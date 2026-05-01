from fastapi import FastAPI, UploadFile, File, Form
from faster_whisper import WhisperModel
import uvicorn
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
    language: str = Form(...),
):
    file_path = f"temp_{file.filename}"

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    segments, info = model.transcribe(
        file_path,
        language=language
    )

    text = ""
    for segment in segments:
        text += segment.text + " "

    os.remove(file_path)

    return {
        "filename": file.filename,
        "text": text.strip(),
        "language": info.language
    }

if __name__ == '__main__':
   uvicorn.run(app, host="127.0.0.1", port=8002)