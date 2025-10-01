from fastapi import FastAPI

app = FastAPI(title="merch-planogram-helper-langchain")

@app.get("/health")
def health():
    return {"ok": True, "repo": "merch-planogram-helper-langchain"}