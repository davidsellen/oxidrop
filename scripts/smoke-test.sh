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

response_file=$(mktemp)
trap 'rm -f -- "$response_file"' EXIT

status=$(printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl --config - --silent --show-error --max-time 5 \
    --output "$response_file" --write-out '%{http_code}' \
    --json '[{"temperature":-3},{"temperature":-5}]' \
    "$base_url/ingest")

if [[ "$status" != 200 ]]; then
  printf 'Expected HTTP 200, got %s\n' "$status" >&2
  exit 1
fi

if ! jq -e '
  .status == "received" and
  .payloadType == "array" and
  .stamp == "batch-landed"
' "$response_file" > /dev/null; then
  echo "Expected an array receipt with stamp batch-landed." >&2
  exit 1
fi

echo "PASS: HTTP 200 with batch-landed stamp"