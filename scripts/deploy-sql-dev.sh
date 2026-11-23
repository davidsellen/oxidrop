#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

case "${1:-what-if}" in
  what-if) action=what-if ;;
  deploy) action=create ;;
  *)
    echo "Usage: bash scripts/deploy-sql-dev.sh [what-if|deploy]" >&2
    exit 2
    ;;
esac

if [[ -f .env ]]; then
  source ./.env
fi

: "${OXIDROP_AZURE_SUBSCRIPTION:?Set OXIDROP_AZURE_SUBSCRIPTION in .env or export it before running this script.}"
: "${OXIDROP_SQL_ADMIN_PASSWORD:?Set OXIDROP_SQL_ADMIN_PASSWORD in .env or export it before running this script.}"
export OXIDROP_SQL_ADMIN_PASSWORD

if [[ ! -f infra/sql.bicepparam ]]; then
  echo "Missing infra/sql.bicepparam. Add the SQL deployment parameters before running this script." >&2
  exit 1
fi

scope_args=(
  --subscription "$OXIDROP_AZURE_SUBSCRIPTION"
  --resource-group rg-oxidrop-dev
)
deployment_args=(
  "${scope_args[@]}"
  --name oxidrop-sql
  --parameters infra/sql.bicepparam
)

if [[ "$action" == what-if ]]; then
  az deployment group what-if "${deployment_args[@]}"
  exit
fi

state=$(az deployment group create "${deployment_args[@]}" \
  --query properties.provisioningState --output tsv)
printf "SQL deployment state: %s\n" "$state"
[[ "$state" == Succeeded ]] || exit 1

az sql server firewall-rule list "${scope_args[@]}" \
  --server oxidrop-dev-sql-jnrumeetc75w2 \
  --query '[].{Rule:name,Start:startIpAddress,End:endIpAddress}' \
  --output table
