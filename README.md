# Translify

Real-Time Multimodal Translation System  
Capstone Project - Group 8

## Table of Contents

- [Overview](#overview)
- [Problem](#problem)
- [Solution](#solution)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Data Flow](#data-flow)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Security & Privacy](#security--privacy)
- [Performance Considerations](#performance-considerations)
- [Roadmap](#roadmap)
- [Team Members](#team-members)

---

## Overview

- Camera-Based Text Translation: Users can simply point their camera at text, and the app detects, reads, and overlays the translation directly on the screen. This feature will be useful for translation in everyday scenarios such as menus, signs, and documents.
- Conversational Speech Translation: Two users will be able to communicate with each other using one phone. They will choose their languages. A user will then speak into the microphone. The app will transcribe the speech into text, translate it, and display the translation on the phone for the other person to read.
- Base Languages: At the very minimum, we plan to include functionality for English and Spanish. However, we very much expect to be able to introduce more languages

Additional features of the app include the following

- Privacy concerns: we will allow the user to decide whether or not they want their translations stored, and we will not use their data for any other purpose other than to display their recent translations
- Stored translations: if allowed by the user, we will store their translations, so that they can look over them at a later time. This storing will be done in a secure manner

## Problem

In today’s world, there are many languages in use. According to New York State's Office of General Services, there are over 800 languages used in the City. Chances are high that you run into a situation that you do not understand because of language barriers.Consider the following situations:

- Someone asks you for directions to a tourist attraction. You want to help but can’t due to not understanding their question
- You see a sign outside of a shop advertising something. However, you can’t understand what is being advertised because it is in a different language
- You visit a city in a different country. Despite your best attempts to learn the language beforehand, all of that knowledge flows out of your mind the moment you step foot into the city.
- You have binding legal documents in front of you, in a different language.

The solution for when you don’t know a language, is to translate between languages. In the past, this was done usually through a person who knew both your language, and the language of the content that you want to understand. However, this method of translation has some problems: relying on such a person to exist and be physically with you in the first place, possible slow translation, and privacy concerns.

Nowadays, translation is done through online services and applications such as Google Translate or DeepL Translate. These services provide quick and free translation into a multitude of languages. However, these services have their problems: there could be unnecessary features within these apps that aren’t needed, unclear layouts that may further complicate translation, and additional privacy concerns, such as the storing of sensitive data.

## Solution

We propose Translify: a mobile app that will facilitate easy translation between languages, in the form of the following features below:

- Camera-Based Text Translation: Users can simply point their camera at text, and the app detects, reads, and overlays the translation directly on the screen. This feature will be useful for translation in everyday scenarios such as menus, signs, and documents.
- Conversational Speech Translation: Two users will be able to communicate with each other using one phone. They will choose their languages. A user will then speak into the microphone. The app will transcribe the speech into text, translate it, and display the translation on the phone for the other person to read.
- Base Languages: At the very minimum, we plan to include functionality for English and Spanish. However, we very much expect to be able to introduce more languages

Additional features of the app include the following:

- Privacy concerns: we will allow the user to decide whether or not they want their translations stored, and we will not use their data for any other purpose other than to display their recent translations
- Stored translations: if allowed by the user, we will store their translations, so that they can look over them at a later time. This storing will be done in a secure manner

## Key Features

- Dual-Mode Translation Engine  
  Supports both camera-based OCR translation and real-time speech-to-text translation within one integrated system.

- Real-Time Processing Pipeline  
  Designed for low-latency handling of image and audio inputs to provide fast translation results.

- Modular Component Architecture  
  Separates frontend, backend, image processing, speech processing, and translation components to ensure scalability and maintainability.

- Self-Hosted Translation Service  
  Uses a self-hosted LibreTranslate server to maintain control over translation logic and privacy.

- Secure Data Handling  
  User authentication and optional translation history are securely managed, with sensitive data excluded through environment configuration.

- Extensible Language Support  
  Initially supports English and Spanish, with architecture designed to easily integrate additional languages.

## System Architecture

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Python + FastAPI + Uvicorn
- **Database:** PostgreSQL
- **Image Processing:** OpenCV + Pytesseract
- **Speech Processing:** SpeechRecognition + PyAudio
- **Translation Engine:** Self-hosted LibreTranslate
- **Data Format:** JSON

## Data Flow

## Repository Structure

## Getting Started

The way this project is setup currently is assuming that it will be deployed on Google Cloud. If you wanted to run this locally, you sould have at the a computer with enough memory, ideally ~24GB of RAM to be safe.

Detailed instructions follow below for how to run this project locally. You should read all of them (which includes following step 1 and reading the README mentioned there) before starting:

1. Clone this repository
2. Instructions for the frontend are given in the README inside the `translify` folder, under the `How to Run` section. Note that you will be required to install the Flutter SDK and Android Studio at the very least, and if you don't have a physical Android device, you will have to configure an emulated device within Android Studio.
3. For the `image-processing`, `speech-processing`, and `translation-engine` components, each folder contains a Dockerfile. You can build Docker images for each component
   - Each container is set up to listen to port 8080. When starting the docker container, make sure to pass the `-p` flag with unique port numbers for each like so: `-p PORT_HERE:8080`. Ideally, you should NOT use port 8000 for any of these containers, since that will be used for `server-core` later on

   - Note that on container startup for `image-processing` and `translation-engine` , they will try to download model weights from Hugging Face, which can be very time consuming. If you plan to startup these containers multiple times, you can alleviate this problem by using the following volume flag when starting up these containers:
      - MacOS or Linux: ` -v $HOME/.cache/huggingface/hub:/root/.cache/huggingface/hub`
      - Windows: `-v C:\Users\YourName\.cache\huggingface:/root/.cache/huggingface`

4. Spin up containers for all of the above, and take note which port numbers go where
5. Make sure that you have a valid Postgres installation. The following assumes that you can access the database through the standard port of `5432`.
6. In `/server_core`, update the included `.env` file with the following:

```bash
DATABASE_USER = "username here"
DATABASE_PASSWORD = "password here"
DATABASE_NAME = "database name  here"
DATABASE_SOCKET = localhost      # This is localhost as is

TRANSLATE_SERVICE = http://127.0.0.1:PORT_NUMBER_YOU_CHOOSE
IMAGE_TO_TEXT_SERVICE = http://127.0.0.1:PORT_NUMBER_YOU_CHOOSE
SPEECH_TO_TEXT_SERVICE = http://127.0.0.1:PORT_NUMBER_YOU_CHOOSE

# The remaining variables in the file can remain the same
```

7. In `/server_core/app/config.py`, uncomment line 5: `load_dotenv()`
8. In a terminal, cd into `/server_core`, and create a virtual environment: `python3 -m venv venv`
9. Activate the virtual environment: `source venv/bin/activate`
10.   Install the required packages: `pip install -r requirements.txt`
11.   Startup the server, depending on if you are using an emulated device or a physical device:
      - Emulated device: `uvicorn app.main:app --reload --port 8000`
      - Physical device: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 `
         - Caution with this, since this port number is now exposed to the local network
         - You should ideally be on a private network

If everything went well, then it the server should start up. On the frontend, either in the emulated device or on a physical device, you should be able to use the application. Everything might be very slow, but it should work eventually.

Within `/server_core` there is a README with two things: an alternative way to startup the backend without Docker, and some sample tests you can use to confirm everything is working. If you do want to follow those instructions, you should still do steps 2, 5, 6, and 7 of these instructions.

If there are any questions, don't hesitate to reach out to the project contributors.

## Development Workflow

## Security & Privacy

Translify is designed with user privacy and data security as core principles.

### Data Handling

- Image and audio data are processed only for translation purposes.
- No translation data is used for analytics, advertising, or third-party sharing.

### User Authentication

- User credentials are securely stored.
- Passwords are hashed before being saved to the database.

### Optional Translation History

- Users may opt-in to store translation history.
- Stored translations are accessible only to the authenticated user.
- Users can control whether their translations are saved.

## Performance Considerations

To keep Translify fast and responsive, both the frontend and backend follow simple performance practices.

- Process small text segments instead of large blocks to translate faster.
- Cache previous translations so the system can reuse results instead of translating the same text again.
- Limit input size to prevent very large requests from slowing down the application.
- Use efficient communication between the mobile app and backend to reduce unnecessary network requests.
- Run translation locally on the backend to avoid delays from external services.
- These practices help ensure the app provides quick and smooth translations for camera text and speech conversations.

## Roadmap

### Phase 1 - Core Translation Engine

**Goal:** Implement text translation pipeline

### Phase 2 - OCR Pipeline (Camera Translation)

**Goal:** Enable image-based text translation

### Phase 3 - Speech Translation Pipeline

**Goal:** Enable real-time speech translation

### Phase 4 - System Integration

**Goal:** Combine all modules into a unified system

### Phase 5 - User Features & Storage

**Goal:** Add user-level functionality

### Phase 6 - Performance Optimization

**Goal:** Improve speed and efficiency

### Phase 7 - Testing & Debugging

**Goal:** Ensure reliability and correctness

### Phase 8 - Deployment & Presentation

**Goal:** Final delivery and demonstration

## Team Members

- Kelvin Capriel Reyes
- Rusha Limbu
- Aakash Gharti Chhetri
- Chin Tao Liu

...
