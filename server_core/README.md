# Server Core

The **Server Core** is a high-performance FastAPI service that powers real-time multimodal translation. It acts as the central orchestrator, receiving text from: OCR (image processing), Speech-to-text pipelines, and Direct user input, and translating it with our Translate Engine, then returning results instantly. It also provides, secure JWT-based authentication and optional translation history storage (in PostgreSQL)

## Features

- User authentication (JWT-based)
- Real-time translation (en ↔ es)
- Integration with OCR service (image → text → translate)
- Integration with Speech transcription service (speech -> text -> translate)
- Translation history storage (optional)
- Async FastAPI backend
- PostgreSQL integration
- Modular architecture (ready for full integration)

## Environment Setup

Create a .env file in the root:

```
DATABASE_URL=postgresql://acexeon:StrongPass123@localhost:4321/translify
IMAGE_TO_TEXT_SERVICE=http://127.0.0.1:8001
SPEECH_TO_TEXT_SERVICE=http://127.0.0.1:8002
TRANSLATE_SERVICE=http://localhost:9000
SUPPORTED_LANGUAGES=en,es
SECRET_KEY=your_super_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

1. PostgreSQL Setup (Mac - Homebrew)
   brew install postgresql@18
   brew services start postgresql@18

2. Create database:
   psql -h localhost -p 4321 postgres
   CREATE DATABASE translify;
   ALTER USER acexeon WITH PASSWORD 'StrongPass123';

3. For each of the three modules (imageProcessing, speechProcessing, translationEngine):
   - Open a new terminal window
   - Navigate to the respective folder within the Translify project
   - Create a virtual environment: `python3 -m venv venv`
   - Activate the virtual environment: `source venv/bin/activate`
   - Install all requirements: `pip install -r requirements.txt`
   - For imageProcessing only: Also install Tesseract OCR [using the instructions here for the respective platform](https://tesseract-ocr.github.io/tessdoc/Installation.html) - Make sure to also install the `tesseract-ocr-langcode` package
   - Run main.py within each folder, and leave the process running

**All three modules (imageProcessing, speechProcessing, translationEngine) must be running BEFORE running the main server below**

4. Run Main Backend Server
   - Open new terminal window
   - Create new virtual environment and activate it
   - Install required packages: `pip install -r requirements.txt`
   - In terminal, run the server: `uvicorn app.main:app --reload`

5. Backend runs on:
   http://127.0.0.1:8000

6. API Endpoints
   Method Endpoint Description

   POST /signup: Create new user

   POST /login: Login and get JWT token

   GET /me Get current user

7. Translation Endpoints Description

   POST /translate Direct text translation

   POST /translate/image-to-text: Receive an image file, extract the text within the image, and return the translated text and bounding boxes

   POST /translate/speech-to-text: Receive an audio file, transcribe the speech to text, and return the translated text

## API Testing (cURL)

1. Signup

```bash
   curl -X POST http://127.0.0.1:8000/signup \
    -H "Content-Type: application/json" \
    -d '{
   "email": "testuser@example.com",
   "password": "mypassword123"
   }'
```

2. Login

```bash
   curl -X POST http://127.0.0.1:8000/login \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=testuser@example.com&password=mypassword123"
```

Copy the token from the response for use in the tests below:
{
"access_token": "...",
"token_type": "bearer"
}

3. Test Auth (/me)

```bash
   curl -X GET http://127.0.0.1:8000/me \
    -H "Authorization: Bearer YOUR_TOKEN"
```

4. Text Translation

```bash
   curl -X POST http://127.0.0.1:8000/translate \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer YOUR_TOKEN" \
    -d '{
   "text": "Hola, ¿cómo estás?",
   "source_language": "es",
   "target_language": "en",
   "mode": "text",
   "store_history": true
   }'
```

5. Image → Text → Translate

```bash
   curl -X POST "http://localhost:8000/translate/image-to-text" \
   -H "Authorization: Bearer YOUR_TOKEN" \
   -F "source_language=en" \
   -F "target_language=es" \
   -F "store_history=false" \
   -F "image=@IMAGE_PATH_HERE"

   # There are sample files to test with in imageProcessing folder
```

6. Speech → Text → Translate

```bash
   curl -X POST "http://localhost:8000/translate/speech-to-text" \
   -H "Authorization: Bearer YOUR_TOKEN" \
   -F "source_language=en" \
   -F "target_language=es" \
   -F "store_history=false" \
   -F "recording=@AUDIO_PATH_HERE"

   # There are sample files to test with in speechProcessing folder
```

## API Documentation

Swagger UI: http://127.0.0.1:8000/docs

## Future Improvements

- Support more languages
- Dockerize all services
- Add Redis caching
- Improve translation quality (possible change to TranslateGemma model via Ollama)
- Real-time streaming translation

# Authors

Translify Capstone Project - Group 8
