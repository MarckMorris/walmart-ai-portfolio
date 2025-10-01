# scripts/fix_imports.ps1  (puedes pegarlo directo en la consola también)

$ErrorActionPreference = "Stop"

$repos = @(
  "retail-pricing-simulator-langchain",
  "retail-catalog-normalizer-crewai",
  "retail-replenishment-planner-langgraph",
  "retail-product-matching-rag-langchain",
  "retail-customer-inquiry-triage-fastapi",
  "retail-a11y-review-bot",
  "retail-assortment-agent-langgraph",         # por si acaso
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

# conftest que mete el root del repo en sys.path (por si el env no cogiera PYTHONPATH)
$conftest = @'
import sys, os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
'@

function Ensure-File {
  param([string]$Path, [string]$ContentIfMissing = "")
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  if (-not (Test-Path -LiteralPath $Path)) {
    Set-Content -LiteralPath $Path -Value $ContentIfMissing -Encoding UTF8
  }
}

foreach ($r in $repos) {
  if (-not (Test-Path -LiteralPath $r)) { continue }

  # 1) app/__init__.py
  Ensure-File -Path (Join-Path $r "app\__init__.py") -ContentIfMissing ""

  # 2) tests/conftest.py
  Ensure-File -Path (Join-Path $r "tests\conftest.py") -ContentIfMissing $conftest

  # 3) requirements.txt (asegurar pytest)
  $req = Join-Path $r "requirements.txt"
  if (Test-Path -LiteralPath $req) {
    $raw = Get-Content -LiteralPath $req -Raw
    if ($raw -notmatch "(?im)^\s*pytest\s*==") {
      Add-Content -LiteralPath $req -Value "pytest==8.3.2"
    }
  } else {
    Set-Content -LiteralPath $req -Value "pytest==8.3.2" -Encoding UTF8
  }
}

git add -A
$pending = git status --porcelain
if ($pending) {
  git commit -m "ci(fix): add app/__init__.py + tests/conftest.py + ensure pytest for all repos"
  git push
} else {
  Write-Host "Nada que commitear: ya estaba todo bien." -ForegroundColor Green
}
