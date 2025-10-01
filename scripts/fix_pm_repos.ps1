# scripts/fix_pm_repos.ps1
# Arregla import errors en repos PM: crea app/__init__.py, app/main.py mínimo, tests y pytest en requirements.

$ErrorActionPreference = "Stop"

$repos = @(
  "pm-risk-register-vanilla",
  "pm-stakeholder-qa-langchain",
  "pm-backlog-prioritizer-langgraph",
  "pm-experiment-copilot-vanilla",
  "pm-prd-writer-crewai"
)

function Ensure-Dir($p) {
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}
function Write-UTF8NoBom([string]$Path, [string]$Content) {
  $dir = Split-Path -Parent $Path
  Ensure-Dir $dir
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

# conftest para añadir el root del proyecto al sys.path
$confTest = @'
import sys, os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
'@

# test de salud
$testHealth = @'
from fastapi.testclient import TestClient
from app.main import app

def test_health():
    c = TestClient(app)
    r = c.get("/health")
    assert r.status_code == 200
    assert r.json().get("ok") is True
'@

foreach ($r in $repos) {
  if (-not (Test-Path -LiteralPath $r)) {
    Write-Warning "Skipping (missing folder): $r"
    continue
  }

  $appDir   = Join-Path $r "app"
  $testsDir = Join-Path $r "tests"
  $reqPath  = Join-Path $r "requirements.txt"
  $initPath = Join-Path $appDir "__init__.py"
  $mainPath = Join-Path $appDir "main.py"
  $confPath = Join-Path $testsDir "conftest.py"
  $healthT  = Join-Path $testsDir "test_health.py"

  Ensure-Dir $appDir
  Ensure-Dir $testsDir

  if (-not (Test-Path -LiteralPath $initPath)) { Write-UTF8NoBom $initPath "" }

  if (-not (Test-Path -LiteralPath $mainPath)) {
    $main = @"
from fastapi import FastAPI

app = FastAPI(title="$r")

@app.get("/health")
def health():
    return {"ok": True, "repo": "$r"}
"@
    Write-UTF8NoBom $mainPath $main
  }

  if (-not (Test-Path -LiteralPath $confPath))   { Write-UTF8NoBom $confPath $confTest }
  if (-not (Test-Path -LiteralPath $healthT))    { Write-UTF8NoBom $healthT  $testHealth }

  # asegurar pytest en requirements
  if (Test-Path -LiteralPath $reqPath) {
    $raw = Get-Content -LiteralPath $reqPath -Raw
    if ($raw -notmatch "(?im)^\s*pytest\s*==") {
      Add-Content -LiteralPath $reqPath -Value "`npytest==8.3.2`n"
    }
  } else {
    Write-UTF8NoBom $reqPath "fastapi==0.115.0`nuvicorn==0.30.6`npytest==8.3.2`n"
  }
}

git add -A
$pending = git status --porcelain
if ($pending) {
  git commit -m "ci(pm): ensure minimal FastAPI app + tests + pytest for pm-* repos"
  git push
} else {
  Write-Host "Nada que commitear; ya estaba todo correcto." -ForegroundColor Green
}
