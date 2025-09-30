from fastapi import FastAPI
from pydantic import BaseModel
import os

app = FastAPI(title="Walmart AI Demo", version="0.1.0")

class Prompt(BaseModel):
    text: str

@app.get("/health")
def health():
    return {"ok": True, "repo": os.getenv("REPO_NAME", "unknown")}

@app.post("/echo")
def echo(p: Prompt):
    provider = os.getenv("PROVIDER", "none")
    return {"provider": provider, "echo": p.text}
