# Incident report — incorrect readiness path

**Status:** Draft for learner review  
**Type:** Planned lab simulation  
**Date:** 19 November 2026

## Summary and impact

A lab deployment changed the readiness path from `/health` to the intentionally nonexistent route `/not-ready-demo`. The exercise explored how Azure Container Apps handles a revision that cannot pass its readiness probe in Single mode. User impact and request failures during the simulation were not measured.

## Timeline

| Order | Event | Evidence |
| --- | --- | --- |
| 1 | Revision `0000004` was the starting revision. | Learner reported starting at revision 4. Later revision history showed `/health` for this revision. |
| 2 | A revision was deployed with the deliberately incorrect readiness path. | Later revision history showed `/not-ready-demo` on `0000005`. |
| 3 | The probe path was restored and the service was checked again. | Revision history showed `/health` on `0000006`. The Azure CLI showed Single mode and both Latest and Ready pointing to `0000006`. |

## Cause and evidence

The observed configuration difference was the readiness path. It targeted a route the application did not implement. The expected effect was an HTTP 404 on the probe. No probe failure log or live traffic capture from revision `0000005` is included in the available evidence. The later history displayed that revision as Healthy, so it does not establish the revision's health or traffic during the exercise.

## Recovery and prevention

- Restore the probe path to `/health` and verify that the latest revision becomes ready.
- Review the probe path and port in the deployment preview. Test the route with the same container image before releasing it.
- In a future drill, capture time-stamped revision status, the relevant Azure log entries and the HTTP response while the new revision is being evaluated.

## AI assistance

AI suggested changing the path for the simulation and predicted that the previous ready revision would retain traffic in Single mode. The learner verified the revision history and the final Latest and Ready values. The prediction about traffic during the failure was not verified. The learner should review this draft and add their own account of the logs, what they ruled out and any AI suggestions that proved incorrect before submission.
