from sqlalchemy import Column, String, DateTime, ForeignKey, Float, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

class Evidence(Base):
    __tablename__ = "evidence"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    capture_id = Column(String, unique=True, index=True, nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    device_id = Column(String, nullable=False)
    
    image_url = Column(String, nullable=False)
    image_public_id = Column(String, nullable=False)
    
    sha256_hash = Column(String, nullable=False, index=True)
    iv_base64 = Column(String, nullable=True)  # AES-GCM initialization vector (base64)
    
    latitude = Column(Float, nullable=False, index=True)
    longitude = Column(Float, nullable=False, index=True)
    altitude = Column(Float)
    gps_accuracy = Column(Float, nullable=False)
    address = Column(String, nullable=True)
    
    capture_timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    upload_timestamp = Column(DateTime(timezone=True), server_default=func.now())
    
    status = Column(String, default="VALID") # VALID, TAMPERED, REJECTED
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="evidence")
    audit_logs = relationship("AuditLog", back_populates="evidence")
