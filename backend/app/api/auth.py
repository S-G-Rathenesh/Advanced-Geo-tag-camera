from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, Token
from app.core.security import verify_password, create_access_token
from app.services.audit_service import log_audit_event

router = APIRouter()

@router.post("/login", response_model=Token)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == request.username).first()
    
    if not user or not verify_password(request.password, user.password_hash):
        if user:
            log_audit_event(db, user_id=user.id, action="LOGIN_FAILURE", details="Invalid password")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )
    
    if not user.is_active:
        log_audit_event(db, user_id=user.id, action="LOGIN_FAILURE", details="Inactive account")
        raise HTTPException(status_code=400, detail="Inactive user")

    access_token = create_access_token(subject=user.id)
    
    log_audit_event(db, user_id=user.id, action="LOGIN_SUCCESS")
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "username": user.username,
            "full_name": user.full_name,
            "department": user.department,
            "is_active": user.is_active,
            "role": user.role.name
        }
    }
