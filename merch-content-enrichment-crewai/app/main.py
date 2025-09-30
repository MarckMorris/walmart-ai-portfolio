from fastapi import FastAPI

app = FastAPI(title="merch-content-enrichment-crewai")

@app.get("/health")
def health():
    return {"ok": True, "repo": "merch-content-enrichment-crewai"}