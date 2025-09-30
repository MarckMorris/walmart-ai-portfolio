# Merch Forecast Comparator Langchain

Production-ready scaffold aligned with Walmart WD2298861 — AI/GenAI/Agentic AI for Sam’s Club merchandising.

**Domain:** MERCHANDISING

## Quickstart
```bash
cp .env.example .env   # set OPENAI_API_KEY / GOOGLE_API_KEY
docker compose up --build
# or
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## API
- `GET /health` – health check
- `POST /echo` – echo your prompt, returns the selected PROVIDER

## Evaluation
```bash
python eval/run.py --dataset data/samples.jsonl
```

## Kubernetes
```bash
kubectl create ns walmart-demo || true
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/hpa.yaml
```

## Role Alignment
- LLMs / agent frameworks / evaluation pipelines map to WD2298861 needs.
- Domain: MERCHANDISING. Roadmap adds LangGraph/LangChain/CrewAI logic.
