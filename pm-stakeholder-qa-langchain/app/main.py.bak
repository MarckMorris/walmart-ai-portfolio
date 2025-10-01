from fastapi import FastAPI

app = FastAPI(title="pm-stakeholder-qa-langchain")

@app.get("/health")
def health():
    return {"ok": True, "repo": "pm-stakeholder-qa-langchain"}