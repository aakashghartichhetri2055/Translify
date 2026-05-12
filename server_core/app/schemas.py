from pydantic import BaseModel, Field, EmailStr
from typing import Optional, Literal


class SignUpRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)


class UserResponse(BaseModel):
    id: int
    email: EmailStr
    is_active: bool

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TranslationRequest(BaseModel):
    text: str = Field(..., min_length=1)
    source_language: str
    target_language: str
    mode: Optional[Literal["image", "speech", "text"]] = "text"
    store_history: bool = False


class TranslationResponse(BaseModel):
    original_text: str
    translated_text: str
    source_language: str
    target_language: str
    mode: Optional[str] = None
