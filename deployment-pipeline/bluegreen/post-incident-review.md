# Post-Incident Review: Staging Pipeline Targeting Error

## Section 1: Incident Summary
During a live investor demonstration, the deployment pipeline mistakenly executed against our staging environment instead of the isolated testing sandbox. This configuration discrepancy caused the proxy to serve uninitialized routes, resulting in exactly 48 seconds of staging unavailability before the automated monitoring system safely restored normal operations.

## Section 2: Timeline (Reconstructed)
* **14:10:00 UTC (Estimated):** Investor demonstration walkthrough begins.
* **14:12:15 UTC:** Deployment pipeline triggered by operating engineer.
* **14:12:30 UTC:** Pipeline incorrectly resolves staging environment endpoints due to a hardcoded configuration variable.
* **14:12:45 UTC:** Automated proxy health check detects consecutive HTTP 500 errors (`[MONITOR FAIL]`).
* **14:13:18 UTC:** Automated rollback script successfully reverts traffic to the previous stable release.
* **14:13:33 UTC:** Post-rollback proxy health check confirms normal service restored.

## Section 3: Root Cause Analysis (The 5 Whys)
1. *Why did the deployment target the wrong environment?* Because the deployment script defaulted to the staging environment file path when an explicit argument was omitted.
2. *Why did the script omit the required argument?* Because the deployment command was executed manually from a terminal history shortcut rather than through the parameterized CI pipeline.
3. *Why was a manual shortcut permitted for production workflows?* Because the CLI tool lacked strict input validation to enforce environment isolation flags.
4. *Why was input validation missing from the CLI tool?* Because previous iterations prioritized rapid script prototyping over robust environment boundary enforcement.
5. *Root Cause:* The absence of strict, schema-validated environment context checking in our deployment wrapper allowed ambiguous local execution parameters to propagate directly to live infrastructure.

## Section 4: Contributing Factors
* **High-Pressure Environment:** The live investor demonstration created cognitive tunnel vision, leading the engineer to rely on unverified command-line shortcuts.
* **Shared Configuration Files:** Both staging and production environments utilized overlapping configuration file templates within the local workspace.

## Section 5: What Went Well
* **Automated Resilience:** The post-deployment health monitor detected the failure within 15 seconds and executed an autonomous rollback without requiring human intervention, successfully limiting total customer impact.

## Section 6: Action Items
1. **Role:** Senior DevOps Engineer | **Description:** Implement strict parameter validation in `deploy-app.sh` requiring an explicit, non-default environment flag (`--env production|staging`) before execution. | **Target Timeframe:** 3 business days.
2. **Role:** Platform Security Lead | **Description:** Separate staging and production configuration repositories into isolated storage buckets with distinct access control credentials. | **Target Timeframe:** 5 business days.
3. **Role:** QA Lead | **Description:** Add automated integration tests that simulate misconfigured deployment targets in a dry-run CI pipeline. | **Target Timeframe:** 10 business days.
