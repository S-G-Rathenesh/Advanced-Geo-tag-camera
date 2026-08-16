from pydantic import BaseModel, ConfigDict
from datetime import datetime

class EvidenceUploadRequest(BaseModel):
    capture_id: str
    device_id: str
    sha256_hash: str
    payload_hash: str
    latitude: float
    longitude: float
    altitude: float | None = None
    gps_accuracy: float
    address: str | None = None
    gnss_constellations: str | None = None
    capture_timestamp: datetime

class EvidenceResponse(BaseModel):
    id: str
    capture_id: str
    user_id: str
    device_id: str
    image_url: str
    sha256_hash: str
    latitude: float
    longitude: float
    altitude: float | None
    gps_accuracy: float
    address: str | None
    gnss_constellations: str | None
    capture_timestamp: datetime
    upload_timestamp: datetime
    status: str
    iv_base64: str | None = None

    model_config = ConfigDict(from_attributes=True)

class IntegrityVerificationResponse(BaseModel):
    capture_id: str
    integrity: str
    hash_match: bool
