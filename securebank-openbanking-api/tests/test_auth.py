from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    assert client.get("/health").status_code == 200

def test_login():
    r = client.post("/auth/token", data={"username": "alice", "password": "password123"})
    assert r.status_code == 200
    assert "access_token" in r.json()
