from fastapi import FastAPI

app = FastAPI(title="pm-okr-advisor-langchain")

@app.get("/health")
def health():
    return {"ok": True, "repo": "pm-okr-advisor-langchain"}