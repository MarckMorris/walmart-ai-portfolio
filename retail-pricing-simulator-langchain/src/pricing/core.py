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
