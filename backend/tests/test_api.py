import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import Base, engine, get_db
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

client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine_test)
    db = TestingSessionLocal()
    
    # Create roles
    role_officer = Role(name="FIELD_OFFICER")
    role_admin = Role(name="ADMIN")
    db.add_all([role_officer, role_admin])
    db.commit()
    
    # Create user
    user = User(username="testuser", password_hash=get_password_hash("password123"), role_id=role_officer.id)
    db.add(user)
    db.commit()
    
    yield
    Base.metadata.drop_all(bind=engine_test)

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
