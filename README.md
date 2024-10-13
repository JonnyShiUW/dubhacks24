Created by Yanni Hou, Jonathan Shi, & Prisha Patil (?). Dubhacks 2024.



Vigil is an AI alarm system that classifies patient requests based on category, allowing nurses or caretakers to have a simplified, straightforward display of the patients they need to tend to in the AI-determined priority queue. It aims to help solve the ever ongoing issue of patient negligence and alarm fatigue in nurses, both caused by understaffed establishments and outdated technology to ensure proper patient care.



# Installation Requirements



To set up a Flutter development environment, follow the following guides depending on software:

IOS: https://docs.flutter.dev/get-started/install/macos/mobile-android

Windows: https://docs.flutter.dev/get-started/install/windows/mobile

After Android Studio is configured and set up, navigate to todo_frontend and locatelib/main.dart, and run. This should open Android Studio's emulator.

Alternatively, if an Android mobile device is available, connect the mobile device to your laptop/PC and follow the steps detailed in the docs above for "Physical Device".



# Usage Guide


Upon successful launch of Vigil, you should be met with an initial page that directs you either to the Patient ot Nurse portal.

To test out Patient functionalities (send a request via text-to-speech/selection) log in with the credentials located under todo_frontend/data/userdata.txt (the first item is the username, the second item is the password). Incorrect logins will be met with a short message indicating as such. Successful logins will take you to the chatbox interface. Then, you're ready to send a request! To test out new requests, simply press the back button to return to the initial page and re-login.

To test out Nurse functionality, click the Nurse button on the initial page and it will immediately take you to the queue where you can see the queue. Each queue item has the patient information including their name and summary of their request. There is also an option to remove the request upon completion.