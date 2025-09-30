from fastapi import FastAPI

app = FastAPI(title="retail-a11y-review-bot")

@app.get("/health")
def health():
    return {"ok": True, "repo": "retail-a11y-review-bot"}