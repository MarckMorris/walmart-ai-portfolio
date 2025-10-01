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
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Ensure-Line {
  param([string]$Path, [string]$Line)
  if (-not (Test-Path $Path)) {
    Write-UTF8NoBom -Path $Path -Content "$Line`r`n"
    return
  }
  $raw = Get-Content -LiteralPath $Path -Raw
  if ($raw -notmatch [regex]::Escape($Line)) {
    Write-UTF8NoBom -Path $Path -Content ($raw.TrimEnd() + "`r`n" + $Line + "`r`n")
  }
}

# === 1) Parchear workflow para PYTHONPATH ===
$wf = ".github/workflows/monorepo-ci.yml"
if (Test-Path $wf) {
  Write-Host "Patching $wf for PYTHONPATH..." -ForegroundColor Cyan
  $yml = Get-Content $wf -Raw

  if ($yml -notmatch "Export PYTHONPATH to project root") {
    # Insertamos el paso justo antes de "Run tests"
    $pyStep = @'
      - name: Export PYTHONPATH to project root
        run: echo "PYTHONPATH=$PWD" >> $GITHUB_ENV
'@
    if ($yml -match "(- name:\s*Run tests\s*[\r\n]+.*?pytest.*)") {
      # metemos el paso de export justo antes de "Run tests"
      $yml = $yml -replace "(\s*- name:\s*Run tests\s*[\r\n])", "$pyStep`$1"
    } else {
      # si no encontramos el paso, lo añadimos al final de steps
      $yml = $yml -replace "(steps:\s*[\r\n]+)", "`$1$pyStep"
    }
    Write-UTF8NoBom -Path $wf -Content $yml
  } else {
    Write-Host "Workflow already exports PYTHONPATH." -ForegroundColor DarkGray
  }
} else {
  Write-Warning "Workflow file not found: $wf"
}

# === 2) Normalizar cada repo ===
$root = (Get-Location).Path
foreach ($repo in $repos) {
  if (-not (Test-Path $repo)) {
    Write-Warning "Skipping '$repo' (folder not found)"
    continue
  }
  Write-Host "==> Fixing $repo" -ForegroundColor Yellow
  Push-Location $repo
  try {
    # Estructura
    New-Item -ItemType Directory -Force "app","tests","data" | Out-Null
    if (-not (Test-Path "app\__init__.py")) { Write-UTF8NoBom "app\__init__.py" "" }

    # app/main.py
    $mainPath = "app\main.py"
    if ($ForceMinimalApp) {
      if (Test-Path $mainPath) {
        Copy-Item $mainPath "$mainPath.bak" -Force
      }
      $content = @"
from fastapi import FastAPI

app = FastAPI(title="$repo")

@app.get("/health")
def health():
    return {"ok": True, "repo": "$repo"}
"@
      Write-UTF8NoBom $mainPath $content
    } elseif (-not (Test-Path $mainPath)) {
      $content = @"
from fastapi import FastAPI

app = FastAPI(title="$repo")

@app.get("/health")
def health():
    return {"ok": True, "repo": "$repo"}
"@
      Write-UTF8NoBom $mainPath $content
    }

    # tests/
    if (-not (Test-Path "tests\conftest.py")) { Write-UTF8NoBom "tests\conftest.py" $confTest }
    if (-not (Test-Path "tests\test_health.py")) { Write-UTF8NoBom "tests\test_health.py" $testHealth }

    # requirements.txt
    if (-not (Test-Path "requirements.txt")) {
      Write-UTF8NoBom "requirements.txt" $reqMinimal
    } else {
      Ensure-Line -Path "requirements.txt" -Line "pytest==8.3.2"
    }

    # data/.gitkeep
    if (-not (Test-Path "data\.gitkeep")) {
      New-Item -ItemType File -Path "data\.gitkeep" -Force | Out-Null
    }
  }
  finally {
    Pop-Location
  }
}

Write-Host "Staging changes..." -ForegroundColor Cyan
git add -A
$pending = git status --porcelain
if (-not $pending) {
  Write-Host "No changes to commit." -ForegroundColor Green
  exit 0
}

git commit -m "fix(ci): standardize repos (health endpoint, tests, minimal requirements) + set PYTHONPATH in workflow"
git push
Write-Host "Done. Actions will run Monorepo CI now." -ForegroundColor Green
