from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.database import get_db

router = APIRouter()

@router.get("/db")
def health_check_db(db: Session = Depends(get_db)):
    try:
        # Perform a simple query to ensure the database is accessible
        db.execute(text("SELECT 1"))
        return {
            "database": "connected",
            "provider": "Neon PostgreSQL"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database connection failed."
        )

@router.get("/migrate")
def migrate_db(db: Session = Depends(get_db)):
    try:
        db.execute(text("ALTER TABLE evidence ADD COLUMN IF NOT EXISTS address VARCHAR;"))
        db.commit()
        return {"status": "Migration successful, address column added."}
    except Exception as e:
        db.rollback()
        return {"status": "Failed", "error": str(e)}
