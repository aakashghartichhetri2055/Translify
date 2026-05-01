import httpx
from app.config import TRANSLATE_SERVICE, SUPPORTED_LANGUAGES

class TranslationService:
    def __init__(self):
        self.base_url = TRANSLATE_SERVICE.rstrip("/")

    def validate_language(self, lang: str):
        if lang not in SUPPORTED_LANGUAGES:
            raise ValueError(f"Unsupported language: {lang}")

    async def translate_text(self, text: str, source_language: str, target_language: str):
        text = text.strip()

        if not text:
            raise ValueError("Text cannot be empty.")

        self.validate_language(source_language)
        self.validate_language(target_language)

        if source_language == target_language:
            return text

        payload = {
            "text": text,
            "sourceLanguage": source_language,
            "targetLanguage": target_language
        }

        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(f"{self.base_url}/translate", json=payload)

            if response.status_code != 200:
                raise Exception(
                    f"LibreTranslate error {response.status_code}: {response.text}"
                )

            data = response.json()
            return data["translatedText"]