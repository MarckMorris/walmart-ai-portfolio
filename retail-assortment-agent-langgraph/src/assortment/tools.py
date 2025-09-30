from __future__ import annotations
import csv
from typing import Dict, Any, List

CATALOG_PATH = "data/catalog.csv"

def load_catalog(category: str) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    with open(CATALOG_PATH, newline="", encoding="utf-8") as f:
        r = csv.DictReader(f)
        for row in r:
            if row["category"].lower() == category.lower():
                # normalizamos tipos
                row["cost"] = float(row["cost"])
                row["price"] = float(row["price"])
                row["lead_days"] = int(row["lead_days"])
                row["stock"] = int(row["stock"])
                rows.append(row)
    return rows

def propose_plan(
    items: List[Dict[str, Any]],
    budget: float,
    min_margin: float = 0.2,
    min_stock: int = 30,
) -> List[Dict[str, Any]]:
    # calcula margen y utilidad por unidad
    enriched: List[Dict[str, Any]] = []
    for it in items:
        margin = (it["price"] - it["cost"]) / it["price"] if it["price"] else 0.0
        if margin >= min_margin and it["stock"] >= min_stock:
            profit_unit = it["price"] - it["cost"]
            enriched.append({**it, "margin": margin, "profit_unit": profit_unit})
    # ordena por utilidad unitaria desc
    enriched.sort(key=lambda x: x["profit_unit"], reverse=True)

    selection: List[Dict[str, Any]] = []
    remaining = budget
    for it in enriched:
        block_cost = it["cost"] * min_stock
        if block_cost <= remaining:
            selection.append({
                "sku": it["sku"],
                "units": min_stock,
                "unit_cost": float(it["cost"]),
                "unit_price": float(it["price"]),
                "lead_days": int(it["lead_days"]),
                "brand": it["brand"],
            })
            remaining -= block_cost
    return selection

def verify_constraints(plan: List[Dict[str, Any]], budget: float, max_lead_days: int | None = None) -> Dict[str, Any]:
    total_cost = sum(p["units"] * p["unit_cost"] for p in plan)
    max_lead = max((p["lead_days"] for p in plan), default=0)
    ok_budget = total_cost <= budget + 1e-6
    ok_lead = True if max_lead_days is None else (max_lead <= max_lead_days)
    return {
        "ok": ok_budget and ok_lead,
        "total_cost": round(total_cost, 2),
        "max_lead_days": int(max_lead),
        "checks": {"budget": ok_budget, "lead_time": ok_lead},
    }
