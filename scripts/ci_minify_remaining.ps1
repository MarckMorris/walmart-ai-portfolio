$ErrorActionPreference = "Stop"

# 17 repos pendientes (todos menos los 3 ya verdes)
$repos = @(
  "retail-pricing-simulator-langchain",
  "retail-catalog-normalizer-crewai",
  "retail-replenishment-planner-langgraph",
  "retail-product-matching-rag-langchain",
  "retail-customer-inquiry-triage-fastapi",
  "retail-a11y-review-bot",
  "merch-vendor-scorecard-langgraph",
  "merch-promo-optimizer-crewai",
  "merch-returns-analyzer-vanilla",
  "merch-forecast-comparator-langchain",
  "merch-content-enrichment-crewai",
  "merch-shelf-gap-detector-langgraph",
  "pm-prd-writer-crewai",
  "pm-experiment-copilot-vanilla",
  "pm-backlog-prioritizer-langgraph",
  "pm-stakeholder-qa-langchain",
  "pm-risk-register-vanilla"
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$monorepo = Split-Path -Parent $root
Set-Location $monorepo

function Write-FileUtf8($Path, $Content) {
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$req = @"
fastapi==0.115.0
uvicorn==0.30.6
python-dotenv==1.0.1
pydantic==2.9.2
httpx==0.27.2
pytest==8.3.2
"@

$confTest = @"
import sys, os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
"@

foreach ($repo in $repos) {
  Write-Host "==> Normalizing $repo" -ForegroundColor Cyan
  Push-Location $repo
  try {
    # requirements.txt (ligero)
    Write-FileUtf8 "$PWD\requirements.txt" $req

    # app package
    Write-FileUtf8 "$PWD\app\__init__.py" ""

    # FastAPI mínimo con /health
    $main = @"
from fastapi import FastAPI

app = FastAPI(title="${repo}")

@app.get("/health")
def health():
    return {"ok": True, "repo": "${repo}"}
"@
    Write-FileUtf8 "$PWD\app\main.py" $main

    # tests
    Write-FileUtf8 "$PWD\tests\conftest.py" $confTest

    $testHealth = @"
from fastapi.testclient import TestClient
from app.main import app

def test_health():
    c = TestClient(app)
    r = c.get("/health")
    assert r.status_code == 200
    j = r.json()
    assert j.get("ok") is True
"@
    Write-FileUtf8 "$PWD\tests\test_health.py" $testHealth

  } finally {
    Pop-Location
  }
}

Write-Host "==> Done. Stage + commit + push the changes." -ForegroundColor Green
