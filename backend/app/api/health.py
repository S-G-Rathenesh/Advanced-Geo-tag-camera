from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.database import get_db

router = APIRouter()

@router.get("/db")
def health_check_db(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"database": "connected", "provider": "Neon PostgreSQL"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Database connection failed.")

@router.get("/db_schema")
def inspect_schema(db: Session = Depends(get_db)):
    try:
        result = db.execute(text("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_name = 'evidence'
            ORDER BY ordinal_position;
        """))
        columns = [{"column_name": row[0], "data_type": row[1]} for row in result.fetchall()]
        return {"table": "evidence", "columns": columns}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/db_migrate")
def migrate_schema(db: Session = Depends(get_db)):
    try:
        db.execute(text("ALTER TABLE evidence ADD COLUMN IF NOT EXISTS address VARCHAR;"))
        db.execute(text("ALTER TABLE evidence ADD COLUMN IF NOT EXISTS gnss_constellations VARCHAR;"))
        db.commit()
        return {"status": "success", "message": "Columns added"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
