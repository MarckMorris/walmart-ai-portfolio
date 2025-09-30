from fastapi import FastAPI

app = FastAPI(title="retail-customer-inquiry-triage-fastapi")

@app.get("/health")
def health():
    return {"ok": True, "repo": "retail-customer-inquiry-triage-fastapi"}