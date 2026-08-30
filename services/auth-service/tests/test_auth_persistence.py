import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.main import app

client = TestClient(app)


def test_signup_persists_user_and_rejects_duplicate_email():
    signup = client.post("/signup", json={"email": "persisted@example.com", "password": "secret123"})
    assert signup.status_code == 200
    assert signup.json()["email"] == "persisted@example.com"

    duplicate = client.post("/signup", json={"email": "persisted@example.com", "password": "secret123"})
    assert duplicate.status_code == 409

    bad_login = client.post("/login", json={"email": "persisted@example.com", "password": "wrongpass"})
    assert bad_login.status_code == 401

    good_login = client.post("/login", json={"email": "persisted@example.com", "password": "secret123"})
    assert good_login.status_code == 200
    assert "access_token" in good_login.json()
