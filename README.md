# Walmart AI Portfolio — 20 Repos (Scaffold)

This bundle contains 20 ready-to-run repository scaffolds aligned with Walmart WD2298861.

## How to use (Windows-friendly)
1. Install: Git, Docker Desktop, Python 3.11, GitHub CLI (`gh`), kubectl.
2. Unzip this bundle. Open a terminal in the root folder.
3. Log in: `gh auth login` (GitHub account: MarckMorris).
4. For any project:
   ```bash
   cd retail-assortment-agent-langgraph
   cp .env.example .env   # add your OPENAI_API_KEY / GOOGLE_API_KEY
   docker compose up --build
   # in another terminal:
   curl http://localhost:8000/health
   ```
5. To create and push all repos automatically:
   - PowerShell: `powershell -ExecutionPolicy Bypass -File scripts/create_and_push_all.ps1`
   - Bash (WSL/macOS/Linux): `bash scripts/create_and_push_all.sh`

## Next steps
- Fill in agent logic (LangGraph/LangChain/CrewAI) in `src/` per project.
- Replace image names in `k8s/deployment.yaml` once you publish container images.
- Keep secrets out of git; use `.env` locally and GitHub Secrets in CI.

License: Apache-2.0 © 2025 MarckMorris
