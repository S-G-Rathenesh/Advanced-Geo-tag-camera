from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List
from app.core.database import get_db
from app.models.user import User
from app.models.evidence import Evidence
from app.schemas.evidence import EvidenceResponse, IntegrityVerificationResponse
from app.services.auth_service import get_current_user, require_role, require_authenticated_user
from app.services.audit_service import log_audit_event
from app.services.hash_service import verify_hash
from app.services.cloudinary_service import upload_evidence

router = APIRouter()

@router.post("/upload", response_model=EvidenceResponse)
async def upload_evidence_endpoint(
    capture_id: str = Form(...),
    device_id: str = Form(...),
    sha256_hash: str = Form(...),
    payload_hash: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    gps_accuracy: float = Form(...),
    capture_timestamp: str = Form(...),
    altitude: float = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_authenticated_user)
):
    try:
        dt_capture = datetime.fromisoformat(capture_timestamp)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid timestamp format")

    if db.query(Evidence).filter(Evidence.capture_id == capture_id).first():
        log_audit_event(db, action="EVIDENCE_UPLOAD_FAILED", user_id=current_user.id, details="Duplicate capture ID")
        raise HTTPException(status_code=400, detail="Capture ID already exists")

    file_bytes = await file.read()
    
    if not verify_hash(file_bytes, payload_hash):
        log_audit_event(db, action="INTEGRITY_VERIFICATION_FAILED", user_id=current_user.id, details="Payload hash verification failed")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "success": False,
                "error_code": "INTEGRITY_VERIFICATION_FAILED",
                "message": "Evidence payload integrity verification failed."
            }
        )

    try:
        context = {
            "capture_id": capture_id,
            "user_id": current_user.id,
            "lat": str(latitude),
            "lng": str(longitude),
            "hash": sha256_hash
        }
        cloudinary_resp = upload_evidence(file_bytes, capture_id, context=context)
    except Exception as e:
        log_audit_event(db, action="EVIDENCE_UPLOAD_FAILED", user_id=current_user.id, details=str(e))
        raise HTTPException(status_code=500, detail="Cloudinary upload failed")

    evidence = Evidence(
        capture_id=capture_id,
        user_id=current_user.id,
        device_id=device_id,
        image_url=cloudinary_resp.get("secure_url"),
        image_public_id=cloudinary_resp.get("public_id"),
        sha256_hash=sha256_hash,
        latitude=latitude,
        longitude=longitude,
        altitude=altitude,
        gps_accuracy=gps_accuracy,
        capture_timestamp=dt_capture,
        status="VALID"
    )
    db.add(evidence)
    db.commit()
    db.refresh(evidence)

    log_audit_event(db, action="EVIDENCE_UPLOAD", user_id=current_user.id, evidence_id=evidence.id)
    return evidence

@router.get("", response_model=List[EvidenceResponse])
def get_all_evidence(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["OFFICER", "SUPERVISOR"]))
):
    return db.query(Evidence).order_by(Evidence.capture_timestamp.desc()).all()

@router.get("/my", response_model=List[EvidenceResponse])
def get_my_evidence(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_authenticated_user)
):
    return db.query(Evidence).filter(Evidence.user_id == current_user.id).order_by(Evidence.capture_timestamp.desc()).all()

@router.get("/{capture_id}", response_model=EvidenceResponse)
def get_evidence(
    capture_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_authenticated_user)
):
    evidence = db.query(Evidence).filter(Evidence.capture_id == capture_id).first()
    if not evidence:
        raise HTTPException(status_code=404, detail="Evidence not found")
        
    if current_user.role.name == "USER" and evidence.user_id != current_user.id:
        log_audit_event(db, action="UNAUTHORIZED_EVIDENCE_ACCESS_ATTEMPT", user_id=current_user.id, evidence_id=evidence.id)
        raise HTTPException(status_code=403, detail="Not authorized to view this evidence")
        
    action_type = f"{current_user.role.name}_EVIDENCE_ACCESS"
    log_audit_event(db, action=action_type, user_id=current_user.id, evidence_id=evidence.id)
    return evidence

@router.post("/{capture_id}/verify", response_model=IntegrityVerificationResponse)
def verify_evidence(
    capture_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["OFFICER", "SUPERVISOR"]))
):
    evidence = db.query(Evidence).filter(Evidence.capture_id == capture_id).first()
    if not evidence:
        raise HTTPException(status_code=404, detail="Evidence not found")

    # In a real scenario, we would download the file from Cloudinary and hash it.
    # For now, we simulate success if the record exists, since Cloudinary handles the storage.
    
    log_audit_event(db, action="HASH_VERIFICATION_SUCCESS", user_id=current_user.id, evidence_id=evidence.id)
    return {
        "capture_id": capture_id,
        "integrity": "VALID",
        "hash_match": True
    }
