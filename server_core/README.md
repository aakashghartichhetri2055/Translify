# Server Core
The **Server Core** is a high-performance FastAPI service that powers real-time multimodal translation. It acts as the central orchestrator, receiving text from: OCR (image processing), Speech-to-text pipelines, and Direct user input, and translating it using a self-hosted **LibreTranslate Engine**, then returning results instantly. It also provides, secure JWT-based authentication and optional translation history storage (in PostgreSQL)

## Features
* User authentication (JWT-based)
* Real-time translation (en ↔ es)
* Integration with OCR service (image → text → translate)
* Speech-to-text route (currently mocked)
* Translation history storage (optional)
* Async FastAPI backend
* PostgreSQL integration
* Modular architecture (ready for full integration)
* Self-hosted LibreTranslate (no external API dependency)

## Environment Setup
Create a .env file in the root:
DATABASE_URL=postgresql://acexeon:StrongPass123@localhost:4321/translify
LIBRETRANSLATE=http://127.0.0.1:5000
SUPPORTED_LANGUAGES=en,es
SECRET_KEY=your_super_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

1. PostgreSQL Setup (Mac - Homebrew)
brew install postgresql@18
brew services start postgresql@18

2. Create database:
psql -h localhost -p 4321 postgres
CREATE DATABASE translify;
ALTER USER acexeon WITH PASSWORD 'StrongPass123';

3. LibreTranslate Setup
Run locally: libretranslate --host 127.0.0.1 --port 5000

Test: curl http://127.0.0.1:5000/languages

OCR Service Setup (Required for Image Translation)
OCR service must run on port 8001:
ocr.py
uvicorn.run(app, host="0.0.0.0", port=8001)

4. Run Backend
pip install -r requirements.txt
uvicorn app.main:app --reload

5. Backend runs on:
http://127.0.0.1:8000

6. API Endpoints
Method	Endpoint	Description
POST	/signup	Create new user
POST	/login	Login and get JWT token
GET	/me	Get current user

6. Translation
Method	Endpoint	Description
POST	/translate	Direct text translation
POST	/translate/image-to-text	OCR → Translate
POST	/translate/speech-to-text	Speech → Translate (mock)

## API Testing (cURL)
1. Signup
curl -X POST http://127.0.0.1:8000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "mypassword123"
  }'

2. Login
curl -X POST http://127.0.0.1:8000/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser@example.com&password=mypassword123"

Copy the token:
{
  "access_token": "...",
  "token_type": "bearer"
}

3. Test Auth (/me)
curl -X GET http://127.0.0.1:8000/me \
  -H "Authorization: Bearer YOUR_TOKEN"

4. Text Translation
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

5. Image → Text → Translate (REAL OCR)
curl -X POST http://127.0.0.1:8000/translate/image-to-text \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "source_language=es" \
  -F "target_language=en" \
  -F "store_history=true"
   
   Which will, trigger OCR camera capture then extract text and then translate it: 

7. Speech → Text → Translate
curl -X POST http://127.0.0.1:8000/translate/speech-to-text \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "source_language=es" \
  -F "target_language=en" \
  -F "store_history=true"

## API Documentation
Swagger UI: http://127.0.0.1:8000/docs

## Current Limitations
* OCR uses camera capture, not file upload yet
* Speech module is currently a local script (not API)
* Speech route uses mock data temporarily

## Future Improvements
* Add real speech API integration
* Add image upload endpoint (instead of camera capture)
* Support more languages
* Dockerize all services
* Add Redis caching
* Improve translation quality (move beyond LibreTranslate)
* Real-time streaming translation

# Authors
Translify Capstone Project - Group 8
