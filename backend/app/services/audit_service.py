from sqlalchemy.orm import Session
from app.models.audit_log import AuditLog

def log_audit_event(
    db: Session,
    action: str,
    user_id: str = None,
    evidence_id: str = None,
    ip_address: str = None,
    device_id: str = None,
    details: str = None
):
    audit_log = AuditLog(
        user_id=user_id,
        evidence_id=evidence_id,
        action=action,
        ip_address=ip_address,
        device_id=device_id,
        details=details
    )
    db.add(audit_log)
    db.commit()
    db.refresh(audit_log)
    return audit_log
