# Vigil
Created by Yanni Hou, Jonathan Shi, & Prisha Patel

Dubhacks 2024

## Inspiration
Vigil started off with two of our developers (who met at their internship at a bio-tech company) wanting to make a positive change in developing a tool to help solve patient negligence in hospitals and nursing homes. After a bit of exploration, we quickly discovered an ongoing problem that skyrocketed in COVID due to staffing outages and overcrowding of patients- alarm fatigue in nurses, leading to patients not receiving the quality care that they would expect in a professional environment. We contacted a few student nurses, who gave their experiences and suggestions through a couple of interviews, which we dissected and wove into Vigil- calls optimized to save lives.

## What it does
Vigil is a mobile application that allows patients in hospitals or nursing homes to send requests to nurses as a replacement of the nurse call light, which we determined to be an outdated and somewhat ambiguous when considering the urgency of the patient's request. The patient meets a login portal, hits a chat interface where they will be prompted to 1. speak to an AI chatbot about what they need, which will categorize and prioritize their request based on other request urgencies or 2. select a general category, to which will automatically update the nurse portal. The nurse portal will be a one-stop shop for nurses to see all of the low-priority requests sorted by urgency, alongside the patient's basic information, like name, room number, a summary of their request, and a dropdown for patient notes in case there is something important the caretakers would need to know. The nurses can then use this page to organize their movements between rooms, delete completed call requests, and ensure that their patient's needs are taken care of.

## How we built it
Vigil is built on Flutter, a mobile application framework, using Dart for handling the frontend and Amazon Polly/Transcribe for TTS backend, Bedrock (Titan model) for the AI integration using Python. We created mock data using CSV to contain patient data for logging in and sending requests. Flask served as the API layer to integrate both ends together.

## Challenges we ran into
For all of us, this was the first time we've ever used Flutter. Learning the language on the fly and understanding syntax was definitely the most challenging part.

Incorporating AWS Generative AI was a challenge in of itself, and using a text-to-speech and speech-to-text interactions with the foundation model only made this doubly so. Handling events and audio stream processing to feed into the Bedrock model was something I had to spend all night debugging - but also euphoric to hear Polly's voice finally speaking properly. 

## Accomplishments that we're proud of
Getting a working text to speech interface may have seemed over-the-top for an alarm system - but was deemed extremely necessary for user accessibility - especially in emergencies when a patient can't afford to hunch over their phone to type a small paragraph.

We're also proud of using proper AI practices by fine-tuning and implementing Retrieval Augmented Generation to reduce hallucinations and properly solve our classification problem's use case.

## What we learned
We've exponentially leveled up our familiarity with this tech stack - between Flutter/Dart, Flask, and AWS. We've also learned a lot about state and event management and the importance of code modularity.

## What's next for Vigil
We're hoping to integrate with real patient data in the future via Epic Sandbox or Medplum, and incorporate this data within our RAG to generate personal follow-up questions. We could also improve the integrations between frontend and backend.
