from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import jwt
import httpx

from app.auth_service import AuthService
from app.config import SECRET_KEY, ALGORITHM, IMAGE_TO_TEXT_SERVICE
from app.database import get_db
from app.schemas import (
    SignUpRequest,
    TokenResponse,
    TranslationRequest,
    TranslationResponse,
    UserResponse,
)
from app.translate_service import TranslationService
from app.models import TranslationHistory, User

router = APIRouter()
auth_service = AuthService()
translation_service = TranslationService()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

# IMPORTANT:
# Your OCR teammate's FastAPI app must run on port 8001, not 8000


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid authentication credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    email = None

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
    except jwt.PyJWTError:
        raise credentials_exception

    if email is None:
        raise credentials_exception

    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception

    return user


@router.post("/signup", response_model=UserResponse)
def signup(request: SignUpRequest, db: Session = Depends(get_db)):
    try:
        user = auth_service.create_user(db, request.email, request.password)
        return user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=TokenResponse)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = auth_service.authenticate_user(db, form_data.username, form_data.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = auth_service.create_access_token(user.email)
    return TokenResponse(access_token=access_token)


@router.get("/me", response_model=UserResponse)
def me(current_user: User = Depends(get_current_user)):
    return current_user


@router.post("/translate", response_model=TranslationResponse)
async def translate(
    request: TranslationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        translated_text = await translation_service.translate_text(
            text=request.text,
            source_language=request.source_language,
            target_language=request.target_language,
        )

        if request.store_history:
            history = TranslationHistory(
                user_id=current_user.id,
                original_text=request.text,
                translated_text=translated_text,
                source_language=request.source_language,
                target_language=request.target_language,
                mode=request.mode,
                store_history=request.store_history,
            )
            db.add(history)
            db.commit()

        return TranslationResponse(
            original_text=request.text,
            translated_text=translated_text,
            source_language=request.source_language,
            target_language=request.target_language,
            mode=request.mode,
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/translate/image-to-text")
async def translate_image_to_text(
    source_language: str = Form(...),
    target_language: str = Form(...),
    image: UploadFile = File(...),
    store_history: bool = Form(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Real OCR integration with Image to Text service
    It triggers the OCR service's /capture endpoint,
    receives extracted text, and translates it.

    if not file.filename.lower().endswith((".jpg", ".jpeg")):
        return {"error": "Only .jpg or jpeg files are allowed"}

    """
    try:
        # Make the request to the image to text service to get extracted text
        async with httpx.AsyncClient(timeout=30.0) as client:
            contents = await image.read()

            capture_request_body = {
                "image": (image.filename, contents, image.content_type)
            }
            capture_response = await client.post(f"{IMAGE_TO_TEXT_SERVICE}/capture", files = capture_request_body)

        if capture_response.status_code != 200:
            raise HTTPException(
                status_code=500,
                detail=f"OCR service error: {capture_response.text}"
            )

        capture_data = capture_response.json()
        extracted_text = capture_data["contents"]

        if not extracted_text:
            raise HTTPException(
                status_code=400,
                detail="OCR service returned no text."
            )
        
        # Translate each of the extracted text 
        for item in extracted_text:
            translation = await translation_service.translate_text(
                  text=item["text"],
                  source_language=source_language,
                  target_language=target_language,
            )

            item["translation"] = translation

        if store_history:
            history = TranslationHistory(
                user_id=current_user.id,
                original_text=extracted_text,
                translated_text="test",
                source_language=source_language,
                target_language=target_language,
                mode="image",
                store_history=store_history,
            )
            db.add(history)
            db.commit()

        return extracted_text

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except httpx.RequestError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Could not reach OCR service: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/translate/speech-to-text")
async def translate_speech_to_text(
    source_language: str = Form(...),
    target_language: str = Form(...),
    store_history: bool = Form(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Temporary mock speech route.
    Replace extracted_text later when speech_demo.py becomes a FastAPI API.
    """
    try:
        extracted_text = "Hola amigo"

        translated_text = await translation_service.translate_text(
            text=extracted_text,
            source_language=source_language,
            target_language=target_language,
        )

        if store_history:
            history = TranslationHistory(
                user_id=current_user.id,
                original_text=extracted_text,
                translated_text=translated_text,
                source_language=source_language,
                target_language=target_language,
                mode="speech",
                store_history=store_history,
            )
            db.add(history)
            db.commit()

        return {
            "original_text": extracted_text,
            "translated_text": translated_text,
            "source_language": source_language,
            "target_language": target_language,
            "mode": "speech",
            "speech_source": "mock"
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
