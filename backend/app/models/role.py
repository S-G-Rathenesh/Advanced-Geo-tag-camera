from sqlalchemy import Column, String
from sqlalchemy.orm import relationship
from app.core.database import Base
import uuid

class Role(Base):
    __tablename__ = "roles"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    name = Column(String, unique=True, index=True)  # FIELD_OFFICER, OFFICIAL, ADMIN

    users = relationship("User", back_populates="role")
