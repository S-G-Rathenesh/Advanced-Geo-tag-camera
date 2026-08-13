import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.role import Role
import base64
import json

client = TestClient(app)

def mock_google_token(email, sub, name):
    header = base64.urlsafe_b64encode(json.dumps({"alg": "HS256", "typ": "JWT"}).encode()).decode()
    payload = base64.urlsafe_b64encode(json.dumps({
        "email": email,
        "sub": sub,
        "name": name,
        "picture": None
    }).encode()).decode()
    return f"{header}.{payload}.mocksignature"

def test_officer_login():
    response = client.post("/api/v1/auth/officer/login", json={
        "username": "demo_officer",
        "password": "password123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_new_google_login_defaults_to_user():
    token = mock_google_token("new@gmail.com", "new_sub_1", "New User")
    response = client.post("/api/v1/auth/google", json={"id_token": token})
    assert response.status_code == 200
    data = response.json()
    assert data["user"]["role"] == "USER"

def test_google_login_as_supervisor():
    token = mock_google_token("demo.supervisor@gmail.com", "demo_google_sup_123", "Demo Supervisor")
    response = client.post("/api/v1/auth/google", json={"id_token": token})
    assert response.status_code == 200
    assert response.json()["user"]["role"] == "SUPERVISOR"

def test_officer_can_grant_supervisor():
    # Login as Officer
    officer_resp = client.post("/api/v1/auth/officer/login", json={
        "username": "demo_officer",
        "password": "password123"
    })
    officer_token = officer_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {officer_token}"}
    
    # Register a new user
    user_token_resp = client.post("/api/v1/auth/google", json={
        "id_token": mock_google_token("promote@gmail.com", "promote_sub", "Promote Me")
    })
    user_id = user_token_resp.json()["user"]["id"]
    
    # Officer grants supervisor
    grant_resp = client.post(f"/api/v1/users/{user_id}/grant-supervisor", headers=headers)
    assert grant_resp.status_code == 200
    
    # Check role
    db = SessionLocal()
    user = db.query(User).filter(User.id == user_id).first()
    assert user.role.name == "SUPERVISOR"
    db.close()

def test_user_cannot_grant_supervisor():
    # Login as User
    user_resp = client.post("/api/v1/auth/google", json={
        "id_token": mock_google_token("demo.user1@gmail.com", "demo_google_user_1", "Demo User 1")
    })
    user_token = user_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {user_token}"}
    
    grant_resp = client.post("/api/v1/users/some_id/grant-supervisor", headers=headers)
    assert grant_resp.status_code == 403

def test_supervisor_cannot_grant_supervisor():
    # Login as Supervisor
    sup_resp = client.post("/api/v1/auth/google", json={
        "id_token": mock_google_token("demo.supervisor@gmail.com", "demo_google_sup_123", "Demo Sup")
    })
    sup_token = sup_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {sup_token}"}
    
    grant_resp = client.post("/api/v1/users/some_id/grant-supervisor", headers=headers)
    assert grant_resp.status_code == 403

def test_officer_can_revoke_supervisor():
    # Login as Officer
    officer_resp = client.post("/api/v1/auth/officer/login", json={
        "username": "demo_officer",
        "password": "password123"
    })
    officer_token = officer_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {officer_token}"}
    
    # Get supervisor user
    db = SessionLocal()
    sup = db.query(User).filter(User.email == "demo.supervisor@gmail.com").first()
    sup_id = sup.id
    db.close()
    
    # Officer revokes supervisor
    revoke_resp = client.post(f"/api/v1/users/{sup_id}/revoke-supervisor", headers=headers)
    assert revoke_resp.status_code == 200
    
    db = SessionLocal()
    sup_check = db.query(User).filter(User.id == sup_id).first()
    assert sup_check.role.name == "USER"
    
    # Restore for other tests
    sup_role = db.query(Role).filter(Role.name == "SUPERVISOR").first()
    sup_check.role_id = sup_role.id
    db.commit()
    db.close()
