from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.models.role import Role
from app.models.evidence import Evidence
from app.services.auth_service import get_current_user, require_role
from app.services.audit_service import log_audit_event
from app.schemas.user import UserResponse
from app.schemas.evidence import EvidenceResponse
from typing import List

router = APIRouter()

@router.get("", response_model=List[UserResponse])
def get_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["OFFICER", "SUPERVISOR"]))
):
    users = db.query(User).all()
    return users

@router.get("/{user_id}/evidence", response_model=List[EvidenceResponse])
def get_user_evidence(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["OFFICER", "SUPERVISOR"]))
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    evidence_list = db.query(Evidence).filter(Evidence.user_id == user_id).all()
    log_audit_event(db, action=f"{current_user.role.name}_EVIDENCE_ACCESS", user_id=current_user.id, target_user_id=user_id)
    return evidence_list

@router.post("/{user_id}/grant-supervisor")
def grant_supervisor(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["OFFICER"]))
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if user.role.name == "SUPERVISOR":
        return {"message": "User is already a supervisor"}
        
    supervisor_role = db.query(Role).filter(Role.name == "SUPERVISOR").first()
    user.role_id = supervisor_role.id
    db.commit()
    
    log_audit_event(db, action="SUPERVISOR_ACCESS_GRANTED", user_id=current_user.id, target_user_id=user_id)
    return {"message": f"Supervisor access granted to {user.name or user.email}"}

@router.post("/{user_id}/revoke-supervisor")
def revoke_supervisor(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["OFFICER"]))
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if user.role.name != "SUPERVISOR":
        raise HTTPException(status_code=400, detail="User is not a supervisor")
        
    user_role = db.query(Role).filter(Role.name == "USER").first()
    user.role_id = user_role.id
    db.commit()
    
    log_audit_event(db, action="SUPERVISOR_ACCESS_REVOKED", user_id=current_user.id, target_user_id=user_id)
    return {"message": f"Supervisor access revoked from {user.name or user.email}"}
