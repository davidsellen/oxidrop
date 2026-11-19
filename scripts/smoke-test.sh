#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-http://127.0.0.1:8081}"
token="${INGEST_TEST_TOKEN:?Set INGEST_TEST_TOKEN to the local test token}"
payload='{"source":"smoke-test","readings":[12,15,14]}'

assert_status() {
  local expected="$1" actual
  shift

  actual=$(curl --silent --show-error --max-time 5 \
    --output /dev/null --write-out '%{http_code}' "$@")

  if [[ "$actual" != "$expected" ]]; then
    printf 'Expected HTTP %s, got %s\n' "$expected" "$actual" >&2
    return 1
  fi

  printf 'PASS: HTTP %s\n' "$actual"
}

assert_status 200 "$base_url/health"
assert_status 401 "$base_url/ingest" --json "$payload"
assert_status 200 "$base_url/ingest" --json "$payload" \
  --header "Authorization: Bearer $token"