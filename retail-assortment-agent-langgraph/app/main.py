from fastapi import FastAPI

app = FastAPI(title="retail-assortment-agent-langgraph")

@app.get("/health")
def health():
    return {"ok": True, "repo": "retail-assortment-agent-langgraph"}