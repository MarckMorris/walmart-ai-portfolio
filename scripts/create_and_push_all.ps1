$ErrorActionPreference = "Stop"

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

foreach ($repo in $repos) {
  Write-Host "==> Processing $repo" -ForegroundColor Cyan
  Push-Location $repo
  try {
    if (-not (Test-Path ".git")) {
      git init -b main | Out-Null
    }

    git add . | Out-Null
    git commit -m "feat: initial scaffold" --allow-empty | Out-Null

    # ¿Existe el repo remoto?
    $exists = $false
    try {
      gh repo view "MarckMorris/$repo" 1>$null 2>$null
      if ($LASTEXITCODE -eq 0) { $exists = $true }
    } catch {
      $exists = $false
    }

    if (-not $exists) {
      gh repo create "MarckMorris/$repo" --public -y
    }

    # Forzar HTTPS para evitar líos con SSH
    try { git remote remove origin 2>$null } catch {}
    git remote add origin "https://github.com/MarckMorris/$repo.git"

    # Empujar main
    git push -u origin main
    Write-Host "✔ Pushed $repo" -ForegroundColor Green
  } catch {
    Write-Warning ("Failed on ${repo}: " + $_.Exception.Message)
  } finally {
    Pop-Location
  }
}
