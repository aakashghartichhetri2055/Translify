from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import jwt

from app.auth_service import AuthService
from app.config import SECRET_KEY, ALGORITHM
from app.database import get_db
from app.schemas import SignUpRequest, TokenResponse, TranslationRequest, TranslationResponse, UserResponse
from app.translate_service import TranslationService
from app.models import TranslationHistory, User 

router = APIRouter()
auth_service = AuthService()
translation_service = TranslationService()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

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
async def translate(request: TranslationRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user),):
    try:
        translated_text = await translation_service.translate_text(
            text=request.text, 
            source_language=request.source_language,
            target_language=request.target_language
        )

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

        return TranslationResponse(
            original_text=request.text,
            translated_text=translated_text,
            source_language=request.source_language,
            target_language=request.target_language, 
            mode=request.mode
        )
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

