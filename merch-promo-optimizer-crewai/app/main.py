from fastapi import FastAPI

app = FastAPI(title="merch-promo-optimizer-crewai")

@app.get("/health")
def health():
    return {"ok": True, "repo": "merch-promo-optimizer-crewai"}