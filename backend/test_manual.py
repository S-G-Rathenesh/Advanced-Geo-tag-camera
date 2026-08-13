import requests
import base64
import json

base_url = "http://127.0.0.1:8000"

def mock_google_token(email, sub, name):
    header = base64.urlsafe_b64encode(json.dumps({"alg": "HS256", "typ": "JWT"}).encode()).decode()
    payload = base64.urlsafe_b64encode(json.dumps({
        "email": email,
        "sub": sub,
        "name": name,
        "picture": None
    }).encode()).decode()
    return f"{header}.{payload}.mocksignature"

def run_tests():
    # 1. Officer Login
    print("Testing Officer Login...")
    resp = requests.post(f"{base_url}/api/v1/auth/officer/login", json={
        "username": "demo_officer",
        "password": "password123"
    })
    if resp.status_code != 200:
        print(f"Error: {resp.text}")
    assert resp.status_code == 200
    officer_token = resp.json()["access_token"]
    print("OK")
    
    # 2. Google Login as New User defaults to USER
    print("Testing New User Login...")
    import time
    random_str = str(time.time())
    new_email = f"new_{random_str}@gmail.com"
    new_sub = f"new_sub_{random_str}"
    
    resp = requests.post(f"{base_url}/api/v1/auth/google", json={
        "id_token": mock_google_token(new_email, new_sub, "New User")
    })
    assert resp.status_code == 200
    assert resp.json()["user"]["role"] == "USER"
    new_user_id = resp.json()["user"]["id"]
    new_user_token = resp.json()["access_token"]
    print("OK")
    
    # 3. Google Login as Supervisor
    print("Testing Supervisor Login...")
    resp = requests.post(f"{base_url}/api/v1/auth/google", json={
        "id_token": mock_google_token("demo.supervisor@gmail.com", "demo_google_sup_123", "Demo Supervisor")
    })
    assert resp.status_code == 200
    assert resp.json()["user"]["role"] == "SUPERVISOR"
    print("OK")
    
    # 4. Officer grants supervisor
    print("Testing Officer grants Supervisor...")
    resp = requests.post(f"{base_url}/api/v1/users/{new_user_id}/grant-supervisor", headers={"Authorization": f"Bearer {officer_token}"})
    if resp.status_code != 200:
        print(f"Error: {resp.text}")
    assert resp.status_code == 200
    
    # Verify
    resp = requests.post(f"{base_url}/api/v1/auth/google", json={
        "id_token": mock_google_token(new_email, new_sub, "New User")
    })
    assert resp.json()["user"]["role"] == "SUPERVISOR"
    print("OK")
    
    # 5. User cannot grant supervisor
    print("Testing User cannot grant...")
    resp = requests.post(f"{base_url}/api/v1/users/some_id/grant-supervisor", headers={"Authorization": f"Bearer {new_user_token}"})
    assert resp.status_code == 403
    print("OK")
    
    print("All tests passed!")

if __name__ == "__main__":
    run_tests()
