import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.main import app

client = TestClient(app)


def test_notification_routes_are_available():
    health = client.get("/health")
    assert health.status_code == 200

    notifications = client.get("/notifications")
    assert notifications.status_code == 200

    preferences = client.get("/preferences")
    assert preferences.status_code == 200
