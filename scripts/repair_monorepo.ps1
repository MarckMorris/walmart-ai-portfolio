#requires -Version 5.0
param(
  [switch]$ForceMinimalApp = $false  # Si lo pasas, sobreescribe app/main.py (con backup)
)

$ErrorActionPreference = "Stop"

# === Repos del monorepo (20) ===
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

# === Contenidos base ===
$reqMinimal = @'
fastapi==0.115.0
uvicorn==0.30.6
python-dotenv==1.0.1
pydantic==2.9.2
httpx==0.27.2
pytest==8.3.2
'@

$confTest = @'
import sys, os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
'@

$testHealth = @'
from fastapi.testclient import TestClient
from app.main import app

def test_health():
    c = TestClient(app)
    r = c.get("/health")
    assert r.status_code == 200
    j = r.json()
    assert j.get("ok") is True
'@

function Write-UTF8NoBom {
  param([string]$Path, [string]$Content)
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Ensure-Line {
  param([string]$Path, [string]$Line)
  if (-not (Test-Path -LiteralPath $Path)) {
    Write-UTF8NoBom -Path $Path -Content "$Line`r`n"
    return
  }
  $raw = Get-Content -LiteralPath $Path -Raw
  if ($raw -notmatch [regex]::Escape($Line)) {
    Write-UTF8NoBom -Path $Path -Content ($raw.TrimEnd() + "`r`n" + $Line + "`r`n")
  }
}

# === 1) Parchear workflow para PYTHONPATH (no rompe YAML) ===
$wfPath = ".github/workflows/monorepo-ci.yml"
if (Test-Path $wfPath) {
  Write-Host "Patching $wfPath for PYTHONPATH..." -ForegroundColor Cyan
  $yml = Get-Content $wfPath -Raw
  if ($yml -notmatch "Export PYTHONPATH to project root") {
    $pyStep = @'
      - name: Export PYTHONPATH to project root
        run: echo "PYTHONPATH=$PWD" >> $GITHUB_ENV
'@
    if ($yml -match "(\s*- name:\s*Run tests\s*[\r\n])") {
      $yml = $yml -replace "(\s*- name:\s*Run tests\s*[\r\n])", "$pyStep`$1"
    } else {
      $yml = $yml -replace "(steps:\s*[\r\n]+)", "`$1$pyStep"
    }
    Write-UTF8NoBom -Path $wfPath -Content $yml
  } else {
    Write-Host "Workflow already exports PYTHONPATH." -ForegroundColor DarkGray
  }
} else {
  Write-Warning "Workflow file not found: $wfPath"
}

# === 2) Normalizar cada repo con RUTAS ABSOLUTAS ===
$root = (Get-Location).Path
foreach ($repo in $repos) {
  $repoRoot   = Join-Path $root $repo
  if (-not (Test-Path -LiteralPath $repoRoot)) {
    Write-Warning "Skipping '$repo' (folder not found: $repoRoot)"
    continue
  }

  Write-Host "==> Fixing $repo" -ForegroundColor Yellow

  $appDir     = Join-Path $repoRoot "app"
  $testsDir   = Join-Path $repoRoot "tests"
  $dataDir    = Join-Path $repoRoot "data"
  $mainPath   = Join-Path $appDir   "main.py"
  $initPath   = Join-Path $appDir   "__init__.py"
  $reqPath    = Join-Path $repoRoot "requirements.txt"
  $confPath   = Join-Path $testsDir "conftest.py"
  $healthPath = Join-Path $testsDir "test_health.py"
  $keepPath   = Join-Path $dataDir  ".gitkeep"

  # Crear carpetas necesarias (absolutas)
  foreach ($d in @($appDir, $testsDir, $dataDir)) {
    if (-not (Test-Path -LiteralPath $d)) {
      New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
  }

  # app/__init__.py
  if (-not (Test-Path -LiteralPath $initPath)) {
    Write-UTF8NoBom -Path $initPath -Content ""
  }

  # app/main.py (mínimo o respetando existente)
  if ($ForceMinimalApp) {
    if (Test-Path -LiteralPath $mainPath) {
      Copy-Item -LiteralPath $mainPath -Destination "$mainPath.bak" -Force
    }
    $content = @"
from fastapi import FastAPI

app = FastAPI(title="$repo")

@app.get("/health")
def health():
    return {"ok": True, "repo": "$repo"}
"@
    Write-UTF8NoBom -Path $mainPath -Content $content
  } elseif (-not (Test-Path -LiteralPath $mainPath)) {
    $content = @"
from fastapi import FastAPI

app = FastAPI(title="$repo")

@app.get("/health")
def health():
    return {"ok": True, "repo": "$repo"}
"@
    Write-UTF8NoBom -Path $mainPath -Content $content
  }

  # tests/
  if (-not (Test-Path -LiteralPath $confPath)) {
    Write-UTF8NoBom -Path $confPath -Content $confTest
  }
  if (-not (Test-Path -LiteralPath $healthPath)) {
    Write-UTF8NoBom -Path $healthPath -Content $testHealth
  }

  # requirements.txt
  if (-not (Test-Path -LiteralPath $reqPath)) {
    Write-UTF8NoBom -Path $reqPath -Content $reqMinimal
  } else {
    Ensure-Line -Path $reqPath -Line "pytest==8.3.2"
  }

  # data/.gitkeep
  if (-not (Test-Path -LiteralPath $keepPath)) {
    New-Item -ItemType File -Path $keepPath -Force | Out-Null
  }
}

Write-Host "Staging changes..." -ForegroundColor Cyan
git add -A
$pending = git status --porcelain
if (-not $pending) {
  Write-Host "No changes to commit." -ForegroundColor Green
  exit 0
}

git commit -m "fix(ci): standardize repos (health endpoint, tests, minimal requirements) + use absolute paths"
git push
Write-Host "Done. Actions will run Monorepo CI now." -ForegroundColor Green
