# Oxidrop

Oxidrop is a Rust HTTP service for a DevOps lab. It accepts JSON payloads of different shapes and acknowledges receipt. The current implementation discards the payload after processing.

| Endpoint | Purpose |
| --- | --- |
| `GET /health` | Check whether the process responds. Azure uses it as a readiness probe. |
| `GET /version` | Return the service name and the version compiled from Cargo.toml. Available from 0.1.2. |
| `POST /ingest` | Accept JSON with a valid Bearer token. Return 401 if the token is missing or invalid. |

## Run locally

From the repository root:

```bash
BIND_ADDRESS=127.0.0.1:8081 INGEST_TOKEN=local-test-only cargo run
```

In another terminal:

```bash
INGEST_TEST_TOKEN=local-test-only bash scripts/smoke-test.sh
curl -fsS http://127.0.0.1:8081/version
```

Use the disposable token only for local tests.

- [Operations runbook](docs/runbook.md)
- [Incident report](docs/incident-report.md)
- [Course project instructions](https://kursrum-devops.pages.dev/examinering/projektarbetet/)
