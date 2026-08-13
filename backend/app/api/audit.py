from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.models.audit_log import AuditLog
from app.services.auth_service import require_role

router = APIRouter()

@router.get("")
def get_audit_logs(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["OFFICER"]))
):
    # In a real app, this should have pagination
    logs = db.query(AuditLog).order_by(AuditLog.timestamp.desc()).limit(100).all()
    return logs
