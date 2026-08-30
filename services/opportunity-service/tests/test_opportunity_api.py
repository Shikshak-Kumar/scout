import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.main import app

client = TestClient(app)


def test_opportunity_list_and_detail():
    list_response = client.get("/opportunities")
    assert list_response.status_code == 200
    items = list_response.json()["items"]
    assert isinstance(items, list)
    assert len(items) >= 1

    opportunity_id = items[0]["id"]
    detail = client.get(f"/opportunities/{opportunity_id}")
    assert detail.status_code == 200
    assert detail.json()["id"] == opportunity_id


def test_bookmark_round_trip():
    opportunity_id = "demo-opportunity-1"
    add = client.post(f"/bookmarks/{opportunity_id}")
    assert add.status_code == 200
    assert add.json()["opportunity_id"] == opportunity_id

    list_response = client.get("/bookmarks")
    assert list_response.status_code == 200
    assert any(item["opportunity_id"] == opportunity_id for item in list_response.json()["items"])

    delete_response = client.delete(f"/bookmarks/{opportunity_id}")
    assert delete_response.status_code == 200
    assert delete_response.json()["removed"] is True
