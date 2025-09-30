from fastapi.testclient import TestClient
from app.main import app

def test_planogram_basic():
    c = TestClient(app)
    payload = {
        "category": "Beverages",
        "skus": [
            {"sku": "BVG-001", "facings": 1, "lead_days": 7, "margin": 0.2},
            {"sku": "BVG-002", "facings": 3, "lead_days": 12, "margin": 0.1},
        ]
    }
    r = c.post("/planogram/check", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert "ok" in data and data["ok"] is False
    assert "violations" in data and len(data["violations"]) >= 1
    assert "suggestions" in data and len(data["suggestions"]) >= 1
