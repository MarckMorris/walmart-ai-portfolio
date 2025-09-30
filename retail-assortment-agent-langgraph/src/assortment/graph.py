from __future__ import annotations
from typing import Dict, Any
from langgraph.graph import StateGraph, END
from pydantic import BaseModel, Field
from .tools import load_catalog, propose_plan, verify_constraints

class AssortmentState(BaseModel):
    input: Dict[str, Any]
    plan: list = Field(default_factory=list)
    report: Dict[str, Any] = Field(default_factory=dict)
    iterations: int = 0

def node_ingest(state: AssortmentState) -> AssortmentState:
    required = ["category", "budget"]
    for k in required:
        if k not in state.input:
            raise ValueError(f"Missing required field: {k}")
    return state

def node_propose(state: AssortmentState) -> AssortmentState:
    params = state.input
    items = load_catalog(params["category"])
    plan = propose_plan(
        items=items,
        budget=float(params["budget"]),
        min_margin=float(params.get("min_margin", 0.2)),
        min_stock=int(params.get("min_stock", 30)),
    )
    state.plan = plan
    return state

def node_verify(state: AssortmentState) -> AssortmentState:
    params = state.input
    rep = verify_constraints(
        plan=state.plan,
        budget=float(params["budget"]),
        max_lead_days=int(params.get("max_lead_days", 14)),
    )
    state.report = rep
    state.iterations += 1
    return state

def should_revise(state: AssortmentState) -> str:
    if not state.report.get("ok", False) and state.iterations < 2:
        return "revise"
    return "finalize"

def node_revise(state: AssortmentState) -> AssortmentState:
    new_input = dict(state.input)
    new_input["min_stock"] = max(10, int(new_input.get("min_stock", 30)) - 10)
    state.input = new_input
    return state

def build_graph():
    g = StateGraph(AssortmentState)
    g.add_node("ingest", node_ingest)
    g.add_node("propose", node_propose)
    g.add_node("verify", node_verify)
    g.add_node("revise", node_revise)
    g.set_entry_point("ingest")
    g.add_edge("ingest", "propose")
    g.add_edge("propose", "verify")
    g.add_conditional_edges("verify", should_revise, {
        "revise": "revise",
        "finalize": END
    })
    g.add_edge("revise", "propose")
    return g.compile()
