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
