#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

case "${1:-what-if}" in
  what-if) action=what-if ;;
  deploy) action=create ;;
  *)
    echo "Usage: bash scripts/deploy-dev.sh [what-if|deploy]" >&2
    exit 2
    ;;
esac

if [[ -f .env ]]; then
  source ./.env
fi

if [[ -z "${OXIDROP_DEPLOY_TOKEN:-}" ]]; then
  echo "Set OXIDROP_DEPLOY_TOKEN in .env or export it before running this script." >&2
  exit 1
fi

export OXIDROP_DEPLOY_TOKEN

: "${OXIDROP_AZURE_SUBSCRIPTION:?Set OXIDROP_AZURE_SUBSCRIPTION in .env or export it before running this script.}"

deployment_args=(
  --subscription "$OXIDROP_AZURE_SUBSCRIPTION"
  --resource-group rg-oxidrop-dev
  --name oxidrop-app
  --parameters infra/dev.bicepparam
)

if [[ "$action" == create ]]; then
  app_host=$(az deployment group create "${deployment_args[@]}" \
    --query properties.outputs.appHost.value \
    --output tsv)

  if [[ -z "$app_host" ]]; then
    echo "Deployment completed, but the appHost output is empty." >&2
    exit 1
  fi

  printf 'Health URL: https://%s/health\n' "$app_host"
else
  az deployment group what-if "${deployment_args[@]}"
fi