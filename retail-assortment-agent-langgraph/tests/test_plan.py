import json
from fastapi.testclient import TestClient
from app.main import app

def test_assortment_plan_endpoint():
    client = TestClient(app)
    payload = {"category": "Beverages", "budget": 100.0}
    r = client.post("/assortment/plan", json=payload)
    assert r.status_code == 200, r.text
    data = r.json()
    assert "plan" in data and isinstance(data["plan"], list)
    assert "report" in data and data["report"]["checks"]["budget"] is True
