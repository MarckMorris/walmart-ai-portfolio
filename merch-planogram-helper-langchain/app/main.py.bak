from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from src.planogram.core import check_planogram

app = FastAPI(title="Merch Planogram Helper (LangChain base)")

class SKU(BaseModel):
    sku: str
    facings: int
    lead_days: int
    margin: float

class PlanogramRequest(BaseModel):
    category: str
    skus: List[SKU]

@app.get("/health")
def health():
    return {"ok": True, "repo": "merch-planogram-helper-langchain"}

@app.post("/planogram/check")
def planogram_check(req: PlanogramRequest):
    try:
        report = check_planogram(req.category, [s.dict() for s in req.skus])
        return report
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
