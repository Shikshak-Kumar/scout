import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.main import app

client = TestClient(app)


def test_ingest_accepts_an_opportunity_payload():
    response = client.post(
        "/ingest",
        json={
            "source": "demo-source",
            "title": "Senior Python Engineer",
            "company": "Northstar Labs",
            "location": "Remote",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "queued"
    assert "broker_published" in payload
