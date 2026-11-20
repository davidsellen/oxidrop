# Oxidrop operations runbook

## Deployment layout

Azure Container Apps pulls the image from GHCR. Bicep declares the development environment, its Container App, ingress, traffic weights, readiness probe and replica limits. The lab permits scale to zero. One observed first request after reaching zero replicas took 57.1 seconds. Requests made immediately afterward were much faster.

The GitHub Actions CI workflow runs on demand in the lab. Image publication and Azure deployment were performed from Fedora. See the [course project criteria](https://kursrum-devops.pages.dev/examinering/projektarbetet/) before submission. They describe a pipeline that calls scripts and a container image stored in an Azure registry.

## Deploy to development

1. Confirm Docker and Azure CLI access, and sign in to the intended Azure subscription.
2. Set `OXIDROP_AZURE_SUBSCRIPTION` and `OXIDROP_DEPLOY_TOKEN` in a local, ignored `.env`. Run `git check-ignore .env`. Keep the token out of Git and command output.
3. Build and publish the intended image tag. For the recorded release, that tag was `ghcr.io/davidsellen/oxidrop:0.1.2`. Confirm that the tag is available to Azure. Update the image reference and use a fresh revision suffix when the revision template changes.
4. From the repository root, preview the deployment:

   ```bash
   bash scripts/deploy-dev.sh
   ```

   Review the target subscription, resource group, image, probe and traffic rules. Resolve unexpected changes before continuing.
5. Apply the reviewed configuration:

   ```bash
   bash scripts/deploy-dev.sh deploy
   ```

6. Open the printed health URL and expect HTTP 200. On the revision being evaluated, verify that `/version` returns the intended tag value compiled into the binary. Send a valid JSON POST to `/ingest` with no token and expect 401. Repeat with a valid token and expect 200. Test the revision-specific URL when traffic is split so the stable revision cannot mask a failed check. Allow extra time for a cold start.

## Inspect revisions and logs

In the Azure portal, open the Oxidrop Container App and select **Revision management**. Review the revision name, health, traffic weight and replicas. Use **Log stream** and select the revision under investigation. Use system logs for startup and platform events, and console logs for application output. A revision scaled to zero may need a request before console logs are available. Use synthetic payloads when testing.

## Roll back traffic

1. Identify the last known good revision in **Revision management**.
2. In `infra/main.bicep`, under `configuration.ingress.traffic`, give that revision 100% by name and remove the canary entry.
3. Run the preview script. Confirm that the stable weight changes to 100 and that the canary entry is removed. Apply with the deploy command above.
4. Check the weights again, then verify `/health` and an authenticated POST to `/ingest` on the main URL.
5. If you changed traffic in the portal first, record the same routing in Bicep before the next deployment. Inspect the failing revision's logs before retrying a release.

## Lab evidence

Before rollback, 100 requests to `/version` on the shared URL returned 11 HTTP 200 responses and 89 HTTP 404 responses. The old revision did not have that route. The configured canary weight was 10%.

After rollback, the revision list showed:

```text
Revision                  Health    Traffic    Probe
oxidrop-dev--0000006      Healthy   100        /health
oxidrop-dev--v012         Healthy   0          /health
```

The learner subsequently reported completing promotion of `v012`. The table above captures the rollback checkpoint.

### GitHub Actions deployment and smoke test

The [GitHub Actions deployment](https://github.com/davidsellen/oxidrop/actions/runs/44746242532) applied the Bicep template to `rg-oxidrop-dev` and passed the post-deployment smoke test.

| Check | HTTP status |
| --- | --- |
| `GET /health` | `200` |
| `POST /ingest` without a token | `401` |
| `POST /ingest` with a valid token | `200` |

### Release 0.1.3 canary at 10%

The direct check of `oxidrop-dev--v013` returned version `0.1.3`. An authenticated JSON array sent to `/ingest` returned `payloadType: array`, `stamp: batch-landed`, and `status: received`.

With traffic configured at 90% for `v012-pinned` and 10% for `v013`, 30 requests to `/version` on the main app URL returned:

| Version | Configured weight | Responses | Observed share |
| --- | ---: | ---: | ---: |
| `0.1.2` | 90% | 25 | 83.3% |
| `0.1.3` | 10% | 5 | 16.7% |

Both revisions served requests in this sample. The observed share can differ from the configured weight in a small sample. This checkpoint was recorded before promotion to 100%.


## Test and promote a new revision

Run these commands from the repository root on Fedora. Keep 100% of the
main URL traffic on the stable revision while you test the new revision.

### Test the new revision directly

Set `revision` and `expected_version` for the release you are testing.
This example uses `oxidrop-dev--v013` and `0.1.3`.

```bash
(
  set -eo pipefail
  source ./.env

  revision='oxidrop-dev--v013'
  expected_version='0.1.3'

  host=$(az containerapp revision show \
    --subscription "$OXIDROP_AZURE_SUBSCRIPTION" \
    --resource-group rg-oxidrop-dev \
    --name oxidrop-dev \
    --revision "$revision" \
    --query properties.fqdn \
    --output tsv)
  test -n "$host"
  base_url="https://$host"

  # Allow time for the revision to start if it scaled to zero.
  curl -fsS --max-time 120 "$base_url/health"
  printf '\n'

  curl -fsS --max-time 120 "$base_url/version" |
    jq -e --arg version "$expected_version" '.version == $version'

  INGEST_TEST_TOKEN="${OXIDROP_DEPLOY_TOKEN:?Set the current Azure token in .env}" \
    bash scripts/smoke-test.sh "$base_url"
)
```

Expect `Healthy`, `true`, and HTTP statuses `200`, `401`, `200` from
the smoke test. Stop if any check fails. Use the revision URL so a
response from the stable revision cannot mask a failure.

For release `0.1.3`, also verify the new behavior. An authenticated
`POST /ingest` with `[{"temperature":-3}]` must return
`"payloadType":"array"` and `"stamp":"batch-landed"`.

### Route 10% to the new revision

1. In `infra/main.bicep`, under `configuration.ingress.traffic`, set the
   stable revision to weight `90` and the new revision to weight `10`.
   Use explicit revision names.
2. Run `bash scripts/deploy-dev.sh` and verify the proposed traffic change.
   Apply it with `bash scripts/deploy-dev.sh deploy`.
3. Check the applied weights in Azure **Revision management**. Call
   `/version` on the main app URL several times. Both release versions
   should appear over repeated requests. A small sample can differ from
   the configured 90/10 split.
4. Check the new revision's logs for failures. If the new revision fails
   a functional check, follow **Roll back traffic**.

### Promote to 100%

1. In the same Bicep traffic block, keep only the new revision and set
   its weight to `100`.
2. Preview and apply with the same commands.
3. Confirm the new revision has weight `100` in Azure. Run the smoke test
   against the **main app URL** and verify `/version` returns the new version.
4. Record the release version, image digest, revision name and test results
   in **Lab evidence**.