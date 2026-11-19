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
