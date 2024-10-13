import asyncio
import json
import os
import time
import pyaudio
import sys
import boto3
import sounddevice as sd

from concurrent.futures import ThreadPoolExecutor
from amazon_transcribe.client import TranscribeStreamingClient
from amazon_transcribe.handlers import TranscriptResultStreamHandler
from amazon_transcribe.model import TranscriptEvent, TranscriptResultStream

from flask import Flask, request, jsonify
from flask_cors import CORS

from api_request_schema import api_request_list, get_model_ids

app = Flask(__name__)
CORS(app)


model_id = os.getenv('MODEL_ID', 'amazon.titan-text-express-v1')
aws_region = os.getenv('AWS_REGION', 'us-east-1')

if model_id not in get_model_ids():
    print(f'Error: Models ID {model_id} in not a valid model ID. Set MODEL_ID env var to one of {get_model_ids()}.')
    sys.exit(0)

api_request = api_request_list[model_id]
config = {
    'log_level': 'debug',  # One of: info, debug, none
    'first_speech': "What issues are you experiencing?",
    'last_speech': "Your request has been received, a care practicioner will be with you shortly",
    'region': aws_region,
    'polly': {
        'Engine': 'neural',
        'LanguageCode': 'en-US',
        'VoiceId': 'Joanna',
        'OutputFormat': 'pcm',
    },
    'translate': {
        'SourceLanguageCode': 'en',
        'TargetLanguageCode': 'en',
    },
    'bedrock': {
        'response_streaming': True,
        'api_request': api_request
    }
}

p = pyaudio.PyAudio()
bedrock_runtime = boto3.client(service_name='bedrock-runtime', region_name=config['region'])
polly = boto3.client('polly', region_name=config['region'])
transcribe_streaming = TranscribeStreamingClient(region=config['region'])

def printer(text, level):
    if config['log_level'] == 'info' and level == 'info':
        print(text)
    elif config['log_level'] == 'debug' and level in ['info', 'debug']:
        print(text)

def list_audio_devices():
    print("\nAvailable audio input devices:")
    devices = sd.query_devices()
    for i, device in enumerate(devices):
        if device['max_input_channels'] > 0:
            print(f"{i}: {device['name']}")
    return devices

def get_audio_device():
    devices = list_audio_devices()
    while True:
        try:
            device_id = int(input("\nEnter the number of the audio input device you want to use: "))
            if 0 <= device_id < len(devices) and devices[device_id]['max_input_channels'] > 0:
                return device_id
            else:
                print("Invalid device number. Please try again.")
        except ValueError:
            print("Please enter a valid number.")

class UserInputManager:
    shutdown_executor = False
    executor = None
    user_ready = False

    @staticmethod
    def set_executor(executor):
        UserInputManager.executor = executor

    @staticmethod
    def start_shutdown_executor():
        UserInputManager.shutdown_executor = False
        raise Exception()  # Workaround to shutdown exec, as executor.shutdown() doesn't work as expected.

    @staticmethod
    def start_user_input_loop():
        while True:
            sys.stdin.readline().strip()
            printer(f'[DEBUG] User input to shut down executor...', 'debug')
            UserInputManager.shutdown_executor = True

    @staticmethod
    def is_executor_set():
        return UserInputManager.executor is not None

    @staticmethod
    def is_shutdown_scheduled():
        return UserInputManager.shutdown_executor


    @staticmethod
    def prompt_user_ready():
        input("Press Enter when you're ready to start speaking...")
        UserInputManager.user_ready = True

    @staticmethod
    def is_user_ready():
        return UserInputManager.user_ready

class BedrockModelsWrapper:
    @staticmethod
    def define_body(text):
        model_id = config['bedrock']['api_request']['modelId']
        model_provider = model_id.split('.')[0]
        body = config['bedrock']['api_request']['body']

        if model_provider == 'amazon':
            body['inputText'] = text
        elif model_provider == 'meta':
            body['prompt'] = text
        elif model_provider == 'anthropic':
            body['prompt'] = f'\n\nHuman: {text}\n\nAssistant:'
        elif model_provider == 'cohere':
            body['prompt'] = text
        else:
            raise Exception('Unknown model provider.')

        return body

    @staticmethod
    def get_stream_chunk(event):
        return event.get('chunk')

    @staticmethod
    def get_stream_text(chunk):
        model_id = config['bedrock']['api_request']['modelId']
        model_provider = model_id.split('.')[0]

        chunk_obj = ''
        text = ''
        if model_provider == 'amazon':
            chunk_obj = json.loads(chunk.get('bytes').decode())
            text = chunk_obj['outputText']
        elif model_provider == 'meta':
            chunk_obj = json.loads(chunk.get('bytes').decode())
            text = chunk_obj['generation']
        elif model_provider == 'anthropic':
            chunk_obj = json.loads(chunk.get('bytes').decode())
            text = chunk_obj['completion']
        elif model_provider == 'cohere':
            chunk_obj = json.loads(chunk.get('bytes').decode())
            text = ' '.join([c["text"] for c in chunk_obj['generations']])
        else:
            raise NotImplementedError('Unknown model provider.')

        printer(f'[DEBUG] {chunk_obj}', 'debug')
        return text

def to_audio_generator(bedrock_stream):
    prefix = ''

    if bedrock_stream:
        for event in bedrock_stream:
            chunk = BedrockModelsWrapper.get_stream_chunk(event)
            if chunk:
                text = BedrockModelsWrapper.get_stream_text(chunk)

                if '.' in text:
                    a = text.split('.')[:-1]
                    to_polly = ''.join([prefix, '.'.join(a), '. '])
                    prefix = text.split('.')[-1]
                    print(to_polly, flush=True, end='')
                    yield to_polly
                else:
                    prefix = ''.join([prefix, text])

        if prefix != '':
            print(prefix, flush=True, end='')
            yield f'{prefix}.'

        print('\n')

class BedrockWrapper:
    def __init__(self):
        self.speaking = False

    def is_speaking(self):
        return self.speaking

    def invoke_bedrock(self, text):
        print("Invoking Bedrock")
        printer('[DEBUG] Bedrock generation started', 'debug')
        self.speaking = True

        prompt_data = f"""Categorize the following request into one of the four categorizes outlined between ##, outputting only the category name.
        #
        Emergency: This would pertain to things that would cause immediate danger to the maker of the request. Bleeding, difficulty breathing, or falling would
        fall into this category
        Pain: This would pertain to problems that cause the maker of the request to be in pain, but not anything life threatening. Things like soreness, rashes,
        or sprains would fall into this category
        Hygiene: This would include problems that don't cause any pain to the request maker but might cause a biohazard if left unchecked. Things like diaper changing,
        catether change, or restroom needs would fall under this categtory.
        Quality of Life: This would include all things that don't fall under the other 3 catagories.
        #

        Request: {text}
        Category:"""
        body = BedrockModelsWrapper.define_body(prompt_data)
        printer(f"[DEBUG] Request body: {body}", 'debug')

        try:
            body_json = json.dumps(body)
            response = bedrock_runtime.invoke_model(
                body=body_json,
                modelId=config['bedrock']['api_request']['modelId'],
                accept=config['bedrock']['api_request']['accept'],
                contentType=config['bedrock']['api_request']['contentType']
            )

            printer('[DEBUG] Capturing Bedrocks response/bedrock_stream', 'debug')
            output_category = json.loads(response.get("body").read())
            print(output_category)

            # full_response = ""
            # for event in bedrock_stream:
            #    chunk = BedrockModelsWrapper.get_stream_chunk(event)
            #    if chunk:
            #        text = BedrockModelsWrapper.get_stream_text(chunk)
            #        full_response += text

            #printer('[DEBUG] Bedrock response: ' + full_response, 'debug')
            return output_category

        except Exception as e:
            print(f"Error in Bedrock invocation: {e}")
            return None

        finally:
            time.sleep(1)
            self.speaking = False
            printer('\n[DEBUG] Bedrock generation completed', 'debug')

class Reader:
    def __init__(self):
        self.polly = boto3.client('polly', region_name=config['region'])
        self.audio = p.open(format=pyaudio.paInt16, channels=1, rate=16000, output=True)
        self.chunk = 1024

    def read(self, data):
        print("Reading audio chunk")
        response = self.polly.synthesize_speech(
            Text=data,
            Engine=config['polly']['Engine'],
            LanguageCode=config['polly']['LanguageCode'],
            VoiceId=config['polly']['VoiceId'],
            OutputFormat=config['polly']['OutputFormat'],
        )

        stream = response['AudioStream']

        while True:
            # Check if user signaled to shutdown Bedrock speech
            # UserInputManager.start_shutdown_executor() will raise Exception. If not ideas but is functional.
            if UserInputManager.is_executor_set() and UserInputManager.is_shutdown_scheduled():
                UserInputManager.start_shutdown_executor()

            data = stream.read(self.chunk)
            self.audio.write(data)
            if not data:
                break

    def close(self):
        time.sleep(1)
        self.audio.stop_stream()
        self.audio.close()

def stream_data(stream):
    chunk = 1024
    if stream:
        polly_stream = p.open(
            format=pyaudio.paInt16,
            channels=1,
            rate=16000,
            output=True,
        )

        while True:
            data = stream.read(chunk)
            polly_stream.write(data)

            # If there's no more data to read, stop streaming
            if not data:
                time.sleep(0.5)
                stream.close()
                polly_stream.stop_stream()
                polly_stream.close()
                break
    else:
        # The stream passed in is empty
        pass

def aws_polly_tts(polly_text):
    printer(f'[INTO] Character count: {len(polly_text)}', 'debug')
    byte_stream_list = []
    polly_text_len = len(polly_text.split('.'))
    printer(f'LEN polly_text_len: {polly_text_len}', 'debug')
    for i in range(0, polly_text_len, 20):
        printer(f'{i}:{i + 20}', 'debug')
        polly_text_chunk = '. '.join(polly_text.split('. ')[i:i + 20])
        printer(f'polly_text_chunk LEN: {len(polly_text_chunk)}', 'debug')

        response = polly.synthesize_speech(
            Text=polly_text_chunk,
            Engine=config['polly']['Engine'],
            LanguageCode=config['polly']['LanguageCode'],
            VoiceId=config['polly']['VoiceId'],
            OutputFormat=config['polly']['OutputFormat'],
        )
        byte_stream = response['AudioStream']
        byte_stream_list.append(byte_stream)

    byte_chunks = []
    chunk = 1024
    for bs in byte_stream_list:
        while True:
            data = bs.read(chunk)
            byte_chunks.append(data)

            if not data:
                bs.close()
                break

    read_byte_chunks(b''.join(byte_chunks))

def read_byte_chunks(data):
    polly_stream = p.open(format=pyaudio.paInt16, channels=1, rate=16000, output=True)
    polly_stream.write(data)

    time.sleep(1)
    polly_stream.stop_stream()
    polly_stream.close()
    time.sleep(1)

class EventHandler(TranscriptResultStreamHandler):
    text = []
    last_time = 0
    sample_count = 0
    max_sample_counter = 4

    def __init__(self, transcript_result_stream: TranscriptResultStream, bedrock_wrapper):
        super().__init__(transcript_result_stream)
        self.bedrock_wrapper = bedrock_wrapper

    async def handle_transcript_event(self, transcript_event: TranscriptEvent):
        results = transcript_event.transcript.results
        print("Received transcript event")
        if UserInputManager.is_user_ready() and not self.bedrock_wrapper.is_speaking():
            if results:
                for result in results:
                    EventHandler.sample_count = 0
                    if not result.is_partial:
                        for alt in result.alternatives:
                            print(alt.transcript, flush=True, end=' ')
                            EventHandler.text.append(alt.transcript)

            else:
                EventHandler.sample_count += 1
                if EventHandler.sample_count == EventHandler.max_sample_counter:

                    if len(EventHandler.text) == 0:
                        last_speech = config['last_speech']
                        print(last_speech, flush=True)
                        aws_polly_tts(last_speech)
                        os._exit(0)  # exit from a child process
                    else:
                        input_text = ' '.join(EventHandler.text)
                        printer(f'\n[INFO] User input: {input_text}', 'info')

                        executor = ThreadPoolExecutor(max_workers=1)
                        # Add executor so Bedrock execution can be shut down, if user input signals so.
                        UserInputManager.set_executor(executor)
                        loop = asyncio.get_event_loop()
                        response = await loop.run_in_executor(
                            executor,
                            self.bedrock_wrapper.invoke_bedrock,
                            input_text
                        )

                    EventHandler.text.clear()
                    EventHandler.sample_count = 0

class MicStream:
    def __init__(self, device_id):
        self.device_id = device_id

    async def mic_stream(self):
        loop = asyncio.get_event_loop()
        input_queue = asyncio.Queue()

        def callback(indata, frame_count, time_info, status):
            loop.call_soon_threadsafe(input_queue.put_nowait, (bytes(indata), status))

        stream = sd.RawInputStream(
            device=self.device_id, channels=1, samplerate=48000, callback=callback, blocksize=2048 * 2, dtype="int16")
        with stream:
            while True:
                indata, status = await input_queue.get()
                yield indata, status

    async def write_chunks(self, stream):
        async for chunk, status in self.mic_stream():
            await stream.input_stream.send_audio_event(audio_chunk=chunk)

        await stream.input_stream.end_stream()

    async def basic_transcribe(self):
        print("Starting transcription...")
        loop = asyncio.get_event_loop()
        loop.run_in_executor(ThreadPoolExecutor(max_workers=1), UserInputManager.start_user_input_loop)
        print("User input  loop started")

        first_speech = config['first_speech']
        aws_polly_tts(first_speech)

        # Prompt the user to indicate when they're ready to speak
        loop.run_in_executor(ThreadPoolExecutor(max_workers=1), UserInputManager.prompt_user_ready)
        
        while not UserInputManager.is_user_ready():
            await asyncio.sleep(0.1)

        print("User is ready. Starting transcription...")

        try:
            stream = await transcribe_streaming.start_stream_transcription(
                language_code="en-US",
                media_sample_rate_hz=48000,
                media_encoding="pcm",
            )
            print("Transcription stream started")

            handler = EventHandler(stream.output_stream, BedrockWrapper())
            print("Event handler created")

            await asyncio.gather(self.write_chunks(stream), handler.handle_events())
        except Exception as e:
            print(e)
            time.sleep(2)
            self.speaking = False
            return None

        finally:
            time.sleep(1)
            self.speaking = False
            print('\n[DEBUG] Bedrock generation completed')

# ... (rest of the code remains unchanged)

info_text = f'''
*************************************************************
[INFO] Supported FM models: {get_model_ids()}.
[INFO] Change FM model by setting <MODEL_ID> environment variable. Example: export MODEL_ID=meta.llama2-70b-chat-v1

[INFO] AWS Region: {config['region']}
[INFO] Amazon Bedrock model: {config['bedrock']['api_request']['modelId']}
[INFO] Polly config: engine {config['polly']['Engine']}, voice {config['polly']['VoiceId']}
[INFO] Log level: {config['log_level']}

[INFO] Hit ENTER to interrupt Amazon Bedrock. After you can continue speaking!
[INFO] Go ahead with the voice chat with Amazon Bedrock!
*************************************************************
'''
# print(info_text)

@app.route('/process_audio', methods=['GET', 'POST'])
def process_audio():
    try:
        # In a real-world scenario, you'd process the audio data sent from the client
        # For now, we'll just simulate the process
        device_id = 1  # You might want to handle this differently
        mic_stream = MicStream(device_id)
        
        # Run the transcription and Bedrock processing
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        result = loop.run_until_complete(mic_stream.basic_transcribe())
        
        # Assuming the result is the category string
        return jsonify({'category': result})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    # device_id = get_audio_device()
    # loop = asyncio.get_event_loop()
    # try:
    #     loop.run_until_complete(MicStream(device_id).basic_transcribe())
    # except (KeyboardInterrupt, Exception) as e:
    #     print(f"An error occurred: {e}")
    # finally:
    #    loop.close()
    print(info_text)
    app.run(debug=True, host='0.0.0.0', port=5000)
