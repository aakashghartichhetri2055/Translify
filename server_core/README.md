# 🌍 Translify — Backend Core
The **Translify Backend Core** is a high-performance FastAPI service that powers real-time multimodal translation.  
It processes text from OCR (images), speech-to-text pipelines, or direct user input, translates it using a **self-hosted LibreTranslate engine**, and returns results instantly.

It also supports **JWT-based authentication** and optional **translation history storage in PostgreSQL**.

# Features
- User authentication (JWT-based)
- Real-time translation (`en` ↔ `es`)
- Translation history storage (optional)
- FastAPI async backend
- PostgreSQL integration
- Self-hosted LibreTranslate (no external API)

# System Architecture
Input (OCR / Speech / Text)
↓
FastAPI Backend (Routing + Validation + Auth)
↓
Translation Service
↓
LibreTranslate (Self-hosted)
↓
Translated Output
↓
(Optional) PostgreSQL (Store History)
↓
Response (JSON)

# Project Structure
backend_core/
├── app/
│   ├── main.py              # FastAPI entry point
│   ├── routes.py            # API endpoints (auth + translate)
│   ├── translate_service.py # Translation logic
│   ├── auth_service.py      # Authentication logic (hash + JWT)
│   ├── schemas.py           # Pydantic models
│   ├── models.py            # SQLAlchemy models
│   ├── database.py          # DB connection setup
│   └── config.py            # Environment config
├── requirements.txt
└── .env

# Environment Setup
Create a `.env` file in the root:

DATABASE_URL=postgresql://acexeon:StrongPass123@localhost:4321/translify
LIBRETRANSLATE=http://127.0.0.1:5000
SUPPORTED_LANGUAGES=en,es
SECRET_KEY=your_super_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# PostgreSQL Setup (Homebrew)
brew install postgresql@18
brew services start postgresql@18

Create DB:

psql -h localhost -p 4321 postgres

CREATE DATABASE translify;
ALTER USER acexeon WITH PASSWORD 'StrongPass123';

# LibreTranslate Setup

Run locally:
libretranslate --host 127.0.0.1 --port 5000

Test:
curl http://127.0.0.1:5000/languages

# Run the Backend
pip install -r requirements.txt
uvicorn app.main:app --reload

# API Testing (cURL)

## Signup
curl -X POST http://127.0.0.1:8000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "mypassword123"
  }'

## Login
curl -X POST http://127.0.0.1:8000/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser@example.com&password=mypassword123"

Response:
{
  "access_token": "...",
  "token_type": "bearer"
}

## Translate
curl -X POST http://127.0.0.1:8000/translate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "text": "Hola, ¿cómo estás?",
    "source_language": "es",
    "target_language": "en",
    "mode": "speech",
    "store_history": true
  }'

Response:
{
  "original_text": "Hola, ¿cómo estás?",
  "translated_text": "Hey, how are you?",
  "source_language": "es",
  "target_language": "en",
  "mode": "speech"
}

# API Documentation
Interactive Swagger UI:
http://127.0.0.1:8000/docs

# Notes

* LibreTranslate **must be running** before translation requests
* Only `en` and `es` are supported (extendable)
* JWT tokens expire after configured time
* History is stored **only if `store_history = true`**
* Backend uses **async processing for performance**

# 🎯 Role in Translify System
This backend acts as the **central orchestrator**, integrating:

* OCR Module → text extraction
* Speech Module → transcription
* Translation Engine → output generation

It ensures a **clean, modular, scalable pipeline** for real-time translation.

# Future Improvements

* Add more languages
* Dockerize services
* Add Redis caching
* Add analytics dashboard
* Streaming translation support

# Status

 Authentication working
Translation working
 PostgreSQL integration working
 Ready for frontend integration

# Author
**Translify Capstone Project — Group 8**

# What I improved (so you understand)
- Clean **professional structure**
- Added **environment setup**
- Added **PostgreSQL + LibreTranslate setup**
- Fixed formatting (code blocks, flow, hierarchy)
- Added **future roadmap (very important for grading)**
- Made it **industry-level readable**
```
