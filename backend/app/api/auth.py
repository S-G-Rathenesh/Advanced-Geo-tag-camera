from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.models.role import Role
from app.schemas.auth import LoginRequest, GoogleAuthRequest, Token
from app.schemas.user import UserResponse
from app.core.security import verify_password, create_access_token
from app.services.audit_service import log_audit_event
from app.services.auth_service import require_authenticated_user
from datetime import datetime, timezone
import json
import base64

router = APIRouter()

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(require_authenticated_user)):
    return current_user

from pydantic import BaseModel
class DemoLoginRequest(BaseModel):
    username: str

@router.post("/demo", response_model=Token)
def demo_login(request: DemoLoginRequest, db: Session = Depends(get_db)):
    allowed_demos = ["demo_supervisor", "demo_user1", "demo_user2", "demo_user3"]
    if request.username not in allowed_demos:
        raise HTTPException(status_code=403, detail="Not a valid demo account")
        
    user = db.query(User).filter(User.username == request.username).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=404, detail="Demo account not found or inactive")
        
    access_token = create_access_token(subject=user.id, role=user.role.name)
    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    
    log_audit_event(db, user_id=user.id, action="DEMO_LOGIN_SUCCESS")
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

@router.post("/officer/login", response_model=Token)
def officer_login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == request.username).first()
    
    if not user or not user.password_hash or not verify_password(request.password, user.password_hash):
        if user:
            log_audit_event(db, user_id=user.id, action="OFFICER_LOGIN_FAILURE", details="Invalid password")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )
    
    if not user.is_active or user.role.name != "OFFICER":
        log_audit_event(db, user_id=user.id, action="OFFICER_LOGIN_FAILURE", details="Inactive account or not an officer")
        raise HTTPException(status_code=403, detail="Unauthorized access")

    access_token = create_access_token(subject=user.id, role=user.role.name)
    
    user.last_login_at = datetime.now(timezone.utc)
    db.commit()

    log_audit_event(db, user_id=user.id, action="OFFICER_LOGIN_SUCCESS")
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

from google.oauth2 import id_token
from google.auth.transport import requests
from app.core.config import settings

@router.post("/google", response_model=Token)
def google_auth(request: GoogleAuthRequest, db: Session = Depends(get_db)):
    try:
        # Verify the token with Google
        payload = id_token.verify_oauth2_token(
            request.id_token,
            requests.Request(),
            settings.GOOGLE_CLIENT_ID
        )

        email = payload.get("email")
        google_subject_id = payload.get("sub")
        name = payload.get("name")
        picture = payload.get("picture")
        
        if not email or not google_subject_id:
            raise ValueError("Missing email or sub in token")
            
    except ValueError as e:
        log_audit_event(db, action="GOOGLE_LOGIN_FAILURE", details=str(e))
        raise HTTPException(status_code=401, detail=f"Invalid Google token: {str(e)}")
    except Exception as e:
        log_audit_event(db, action="GOOGLE_LOGIN_FAILURE", details="Unknown error verifying token")
        raise HTTPException(status_code=401, detail="Error verifying token")
        
    user = db.query(User).filter(User.google_subject_id == google_subject_id).first()
    
    # Also check if user exists by email (for demo seeding match)
    if not user:
        user = db.query(User).filter(User.email == email).first()
        if user:
            user.google_subject_id = google_subject_id
            db.commit()

    if not user:
        # Create new user
        role_user = db.query(Role).filter(Role.name == "USER").first()
        user = User(
            google_subject_id=google_subject_id,
            email=email,
            name=name,
            profile_image=picture,
            role_id=role_user.id,
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
    if not user.is_active:
        log_audit_event(db, user_id=user.id, action="GOOGLE_LOGIN_FAILURE", details="Inactive account")
        raise HTTPException(status_code=403, detail="Inactive user")
        
    access_token = create_access_token(subject=user.id, role=user.role.name)
    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    
    log_audit_event(db, user_id=user.id, action="GOOGLE_LOGIN_SUCCESS")
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }
