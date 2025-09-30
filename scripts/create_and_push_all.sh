#!/usr/bin/env bash
set -euo pipefail

REPOS=(
  retail-assortment-agent-langgraph
  retail-pricing-simulator-langchain
  retail-catalog-normalizer-crewai
  retail-replenishment-planner-langgraph
  retail-product-matching-rag-langchain
  retail-customer-inquiry-triage-fastapi
  retail-a11y-review-bot
  merch-vendor-scorecard-langgraph
  merch-planogram-helper-langchain
  merch-promo-optimizer-crewai
  merch-returns-analyzer-vanilla
  merch-forecast-comparator-langchain
  merch-content-enrichment-crewai
  merch-shelf-gap-detector-langgraph
  pm-okr-advisor-langchain
  pm-prd-writer-crewai
  pm-experiment-copilot-vanilla
  pm-backlog-prioritizer-langgraph
  pm-stakeholder-qa-langchain
  pm-risk-register-vanilla
)

for repo in "${REPOS[@]}"; do
  echo "==> Processing $repo"
  cd "$repo"
  git init -b main
  git add .
  git commit -m "feat: initial scaffold"
  gh repo create MarckMorris/"$repo" --public -y
  git remote add origin git@github.com:MarckMorris/"$repo".git
  git push -u origin main
  cd ..
done
