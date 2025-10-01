from fastapi import FastAPI

app = FastAPI(title="retail-pricing-simulator-langchain")

@app.get("/health")
def health():
    return {"ok": True, "repo": "retail-pricing-simulator-langchain"}