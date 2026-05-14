import os
from dotenv import load_dotenv
from sqlalchemy.engine import URL

DATABASE_USER = os.getenv("DATABASE_USER")
DATABASE_PASSWORD = os.getenv("DATABASE_PASSWORD")
DATABASE_NAME = os.getenv("DATABASE_NAME")
DATABASE_SOCKET = os.getenv("DATABASE_SOCKET")

DATABASE_URL = URL.create(
    drivername = "postgresql",
    username = DATABASE_USER,
    password = DATABASE_PASSWORD,
    database = DATABASE_NAME,
    host = DATABASE_SOCKET,
)

TRANSLATE_SERVICE = os.getenv("TRANSLATE_SERVICE", "http://127.0.0.1:9000")
IMAGE_TO_TEXT_SERVICE = os.getenv("IMAGE_TO_TEXT_SERVICE", "http://127.0.0.1:8001")
SPEECH_TO_TEXT_SERVICE = os.getenv("SPEECH_TO_TEXT_SERVICE", "http://127.0.0.1:8002")

SUPPORTED_LANGUAGES = os.getenv("SUPPORTED_LANGUAGES", "en,es,fr").split(",")

SECRET_KEY = os.getenv("SECRET_KEY", "change_me")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
