from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Dict, Any
from src.okr.advisor import evaluate_okrs, Suggestion

app = FastAPI(title="PM OKR Advisor (LangChain base)")

class KR(BaseModel):
    name: str = Field(..., description="Key Result statement")
    metric: str = Field(..., description="Metric measured")
    target: float = Field(..., description="Target value")
    baseline: float | None = Field(None, description="Optional baseline value")
    frequency: str | None = Field("weekly", description="How often we measure")

class Objective(BaseModel):
    title: str
    description: str | None = None
    krs: List[KR]

class OKRRequest(BaseModel):
    timeframe: str = "Q4-2025"
    objectives: List[Objective]

@app.get("/health")
def health():
    return {"ok": True, "repo": "pm-okr-advisor-langchain"}

@app.post("/okr/evaluate")
def okr_evaluate(req: OKRRequest) -> Dict[str, Any]:
    try:
        report: Dict[str, Any] = evaluate_okrs(req.timeframe, [o.dict() for o in req.objectives])
        return report
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
