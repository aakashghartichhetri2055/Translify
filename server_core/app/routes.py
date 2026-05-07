from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import jwt
<<<<<<< HEAD

from app.auth_service import AuthService
from app.config import SECRET_KEY, ALGORITHM
=======
import httpx
import json

from app.auth_service import AuthService
from app.config import (
    SECRET_KEY,
    ALGORITHM,
    IMAGE_TO_TEXT_SERVICE,
    SPEECH_TO_TEXT_SERVICE,
)
>>>>>>> 1b3778e (Temporary save before switching branches)
from app.database import get_db
from app.schemas import SignUpRequest, TokenResponse, TranslationRequest, TranslationResponse, UserResponse
from app.translate_service import TranslationService
from app.models import TranslationHistory, User 

router = APIRouter()
auth_service = AuthService()
translation_service = TranslationService()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

<<<<<<< HEAD
=======

>>>>>>> 1b3778e (Temporary save before switching branches)
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid authentication credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )

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

<<<<<<< HEAD
@router.post("/signup", response_model=UserResponse)
def signup(request: SignUpRequest, db: Session = Depends(get_db)):
    try:
        user = auth_service.create_user(db, request.email, request.password)
        return user 
    except ValueError as e: 
=======

def save_history(
    db: Session,
    user_id: int,
    original_text: str,
    translated_text: str,
    source_language: str,
    target_language: str,
    mode: str,
    store_history: bool,
):
    if not store_history:
        return

    history = TranslationHistory(
        user_id=user_id,
        original_text=original_text,
        translated_text=translated_text,
        source_language=source_language,
        target_language=target_language,
        mode=mode,
        store_history=store_history,
    )

    db.add(history)
    db.commit()


@router.post("/signup", response_model=UserResponse)
def signup(request: SignUpRequest, db: Session = Depends(get_db)):
    try:
        return auth_service.create_user(db, request.email, request.password)
    except ValueError as e:
>>>>>>> 1b3778e (Temporary save before switching branches)
        raise HTTPException(status_code=400, detail=str(e))
    
@router.post("/login", response_model=TokenResponse)
def login(
<<<<<<< HEAD
    form_data: OAuth2PasswordRequestForm = Depends(), 
    db: Session = Depends(get_db), 
): 
    user = auth_service.authenticate_user(db, form_data.username, form_data.password)
=======
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = auth_service.authenticate_user(
        db,
        form_data.username,
        form_data.password,
    )
>>>>>>> 1b3778e (Temporary save before switching branches)

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
async def translate(request: TranslationRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user),):
    try:
        translated_text = await translation_service.translate_text(
            text=request.text, 
            source_language=request.source_language,
            target_language=request.target_language
        )

<<<<<<< HEAD
        if request.store_history:
            history = TranslationHistory(
                user_id=current_user.id, 
                original_text=request.text, 
                translated_text=translated_text, 
                source_language=request.source_language,
                target_language=request.target_language,
                mode=request.mode, 
                store_history=request.store_history
            )
            db.add(history)
            db.commit()
=======
        save_history(
            db=db,
            user_id=current_user.id,
            original_text=request.text,
            translated_text=translated_text,
            source_language=request.source_language,
            target_language=request.target_language,
            mode=request.mode or "text",
            store_history=bool(request.store_history),
        )
>>>>>>> 1b3778e (Temporary save before switching branches)

        return TranslationResponse(
            original_text=request.text,
            translated_text=translated_text,
            source_language=request.source_language,
<<<<<<< HEAD
            target_language=request.target_language, 
            mode=request.mode
=======
            target_language=request.target_language,
            mode=request.mode or "text",
>>>>>>> 1b3778e (Temporary save before switching branches)
        )
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except httpx.RequestError as e:
        raise HTTPException(status_code=500, detail=f"Translation service unavailable: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

<<<<<<< HEAD
=======

@router.post("/translate/image-to-text")
async def translate_image_to_text(
    source_language: str = Form(...),
    target_language: str = Form(...),
    image: UploadFile = File(...),
    store_history: bool = Form(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not image.filename.lower().endswith((".jpg", ".jpeg", ".png")):
        raise HTTPException(
            status_code=400,
            detail="Only .jpg, .jpeg, or .png files are allowed.",
        )

    try:
        image_bytes = await image.read()

        if not image_bytes:
            raise HTTPException(status_code=400, detail="Empty image file received.")

        async with httpx.AsyncClient(timeout=120.0) as client:
            ocr_response = await client.post(
                f"{IMAGE_TO_TEXT_SERVICE.rstrip('/')}/capture",
                files={
                    "image": (
                        image.filename,
                        image_bytes,
                        image.content_type or "image/jpeg",
                    )
                },
            )

        if ocr_response.status_code != 200:
            raise HTTPException(
                status_code=500,
                detail=f"OCR service error: {ocr_response.text}",
            )

        ocr_data = ocr_response.json()
        contents = ocr_data.get("contents", [])
        full_text = ocr_data.get("text", "").strip()

        if not contents and not full_text:
            raise HTTPException(status_code=400, detail="OCR service returned no text.")

        translated_blocks = []

        if contents:
            for item in contents:
                original_block_text = item.get("text", "").strip()

                if not original_block_text:
                    continue

                translated_block_text = await translation_service.translate_text(
                    text=original_block_text,
                    source_language=source_language,
                    target_language=target_language,
                )

                translated_blocks.append(
                    {
                        "original_text": original_block_text,
                        "translated_text": translated_block_text,
                        "bbox": item.get("bbox"),
                    }
                )

            original_for_history = " ".join(
                block["original_text"] for block in translated_blocks
            )
            translated_for_history = " ".join(
                block["translated_text"] for block in translated_blocks
            )

        else:
            translated_text = await translation_service.translate_text(
                text=full_text,
                source_language=source_language,
                target_language=target_language,
            )

            translated_blocks.append(
                {
                    "original_text": full_text,
                    "translated_text": translated_text,
                    "bbox": None,
                }
            )

            original_for_history = full_text
            translated_for_history = translated_text

        save_history(
            db=db,
            user_id=current_user.id,
            original_text=original_for_history,
            translated_text=translated_for_history,
            source_language=source_language,
            target_language=target_language,
            mode="image",
            store_history=store_history,
        )

        return {
            "mode": "image",
            "source_language": source_language,
            "target_language": target_language,
            "original_text": original_for_history,
            "translated_text": translated_for_history,
            "blocks": translated_blocks,
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except httpx.RequestError as e:
        raise HTTPException(status_code=500, detail=f"Could not reach OCR service: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/translate/speech-to-text")
async def translate_speech_to_text(
    source_language: str = Form(...),
    target_language: str = Form(...),
    recording: UploadFile = File(...),
    store_history: bool = Form(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not recording.filename.lower().endswith((".wav", ".mp3", ".m4a")):
        raise HTTPException(
            status_code=400,
            detail="Only .wav, .mp3, or .m4a audio files are allowed.",
        )

    try:
        audio_bytes = await recording.read()

        if not audio_bytes:
            raise HTTPException(status_code=400, detail="Empty audio file received.")

        async with httpx.AsyncClient(timeout=180.0) as client:
            speech_response = await client.post(
                f"{SPEECH_TO_TEXT_SERVICE.rstrip('/')}/speech/transcribe",
                files={
                    "file": (
                        recording.filename,
                        audio_bytes,
                        recording.content_type or "audio/wav",
                        )
                        },
                        data={
                            "language": source_language
                            },
                            )

        if speech_response.status_code != 200:
            raise HTTPException(
                status_code=500,
                detail=f"Speech service error: {speech_response.text}",
            )

        speech_data = speech_response.json()
        transcription = speech_data.get("text", "").strip()
        detected_language = speech_data.get("language")

        if not transcription:
            raise HTTPException(
                status_code=400,
                detail="Speech service returned no transcription.",
            )

        translated_text = await translation_service.translate_text(
            text=transcription,
            source_language=source_language,
            target_language=target_language,
        )

        save_history(
            db=db,
            user_id=current_user.id,
            original_text=transcription,
            translated_text=translated_text,
            source_language=source_language,
            target_language=target_language,
            mode="speech",
            store_history=store_history,
        )

        return {
            "mode": "speech",
            "source_language": source_language,
            "target_language": target_language,
            "detected_language": detected_language,
            "original_text": transcription,
            "translated_text": translated_text,
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except httpx.RequestError as e:
        raise HTTPException(status_code=500, detail=f"Could not reach speech service: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
>>>>>>> 1b3778e (Temporary save before switching branches)
