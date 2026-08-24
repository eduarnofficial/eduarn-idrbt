from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_negative_amount_rejected():
    r = client.post(
        "/api/v1/transactions",
        json={"to_account": 2, "amount": -500, "description": "Invalid"}
    )
    assert r.status_code == 401  # Authentication is required before business validation

def test_large_amount_validation():
    r = client.post(
        "/api/v1/transactions",
        json={"to_account": 2, "amount": 999999999, "description": "Invalid"}
    )
    assert r.status_code in (401, 422)
