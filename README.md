# FamilyVoice Assistant

A personalized voice-controlled assistant developed in MATLAB that identifies individual users using Mel Frequency Cepstral Coefficients (MFCC) and provides customized responses based on speaker recognition.

## Overview

Most conventional voice assistants rely on cloud-based processing and do not differentiate between users. FamilyVoice Assistant addresses this limitation by performing offline speaker identification and command processing using signal processing techniques.

The system extracts MFCC features from speech recordings, compares them with stored voice templates using Euclidean distance, identifies the speaker, and executes personalized commands.

## Features

* Offline speaker recognition
* MFCC-based feature extraction
* Personalized user profiles
* Voice and text command support
* Reminder management system
* User-specific interaction history
* MATLAB-based implementation
* Data logging and storage

## Methodology

1. Voice Acquisition
2. Pre-processing
3. MFCC Feature Extraction
4. Speaker Identification
5. Command Recognition
6. Response Generation
7. Data Logging

## Technologies Used

* MATLAB
* Digital Signal Processing
* MFCC
* Euclidean Distance Classification
* Speech Processing

## Project Structure

```text
familyvoice-assistant
│
├── README.md
├── docs
├── matlab
├── images
└── outputs
```

## Results

The system successfully identifies registered users based on voice characteristics and executes personalized commands such as reminders, weather updates, calculations, and information retrieval.

## Future Enhancements

* Deep learning-based speaker recognition
* Natural language understanding
* Home automation integration
* Real-time speech-to-text
* Mobile application support

## Author

Mokshagna Yerra
B.Tech Electronics and Communication Engineering
VNR Vignana Jyothi Institute of Engineering and Technology
