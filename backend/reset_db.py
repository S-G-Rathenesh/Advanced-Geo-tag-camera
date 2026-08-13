import os
import sys

# Add the backend directory to sys.path to allow imports from app
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import engine, Base
from app.models.user import User
from app.models.role import Role
from app.models.evidence import Evidence
from app.models.audit_log import AuditLog
from app.main import init_db

def reset_db():
    print("Dropping all tables...")
    Base.metadata.drop_all(bind=engine)
    
    print("Creating all tables and seeding demo data...")
    init_db()
    
    print("Database reset successfully.")

if __name__ == "__main__":
    reset_db()
