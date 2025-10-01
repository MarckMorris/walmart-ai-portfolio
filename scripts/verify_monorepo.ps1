# scripts/verify_monorepo.ps1
# Verifica estructura mínima de cada proyecto y que app/main.py defina "app"

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

$fail = @()

foreach ($r in $repos) {
  if (-not (Test-Path $r)) { 
    $fail += "$($r): MISSING_FOLDER"
    continue 
  }

  $req     = Test-Path "$r/requirements.txt"
  $main    = Test-Path "$r/app/main.py"
  $tests   = Test-Path "$r/tests/test_health.py"
  $testsDir= Test-Path "$r/tests"

  $appDefined = $false
  if ($main) {
    $t = Get-Content "$r/app/main.py" -Raw
    if ($t -match "(?ms)^\s*app\s*=") { $appDefined = $true }
  }

  if (-not $req)      { $fail += "$($r): missing requirements.txt" }
  if (-not $main)     { $fail += "$($r): missing app/main.py" }
  if (-not $appDefined){ $fail += "$($r): app not defined in app/main.py" }
  if (-not $tests)    { $fail += "$($r): missing tests/test_health.py" }
  if (-not $testsDir) { $fail += "$($r): missing tests/ directory" }
}

if ($fail.Count -eq 0) {
  Write-Host "OK: all projects look structurally sound." -ForegroundColor Green
  exit 0
} else {
  Write-Host "Issues found:" -ForegroundColor Yellow
  $fail | ForEach-Object { Write-Host " - $_" }
  exit 1
}
