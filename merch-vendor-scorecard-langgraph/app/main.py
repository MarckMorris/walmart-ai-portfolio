from fastapi import FastAPI

app = FastAPI(title="merch-vendor-scorecard-langgraph")

@app.get("/health")
def health():
    return {"ok": True, "repo": "merch-vendor-scorecard-langgraph"}