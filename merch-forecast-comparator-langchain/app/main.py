from fastapi import FastAPI

app = FastAPI(title="merch-forecast-comparator-langchain")

@app.get("/health")
def health():
    return {"ok": True, "repo": "merch-forecast-comparator-langchain"}