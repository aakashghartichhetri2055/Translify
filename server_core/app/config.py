import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
LIBRETRANSLATE = os.getenv("LIBRETRANSLATE", "http://127.0.0.1:5000")
SUPPORTED_LANGUAGES = os.getenv("SUPPORTED_LANGUAGES", "en,es").split(",")

SECRET_KEY=os.getenv("SECRET_KEY", "change_me")
ALGORITHM=os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES=int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))