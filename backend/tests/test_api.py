import pytest
import os
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import Base, get_db
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models.role import Role
from app.models.user import User
from app.core.security import get_password_hash

# Setup testing DB
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine_test = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine_test)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(scope="module", autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine_test)
    db = TestingSessionLocal()
    
    # Create roles safely
    role_officer = db.query(Role).filter(Role.name == "FIELD_OFFICER").first()
    if not role_officer:
        role_officer = Role(name="FIELD_OFFICER")
        db.add(role_officer)
    
    role_admin = db.query(Role).filter(Role.name == "ADMIN").first()
    if not role_admin:
        role_admin = Role(name="ADMIN")
        db.add(role_admin)
        
    db.commit()
    db.refresh(role_officer)
    db.refresh(role_admin)
    
    # Create test user safely
    user = db.query(User).filter(User.username == "testuser").first()
    if not user:
        user = User(username="testuser", password_hash=get_password_hash("password123"), role_id=role_officer.id)
        db.add(user)
        db.commit()
    
    yield
    db.close()
    Base.metadata.drop_all(bind=engine_test)
    if os.path.exists("./test.db"):
        try:
            os.remove("./test.db")
        except Exception:
            pass

client = TestClient(app)

def test_login_success():
    response = client.post("/api/v1/auth/login", json={"username": "testuser", "password": "password123"})
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["username"] == "testuser"
    assert data["user"]["role"] == "FIELD_OFFICER"

def test_login_failure():
    response = client.post("/api/v1/auth/login", json={"username": "testuser", "password": "wrong"})
    assert response.status_code == 401

def test_upload_evidence_unauthorized():
    response = client.post("/api/v1/evidence/upload", data={"capture_id": "123"})
    assert response.status_code == 401
