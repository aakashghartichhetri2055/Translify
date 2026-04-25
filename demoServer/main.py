from fastapi import FastAPI, UploadFile, File, Form
import shutil
from pathlib import Path
from speechProcessing.speech_demo import speechProcessing
import httpx

app = FastAPI()

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

LIBRETRANSLATE = "http://127.0.0.1:5000"

@app.post("/translateSpeech")
async def upload_wav(file: UploadFile = File(...), originalLang: str = Form(...), targetLang: str = Form(...)):
    
    if not file.filename.endswith(".wav"):
        return {"error": "Only .wav files are allowed"}

    save_path = UPLOAD_DIR / file.filename

    # Save the file
    with open(save_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Transcribe the text
    transcript = speechProcessing(str(save_path))

    # Translate the text
    payload = {
      "q": transcript,
      "source": originalLang,
      "target": targetLang,
      "format": "text"
   }
    
    async with httpx.AsyncClient(timeout=15.0) as client:
      response = await client.post(f"{LIBRETRANSLATE}/translate", json=payload)
      data = response.json()
      translation = data["translatedText"]

      return {
         "transcript":transcript,
         "translation": translation,
      }
    
# Bind to network so that phone can reach
# uvicorn main:app --host 0.0.0.0 --port 8000

# Else
# uvicorn main:app --reload