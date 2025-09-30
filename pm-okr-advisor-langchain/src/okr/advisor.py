from __future__ import annotations
from typing import List, Dict, Any, TypedDict

class Suggestion(TypedDict):
    type: str
    message: str
    path: str

def _is_smart(kr: Dict[str, Any]) -> List[Suggestion]:
    out: List[Suggestion] = []
    name = kr.get("name", "").strip()
    metric = kr.get("metric", "").strip()
    target = kr.get("target", None)
    if not name:
        out.append({"type": "missing_name", "message": "KR needs a clear statement.", "path": "kr.name"})
    if not metric:
        out.append({"type": "missing_metric", "message": "KR needs a measurable metric.", "path": "kr.metric"})
    if target is None:
        out.append({"type": "missing_target", "message": "KR needs a numeric target.", "path": "kr.target"})
    return out

def _check_alignment(objective: Dict[str, Any]) -> List[Suggestion]:
    out: List[Suggestion] = []
    title = (objective.get("title") or "").lower()
    for kr in objective.get("krs", []):
        name = (kr.get("name") or "").lower()
        # naive alignment: basic keyword overlap
        if title and name and len(set(title.split()) & set(name.split())) == 0:
            out.append({
                "type": "weak_alignment",
                "message": f"KR '{kr.get('name')}' may not align with objective '{objective.get('title')}'.",
                "path": f"objective[{objective.get('title')}].krs[{kr.get('name')}]"
            })
    return out

def _check_quality(objective: Dict[str, Any]) -> Dict[str, Any]:
    suggestions: List[Suggestion] = []
    score = 100

    if not objective.get("title"):
        suggestions.append({"type": "missing_title", "message": "Objective needs a title.", "path": "objective.title"})
        score -= 20

    krs = objective.get("krs", [])
    if not krs:
        suggestions.append({"type": "missing_krs", "message": "Objective should have at least one KR.", "path": "objective.krs"})
        score -= 40

    for i, kr in enumerate(krs):
        sug = _is_smart(kr)
        if sug:
            suggestions.extend(sug)
            score -= 10
    suggestions.extend(_check_alignment(objective))
    score = max(0, min(100, score))
    return {"score": score, "suggestions": suggestions}

def evaluate_okrs(timeframe: str, objectives: List[Dict[str, Any]]) -> Dict[str, Any]:
    results = []
    total = 0
    for obj in objectives:
        q = _check_quality(obj)
        results.append({"objective": obj.get("title", ""), **q})
        total += q["score"]
    avg = int(round(total / max(1, len(objectives))))
    # lightweight rubric
    band = "excellent" if avg >= 85 else "good" if avg >= 70 else "fair" if avg >= 50 else "needs_improvement"
    return {"timeframe": timeframe, "average_score": avg, "band": band, "results": results}
