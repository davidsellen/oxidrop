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

az deployment group "$action" \
  --subscription e6010d5d-9573-4482-af10-46bb1978fc74 \
  --resource-group rg-oxidrop-dev \
  --name oxidrop-app \
  --parameters infra/dev.bicepparam