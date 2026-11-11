# Engineering Reflection: Week 8

## 1. Precision in Non-Technical Communication
When describing our automated rollback as "faster than a person could have responded" during the board script, there is a minor risk of overclaiming. While true in terms of reaction time, it glosses over the fact that an automated monitor can occasionally trigger a false-positive rollback if a transient network hiccup occurs before retry logic exhausts. To be more precise without losing a board member, one could state: "The system autonomously detected the anomaly and recovered normal operations in 13 seconds, eliminating the delay of human manual intervention."

## 2. Post-Incident Action Items and Confidence
The single highest-value action item identified is implementing strict parameter validation requiring an explicit environment flag in `deploy-app.sh`. We are highly confident that this prevents recurrence because it removes the possibility of executing default-fallback targets. To be 100% certain, we would need to inspect the script's argument parsing logic to ensure it fails closed (exiting with a non-zero code) whenever an environment parameter is missing or ambiguous.

## 3. Conceptual Continuity from VMs to Containers
Comparing the two approaches, the core concept of maintaining a healthy standby state carries forward, but the implementation changes dramatically. In the VM-based blue/green model, routing, state files (`.active-env`), systemd daemon management, and proxy reloading must be explicitly scripted. In the containerized Kubernetes world, these mechanisms become completely redundant because the orchestrator natively manages container networking, replica sets, health probes, and automatic load balancing.

## 4. Hardcoded Manifest Values and Operational Risk
Looking at `kk-payments-deployment.yaml`, the following values are hardcoded and create operational risks:
* **Registry URL (`localhost:5000/kk-payments`):** Prevents promoting the exact same immutable artifact to staging or production clusters that utilize different container registries.
* **`imagePullSecrets` Reference:** Couples the deployment to a specific cluster secret name, complicating multi-tenant or multi-cluster deployments when secret names rotate.
* **Container Port (`3001`):** Restricts flexibility if the underlying application framework changes its default listening port across environments.
