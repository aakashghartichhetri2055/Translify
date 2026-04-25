from faster_whisper import WhisperModel
import sounddevice as sd
import numpy as np
import wave
import os

def speechProcessing(filepath):
   model = WhisperModel("base", device="cpu", compute_type="int8")

   segments, languageInfo = model.transcribe(filepath)

   print(f"Detected language: {languageInfo.language}")
   print(f"Confidence: {languageInfo.language_probability:.2f}")

   text = ""
   for segment in segments:
      text += segment.text + " "

   return text.strip()

class SpeechProcessor:
    def __init__(self):
        print("Welcome to Translify")
        self.model = WhisperModel("base", device="cpu", compute_type="int8")
    

    def record_audio(self, filename="speech.wav"):
        samplerate = 16000
        duration = 5

        print("Listening... Speak now.")
        audio = sd.rec(
            int(duration * samplerate),
            samplerate=samplerate,
            channels=1,
            dtype="int16"
        )

        sd.wait()

    
        with wave.open(filename, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(samplerate)
            wf.writeframes(audio.tobytes())

        return filename

    def transcribe(self):
        audio_file = self.record_audio()

        segments, _ = self.model.transcribe(audio_file)

        text = ""
        for segment in segments:
            text += segment.text + " "

        return text.strip()


if __name__ == "__main__":
   #  speech = SpeechProcessor()
   #  result = speech.transcribe()
   #  print("You said:", result)
   result = speechProcessing("output.wav")
   print(result)
