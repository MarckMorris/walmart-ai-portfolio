from __future__ import annotations
import csv
from typing import Dict, Any, List
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parents[2] / "data"
RULES_PATH = str(DATA_DIR / "rules.csv")

def load_rules(category: str) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    # utf-8-sig -> elimina BOM si está presente
    with open(RULES_PATH, newline="", encoding="utf-8-sig") as f:
        r = csv.DictReader(f)
        for row in r:
            if row.get("category", "").lower() == category.lower():
                rows.append(row)
    return rows


def check_planogram(category: str, skus: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    skus: [{sku, facings, lead_days, margin}]
    """
    rules = load_rules(category)
    result = {"ok": True, "violations": []}

    def add(rule_id: str, msg: str):
        result["ok"] = False
        result["violations"].append({"rule_id": rule_id, "message": msg})

    for r in rules:
        rid, rule, thr = r["rule_id"], r["rule"], r["threshold"]
        if rule == "Min facings per SKU":
            thr_i = int(thr)
            for s in skus:
                if s.get("facings", 0) < thr_i:
                    add(rid, f"SKU {s['sku']} has {s['facings']}<min {thr_i} facings")
        elif rule == "Max lead days":
            thr_i = int(thr)
            for s in skus:
                if s.get("lead_days", 999) > thr_i:
                    add(rid, f"SKU {s['sku']} lead_days {s['lead_days']}>max {thr_i}")
        elif rule == "Min margin":
            thr_f = float(thr)
            for s in skus:
                margin = float(s.get("margin", 0.0))
                if margin < thr_f:
                    add(rid, f"SKU {s['sku']} margin {margin:.2f}<min {thr_f:.2f}")

    suggestions = []
    if not result["ok"]:
        for v in result["violations"]:
            if "facings" in v["message"]:
                suggestions.append("Increase facings for low-facing SKUs or swap low-velocity items.")
            if "lead_days" in v["message"]:
                suggestions.append("Prefer suppliers with shorter lead times or adjust safety stock.")
            if "margin" in v["message"]:
                suggestions.append("Review cost/price; consider promo removal or alternative SKU.")
    return {**result, "suggestions": sorted(set(suggestions))}
