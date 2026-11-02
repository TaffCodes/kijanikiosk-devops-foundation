# Week 8 Reflection

## 1. Automation Challenges in CI/CD
If automating this sequence into a single CI/CD pipeline, the hardest step to make reliable would be the deployment verification step (waiting for self-healing and readiness). The primary failure mode concern is a "false positive" deployment: if the pipeline simply checks that a container is in a `Running` state but does not wait to verify deep health endpoints, the CI pipeline could report success while the application is actually stuck in an initialization crash-loop or failing to connect to the database.

## 2. Translating Prose to Technical Jargon
**Plain Prose:** "Through the implementation of multi-stage packaging routines, we now strictly separate the build environment from the runtime environment."
**Technical Rewrite:** "By implementing a multi-stage Dockerfile, we isolated the `node:18-alpine` builder stage containing the `devDependencies` and `tsc` compiler from the final lightweight runtime image layer."
**What is lost:** Accessibility for non-technical stakeholders (like the board), who will not understand what a `tsc` compiler or a runtime image layer is.
**What is gained:** Strict engineering precision that allows another developer to perfectly replicate the architecture without ambiguity.

## 3. Hardcoded Manifest Values vs. Week 9 Configuration Management
Looking at `kk-payments-deployment.yaml`, the following values are hardcoded and belong in ConfigMaps or Secrets:
- **`image: localhost:5000/kk-payments` (Registry URL):** Should be a ConfigMap. If hardcoded, we cannot seamlessly deploy the exact same manifest to both a staging cluster and a production cluster that use different container registries. 
- **`imagePullSecrets` credentials:** Must be a Secret. If the registry password rotates, we currently have to manually recreate the secret or update the manifest.
- **`containerPort: 3001`**: Should be a ConfigMap. Keeping environment configurations separate from application manifests allows true immutable deployments where the exact same artifact is promoted through environments simply by swapping the configuration file.
