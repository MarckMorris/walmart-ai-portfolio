#requires -Version 5.0
$ErrorActionPreference = "Stop"

# === Config ===
# Lista de todos los repos del monorepo
$repos = @(
  "retail-assortment-agent-langgraph",
  "retail-pricing-simulator-langchain",
  "retail-catalog-normalizer-crewai",
  "retail-replenishment-planner-langgraph",
  "retail-product-matching-rag-langchain",
  "retail-customer-inquiry-triage-fastapi",
  "retail-a11y-review-bot",
  "merch-vendor-scorecard-langgraph",
  "merch-planogram-helper-langchain",
  "merch-promo-optimizer-crewai",
  "merch-returns-analyzer-vanilla",
  "merch-forecast-comparator-langchain",
  "merch-content-enrichment-crewai",
  "merch-shelf-gap-detector-langgraph",
  "pm-okr-advisor-langchain",
  "pm-prd-writer-crewai",
  "pm-experiment-copilot-vanilla",
  "pm-backlog-prioritizer-langgraph",
  "pm-stakeholder-qa-langchain",
  "pm-risk-register-vanilla"
)

# Requirements mínimos para smoke tests (sin deps pesadas)
$reqMinimal = @"
fastapi==0.115.0
uvicorn==0.30.6
python-dotenv==1.0.1
pydantic==2.9.2
httpx==0.27.2
pytest==8.3.2
"@

# tests/conftest.py para fijar PYTHONPATH al directorio del proyecto
$confTest = @"
import sys, os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
"@

# tests/test_health.py (solo si no existe)
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

Function Write-FileUtf8NoBom {
  param([string]$Path, [string]$Content)
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

Function Ensure-File-ContainsLine {
  param([string]$Path, [string]$Line)
  if (-not (Test-Path $Path)) {
    Write-FileUtf8NoBom -Path $Path -Content $Line
    return
  }
  $content = Get-Content -LiteralPath $Path -Raw
  if ($content -notmatch [regex]::Escape($Line)) {
    $new = $content.TrimEnd() + "`r`n" + $Line + "`r`n"
    Write-FileUtf8NoBom -Path $Path -Content $new
  }
}

# ===== MAIN =====
# Cambia a la raíz del monorepo (donde está este script)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$monorepo = Split-Path -Parent $root
Set-Location $monorepo

Write-Host "Monorepo root: $monorepo" -ForegroundColor Cyan

foreach ($repo in $repos) {
  if (-not (Test-Path $repo)) {
    Write-Warning "Skipping $repo (folder not found)"
    continue
  }

  Write-Host "==> Normalizing $repo" -ForegroundColor Yellow
  Push-Location $repo
  try {
    # 1) app/
    if (-not (Test-Path ".\app")) { New-Item -ItemType Directory -Path ".\app" -Force | Out-Null }
    if (-not (Test-Path ".\app\__init__.py")) { Write-FileUtf8NoBom ".\app\__init__.py" "" }

    # 2) app/main.py (solo si falta; no sobrescribo lógica existente)
    if (-not (Test-Path ".\app\main.py")) {
      $title = $repo
      $main = @"
from fastapi import FastAPI

app = FastAPI(title="${title}")

@app.get("/health")
def health():
    return {"ok": True, "repo": "${title}"}
"@
      Write-FileUtf8NoBom ".\app\main.py" $main
    }

    # 3) tests/
    if (-not (Test-Path ".\tests")) { New-Item -ItemType Directory -Path ".\tests" -Force | Out-Null }
    # conftest.py (si falta o vacío lo escribo; si existe con contenido, lo dejo)
    if (-not (Test-Path ".\tests\conftest.py")) {
      Write-FileUtf8NoBom ".\tests\conftest.py" $confTest
    } else {
      $existing = (Get-Content ".\tests\conftest.py" -Raw)
      if ([string]::IsNullOrWhiteSpace($existing)) {
        Write-FileUtf8NoBom ".\tests\conftest.py" $confTest
      }
    }
    # test_health.py (solo si falta)
    if (-not (Test-Path ".\tests\test_health.py")) {
      Write-FileUtf8NoBom ".\tests\test_health.py" $testHealth
    }

    # 4) requirements.txt
    if (-not (Test-Path ".\requirements.txt")) {
      Write-FileUtf8NoBom ".\requirements.txt" $reqMinimal
    } else {
      # asegura pytest esté presente
      Ensure-File-ContainsLine -Path ".\requirements.txt" -Line "pytest==8.3.2"
      # No tocamos otras dependencias para no romper lógicas existentes
    }

    # 5) data/.gitkeep (crea data/ si no existe y añade .gitkeep)
    if (-not (Test-Path ".\data")) {
  New-Item -ItemType Directory -Path ".\data" -Force | Out-Null
    }
    if (-not (Test-Path ".\data\.gitkeep")) {
        New-Item -ItemType File -Path ".\data\.gitkeep" -Force | Out-Null
    }



  } finally {
    Pop-Location
  }
}

Write-Host "==> Normalization done." -ForegroundColor Green

# Git stage/commit/push
git add .
if ($LASTEXITCODE -ne 0) { throw "git add failed" }

# Si no hay cambios, no fallar
$pending = git status --porcelain
if (-not $pending) {
  Write-Host "No changes to commit." -ForegroundColor Cyan
  exit 0
}

git commit -m "chore(ci): normalize all projects (health endpoint, tests, minimal requirements)"
if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

git push
if ($LASTEXITCODE -ne 0) { throw "git push failed" }

Write-Host "Pushed! GitHub Actions will run Monorepo CI now." -ForegroundColor Green
