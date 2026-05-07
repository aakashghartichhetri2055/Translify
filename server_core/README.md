# Server Core
The **Server Core** is a high-performance FastAPI service that powers real-time multimodal translation. It acts as the central orchestrator, receiving text from: OCR (image processing), Speech-to-text pipelines, and Direct user input, and translating it with our Translate Engine, then returning results instantly. It also provides, secure JWT-based authentication and optional translation history storage (in PostgreSQL)

This section explains the FULL authentication and testing process step-by-step so that team-mate can run and test the complete Translify backend correctly.
---

# STEP 1 — Start All Services
IMPORTANT:
All services MUST run simultaneously.
Open 4 separate terminals.
---

## Terminal 1 — Translation Engine
```bash
conda activate translify

cd translationEngine

uvicorn main:app --port 9000 --reload
```

Expected:

```text
Uvicorn running on http://127.0.0.1:9000
```

---
## Terminal 2 — Image Processing

```bash
conda activate translify

cd imageProcessing

python ocr.py
```

Expected:

```text
Uvicorn running on http://127.0.0.1:8001
```

---
## Terminal 3 — Speech Processing

macOS users:

```bash
conda activate translify

cd speechProcessing

export KMP_DUPLICATE_LIB_OK=TRUE

uvicorn main:app --port 8002 --reload
```

Expected:

```text
Model loaded.
Application startup complete.
```

---
## Terminal 4 — Server Core

```bash
conda activate translify

cd server_core

uvicorn app.main:app --reload
```

Expected:

```text
Application startup complete.
```

Main backend:

```text
http://127.0.0.1:8000
```

Swagger docs:

```text
http://127.0.0.1:8000/docs
```

---
# STEP 2 — Create New User (Signup)

The signup endpoint creates a new authenticated user inside PostgreSQL.

Run:

```bash
curl -X POST http://127.0.0.1:8000/signup \
-H "Content-Type: application/json" \
-d '{
"email":"test1@example.com",
"password":"mypassword123"
}'
```

Expected response:

```json
{
  "id": 1,
  "email": "test1@example.com",
  "is_active": true
}
```

IMPORTANT:

- If the user already exists, continue to login.
- Signup only needs to be done once.

---
# STEP 3 — Login User

The login endpoint authenticates the user and returns a JWT access token.

Run:

```bash
curl -X POST http://127.0.0.1:8000/login \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=test1@example.com&password=mypassword123"
```

Expected response:

```json
{
  "access_token": "YOUR_ACCESS_TOKEN_HERE",
  "token_type": "bearer"
}
```

---
# STEP 4 — Save JWT Token

Copy the `access_token` from login response.

Save it as an environment variable:

```bash
export TOKEN="PASTE_ACCESS_TOKEN_HERE"
```

Example:

```bash
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

IMPORTANT:

All protected routes require:

```http
Authorization: Bearer <TOKEN>
```

---

# STEP 5 — Verify Authentication
Run:

```bash
curl -X GET http://127.0.0.1:8000/me \
-H "Authorization: Bearer $TOKEN"
```

Expected response:

```json
{
  "id": 1,
  "email": "test1@example.com",
  "is_active": true
}
```

This confirms:

- JWT authentication works
- Token is valid
- PostgreSQL user retrieval works

---

# STEP 6 — Test Text Translation
```bash
curl -X POST http://127.0.0.1:8000/translate \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
"text":"Hola amigo",
"source_language":"es",
"target_language":"en",
"mode":"text",
"store_history":true
}'
```

Expected response:

```json
{
  "original_text": "Hola amigo",
  "translated_text": "Hello friend",
  "source_language": "es",
  "target_language": "en",
  "mode": "text"
}
```

---
# STEP 7 — Test OCR Image Translation

Run from inside:

```text
server_core/
```

Command:

```bash
curl -X POST "http://127.0.0.1:8000/translate/image-to-text" \
-H "Authorization: Bearer $TOKEN" \
-F "image=@../imageProcessing/Test1.jpg" \
-F "source_language=en" \
-F "target_language=es" \
-F "store_history=true"
```

Expected response:

```json
{
  "mode": "image",
  "source_language": "en",
  "target_language": "es",
  "original_text": "...",
  "translated_text": "...",
  "blocks": []
}
```

This confirms:

- OCR works
- Translation works
- Service communication works
- Database storage works

---
# STEP 8 — Test Speech Translation

Run from inside:

```text
speechProcessing/
```

Command:

```bash
curl -X POST "http://127.0.0.1:8000/translate/speech-to-text" \
-H "Authorization: Bearer $TOKEN" \
-F "recording=@Test1.wav" \
-F "source_language=en" \
-F "target_language=es" \
-F "store_history=true"
```

Expected response:

```json
{
  "mode": "speech",
  "source_language": "en",
  "target_language": "es",
  "original_text": "...",
  "translated_text": "..."
}
```

This confirms:

- Speech-to-text works
- Translation works
- Microservices communicate correctly
- Translation history saves correctly

---
# FULL VERIFIED SUCCESS CHECKLIST

The backend is fully working when ALL endpoints succeed:

```text
/signup
/login
/me
/translate
/translate/image-to-text
/translate/speech-to-text
```

---
# Common Errors + Fixes

---
## Error: Invalid authentication credentials

Cause:

- Expired token
- Wrong token

Fix:

Login again:

```bash
curl -X POST http://127.0.0.1:8000/login \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=test1@example.com&password=mypassword123"
```

Save new token:

```bash
export TOKEN="NEW_ACCESS_TOKEN"
```

---
## Error: curl (26) Failed to open/read local data

Cause:

Wrong image/audio path.

Fix:

```bash
ls ../imageProcessing

ls ../speechProcessing
```

Use exact file names.

---
## Error: 404 Not Found

Wrong endpoint.

Correct endpoints:

```text
/translate
/translate/image-to-text
/translate/speech-to-text
```

---
## Error: 422 Unprocessable Entity

Wrong field names.

Correct fields:

```text
Image endpoint:
image

Speech endpoint:
recording
```

---
## Error: Speech endpoint returns 422

Make sure this fix exists inside:

```text
server_core/app/routes.py
```

```python
data={
    "language": source_language
}
```
Without this fix, speech processing fails.
