from fastapi import FastAPI

app = FastAPI(title="pm-backlog-prioritizer-langgraph")

@app.get("/health")
def health():
    return {"ok": True, "repo": "pm-backlog-prioritizer-langgraph"}