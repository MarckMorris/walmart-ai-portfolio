from fastapi.testclient import TestClient
from app.main import app

def test_simulate_basic():
    c = TestClient(app)
    payload = {
        "items": [
            {"sku": "SKU-001", "new_price": 3.8},  # pequeña baja
            {"sku": "SKU-002", "new_price": 2.7},  # pequeña subida
        ],
        "elasticity_default": -1.4
    }
    r = c.post("/pricing/simulate", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert "summary" in data and "items" in data
    assert isinstance(data["items"], list) and len(data["items"]) >= 3
