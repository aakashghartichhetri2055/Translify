from fastapi import FastAPI, UploadFile, File
from faster_whisper import WhisperModel
import shutil
import os

app = FastAPI()

print("Loading model...")
model = WhisperModel("base", device="cpu", compute_type="int8")
print("Model loaded.")


@app.get("/")
def home():
    return {"message": "Speech API running"}


@app.post("/speech/transcribe")
async def transcribe(file: UploadFile = File(...)):
    file_path = f"temp_{file.filename}"

    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    
    segments, info = model.transcribe(file_path)

    text = ""
    for segment in segments:
        text += segment.text + " "

    os.remove(file_path)

    return {
        "text": text.strip(),
        "language": info.language
    }
