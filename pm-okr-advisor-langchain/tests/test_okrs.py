from fastapi.testclient import TestClient
from app.main import app

def test_okrs_basic():
    c = TestClient(app)
    payload = {
        "timeframe": "Q4-2025",
        "objectives": [
            {
                "title": "Improve conversion rate",
                "krs": [
                    {"name": "Increase PDP conversion", "metric": "cv_rate", "target": 0.03, "baseline": 0.02},
                    {"name": "Reduce checkout drop-off", "metric": "drop_off", "target": 0.15, "baseline": 0.20}
                ]
            },
            {
                "title": "Reduce returns",
                "krs": [
                    {"name": "Returns within 30d", "metric": "returns_rate", "target": 0.10}
                ]
            }
        ]
    }
    r = c.post("/okr/evaluate", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert "average_score" in data
    assert "results" in data and len(data["results"]) == 2
