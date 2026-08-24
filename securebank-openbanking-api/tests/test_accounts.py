from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def token(username):
    r = client.post("/auth/token", data={"username": username, "password": "password123"})
    return r.json()["access_token"]

def test_alice_can_see_own_accounts():
    r = client.get("/api/v1/accounts", headers={"Authorization": f"Bearer {token('alice')}"})
    assert r.status_code == 200
    assert len(r.json()) >= 1

def test_bola_is_blocked():
    r = client.get("/api/v1/accounts/2", headers={"Authorization": f"Bearer {token('alice')}"})
    assert r.status_code == 403
