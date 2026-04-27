from fastapi import FastAPI, UploadFile, File, Form
from faster_whisper import WhisperModel
import shutil
import os

app = FastAPI()

print("Loading model...")
loaded_model_name = "base"
model = WhisperModel(loaded_model_name, device="cpu", compute_type="int8")
print("Model loaded.")


@app.get("/")
def home():
    return {"message": "Speech API running"}


@app.post("/speech/transcribe")
async def transcribe(
    file: UploadFile = File(...),
    language: str = Form("en"),
    model_name: str = Form("base")
):
    file_path = f"temp_{file.filename}"

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    selected_model = model

    
    if model_name != loaded_model_name:
        selected_model = WhisperModel(model_name, device="cpu", compute_type="int8")

    segments, info = selected_model.transcribe(
        file_path,
        language=language
    )

    text = ""
    for segment in segments:
        text += segment.text + " "

    os.remove(file_path)

    return {
        "filename": file.filename,
        "model": model_name,
        "text": text.strip(),
        "language": info.language
    }
