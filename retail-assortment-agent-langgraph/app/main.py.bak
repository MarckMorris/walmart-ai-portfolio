from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Any, Dict
from src.assortment.graph import build_graph, AssortmentState

app = FastAPI(title="Assortment Agent (LangGraph)")

class AssortmentRequest(BaseModel):
    category: str
    budget: float
    min_margin: float | None = 0.2
    min_stock: int | None = 30
    max_lead_days: int | None = 14

graph = build_graph()

@app.get("/health")
def health():
    return {"ok": True, "repo": "retail-assortment-agent-langgraph"}

@app.post("/assortment/plan")
def plan(req: AssortmentRequest):
    try:
        init_state = AssortmentState(input=req.dict())
        out = graph.invoke(init_state)

        # LangGraph suele retornar un dict-like (AddableValuesDict)
        if isinstance(out, AssortmentState):
            payload = out.dict()
        elif isinstance(out, dict):
            payload = out
        else:
            # fallback: intenta .dict() y si no, convierte a dict simple
            payload = getattr(out, "dict", lambda: dict(out))()

        return {
            "plan": payload.get("plan", []),
            "report": payload.get("report", {}),
            "iterations": payload.get("iterations", 0),
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
