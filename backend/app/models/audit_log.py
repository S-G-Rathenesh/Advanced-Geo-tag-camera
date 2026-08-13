from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True, index=True)
    target_user_id = Column(String, ForeignKey("users.id"), nullable=True, index=True)
    evidence_id = Column(String, ForeignKey("evidence.id"), nullable=True, index=True)
    
    action = Column(String, nullable=False, index=True)
    ip_address = Column(String)
    device_id = Column(String)
    
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    details = Column(Text)

    user = relationship("User", back_populates="audit_logs", foreign_keys=[user_id])
    evidence = relationship("Evidence", back_populates="audit_logs")
