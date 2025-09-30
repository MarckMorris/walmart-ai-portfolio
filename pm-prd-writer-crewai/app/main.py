from fastapi import FastAPI

app = FastAPI(title="pm-prd-writer-crewai")

@app.get("/health")
def health():
    return {"ok": True, "repo": "pm-prd-writer-crewai"}