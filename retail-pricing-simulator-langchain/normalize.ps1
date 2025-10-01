param (
    [string]$Repo = "retail-pricing-simulator-langchain"
)

Write-Host "==> Normalizing $Repo"

# rutas base
$root = (Get-Location).Path
$repoPath = Join-Path $root $Repo
$appPath = Join-Path $repoPath "app"
$srcPath = Join-Path $repoPath "src\pricing"
$dataPath = Join-Path $repoPath "data"
$testsPath = Join-Path $repoPath "tests"

# crear carpetas
New-Item -ItemType Directory -Force $appPath,$srcPath,$dataPath,$testsPath | Out-Null

# __init__.py vacío
Set-Content -Path (Join-Path $appPath "__init__.py") -Value "" -Encoding UTF8

# requirements.txt
@"
fastapi==0.115.0
uvicorn==0.30.6
python-dotenv==1.0.1
pydantic==2.9.2
httpx==0.27.2
pytest==8.3.2
"@ | Set-Content -Path (Join-Path $repoPath "requirements.txt") -Encoding UTF8

# app/main.py
@"
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Dict, Any
from src.pricing.core import load_catalog, simulate

app = FastAPI(title="Retail Pricing Simulator (LangChain base)")

class Item(BaseModel):
    sku: str
    new_price: float = Field(..., gt=0)

class SimRequest(BaseModel):
    items: List[Item]
    elasticity_default: float = -1.4

@app.get("/health")
def health():
    return {"ok": True, "repo": "retail-pricing-simulator-langchain"}

@app.post("/pricing/simulate")
def pricing_sim(req: SimRequest) -> Dict[str, Any]:
    try:
        catalog = load_catalog()
        plan = [{"sku": it.sku, "new_price": float(it.new_price)} for it in req.items]
        out = simulate(catalog, plan, elasticity_default=req.elasticity_default)
        return out
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
"@ | Set-Content -Path (Join-Path $appPath "main.py") -Encoding UTF8

# src/pricing/core.py
@"
from __future__ import annotations
import csv
from typing import Dict, Any, List
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parents[2] / "data"
CATALOG_PATH = DATA_DIR / "catalog.csv"

def load_catalog() -> Dict[str, Dict[str, Any]]:
    if not CATALOG_PATH.exists():
        raise FileNotFoundError(f"Missing catalog: {CATALOG_PATH}")
    by_sku: Dict[str, Dict[str, Any]] = {}
    with CATALOG_PATH.open(newline="", encoding="utf-8-sig") as f:
        r = csv.DictReader(f)
        for row in r:
            sku = row["sku"].strip()
            by_sku[sku] = {
                "sku": sku,
                "price": float(row["price"]),
                "cost": float(row["cost"]),
                "base_volume": float(row["base_volume"]),
                "elasticity": float(row["elasticity"]) if row.get("elasticity") else None,
            }
    return by_sku

def simulate(catalog: Dict[str, Dict[str, Any]], plan: List[Dict[str, Any]], elasticity_default: float = -1.4) -> Dict[str, Any]:
    results: List[Dict[str, Any]] = []
    total_profit_old = 0.0
    total_profit_new = 0.0
    for sku, rec in catalog.items():
        old_price = rec["price"]; cost = rec["cost"]; base_volume = rec["base_volume"]
        elasticity = rec["elasticity"] if rec["elasticity"] is not None else elasticity_default
        new_price = next((p["new_price"] for p in plan if p["sku"] == sku), old_price)
        old_profit = (old_price - cost) * base_volume
        ratio = (new_price / old_price) if old_price > 0 else 1.0
        new_volume = base_volume * (ratio ** elasticity)
        new_profit = (new_price - cost) * new_volume
        total_profit_old += old_profit; total_profit_new += new_profit
        results.append({
            "sku": sku,
            "old_price": round(old_price, 4),
            "new_price": round(new_price, 4),
            "base_volume": round(base_volume, 4),
            "elasticity": round(elasticity, 4),
            "new_volume": round(new_volume, 4),
            "old_profit": round(old_profit, 4),
            "new_profit": round(new_profit, 4),
            "delta_profit": round(new_profit - old_profit, 4),
        })
    return {
        "summary": {
            "old_total_profit": round(total_profit_old, 2),
            "new_total_profit": round(total_profit_new, 2),
            "delta_total_profit": round(total_profit_new - total_profit_old, 2),
        },
        "items": results,
    }
"@ | Set-Content -Path (Join-Path $srcPath "core.py") -Encoding UTF8

# data/catalog.csv
@"
sku,price,cost,base_volume,elasticity
SKU-001,4.00,2.20,1000,-1.5
SKU-002,2.50,1.20,800,-1.2
SKU-003,1.20,0.60,1200,
"@ | Set-Content -Path (Join-Path $dataPath "catalog.csv") -Encoding UTF8

# tests/conftest.py
@"
import sys, os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
"@ | Set-Content -Path (Join-Path $testsPath "conftest.py") -Encoding UTF8

# tests/test_health.py
@"
from fastapi.testclient import TestClient
from app.main import app

def test_health():
    c = TestClient(app)
    r = c.get("/health")
    assert r.status_code == 200
    assert r.json().get("ok") is True
"@ | Set-Content -Path (Join-Path $testsPath "test_health.py") -Encoding UTF8

# tests/test_pricing.py
@"
from fastapi.testclient import TestClient
from app.main import app

def test_simulate_basic():
    c = TestClient(app)
    payload = {
        "items": [
            {"sku": "SKU-001", "new_price": 3.8},
            {"sku": "SKU-002", "new_price": 2.7},
        ],
        "elasticity_default": -1.4
    }
    r = c.post("/pricing/simulate", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert "summary" in data and "items" in data
    assert isinstance(data["items"], list) and len(data["items"]) >= 3
"@ | Set-Content -Path (Join-Path $testsPath "test_pricing.py") -Encoding UTF8

# git
git add $repo/*
git commit -m "normalize($Repo): scaffold FastAPI app, core logic, data and tests"
git push
