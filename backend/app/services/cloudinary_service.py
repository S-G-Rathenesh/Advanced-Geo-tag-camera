import cloudinary
import cloudinary.uploader
from app.core.config import settings

# Initialize cloudinary
cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True
)

def upload_evidence(file_bytes: bytes, capture_id: str, context: dict = None) -> dict:
    """
    Uploads the encrypted payload to Cloudinary as a raw resource.
    """
    try:
        response = cloudinary.uploader.upload(
            file_bytes,
            resource_type="raw", # Store as raw binary file
            public_id=f"geo_evidence/{capture_id}",
            context=context
        )
        return response
    except Exception as e:
        raise Exception(f"Cloudinary upload failed: {str(e)}")
