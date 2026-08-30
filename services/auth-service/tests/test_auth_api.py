import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.main import app

client = TestClient(app)


def test_signup_and_login_flow():
    signup = client.post("/signup", json={"email": "user@example.com", "password": "secret123"})
    assert signup.status_code == 200
    payload = signup.json()
    assert payload["email"] == "user@example.com"

    login = client.post("/login", json={"email": "user@example.com", "password": "secret123"})
    assert login.status_code == 200
    data = login.json()
    assert "access_token" in data
    assert "refresh_token" in data

    token = data["access_token"]
    verified = client.get("/verify-token", headers={"Authorization": f"Bearer {token}"})
    assert verified.status_code == 200
    assert verified.json()["valid"] is True


def test_refresh_flow():
    login = client.post("/login", json={"email": "user@example.com", "password": "secret123"})
    refresh_token = login.json()["refresh_token"]

    refreshed = client.post("/refresh", json={"refresh_token": refresh_token})
    assert refreshed.status_code == 200
    assert "access_token" in refreshed.json()
