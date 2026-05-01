"""
A server that will contain the translation engine

Main backend server can call this server for translations
"""

from fastapi import FastAPI
from fastapi import HTTPException

import uvicorn

from pydantic import BaseModel, Field

from translationEngine import TranslationEngine


# Schema for request data
class TranslationRequest(BaseModel):
   text: str = Field(..., description = "The text to be translated")
   sourceLanguage: str = Field(..., description = "The original language of the text")
   targetLanguage: str = Field(..., description = "The target language for the text")

# Schema for response data
class TranslationResponse(BaseModel):
   translatedText: str = Field(..., description = "The translated text")

# Create and load the model
MODEL = "facebook/nllb-200-distilled-600M"
engine = TranslationEngine(modelName = MODEL)

# FastAPI server
app = FastAPI()

# Route for the translation request
@app.post("/translate", response_model = TranslationResponse)
def translate(request: TranslationRequest):
   try:
      # Try to translate
      result = engine.translate(
         text = request.text,
         srcLang = request.sourceLanguage, 
         tgtLang = request.targetLanguage
      )

      return TranslationResponse(translatedText = result)
   except ValueError as e:
      raise HTTPException(status_code = 422, detail = str(e))
   
if __name__ == '__main__':
    uvicorn.run(app, host="127.0.0.1", port=9000)