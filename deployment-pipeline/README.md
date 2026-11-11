# KijaniKiosk Production Deployment Pipeline (Week 8)

This directory contains all code, manifests, and documentation for the Week 8 independent project, demonstrating both a traditional virtual machine blue/green zero-downtime deployment with automated rollbacks and a modern containerized Kubernetes delivery model[cite: 2, 3, 14, 15].

## Directory Structure

* **`bluegreen/`**: Contains artifacts for the VM-based blue/green deployment strategy[cite: 14, 15].
  * `switch-cycle.log`: Full timestamped log confirming a clean starting state and traffic switch to `v1.4.0`[cite: 5, 14].
  * `rollback-evidence.txt`: Proof of autonomous automated rollback triggered by the post-deploy monitor in under 90 seconds (measured at 13 seconds)[cite: 5, 6, 14].
  * `kk-payments-slo.md`: Service Level Objectives defining SLIs, targets, rollback thresholds, and exclusions[cite: 6, 7, 14].
  * `post-incident-review.md`: Six-section post-incident review analyzing the staging routing outage with concrete action items[cite: 7, 15].
  * `demo-script.md`: A 250-word, acronym-free script for the board presentation citing the exact measured rollback duration[cite: 7, 8, 15].
* **`containers/`**: Contains artifacts for the containerization and Kubernetes orchestration track[cite: 14, 15].
  * `Dockerfile.production`: Multi-stage Dockerfile producing a secure, 47MB image running as the `kijani` user with a health check[cite: 9, 15].
  * `.dockerignore`: Excludes non-essential files, tests, and secrets from the build context[cite: 9, 15].
  * `kk-payments-deployment.yaml`: Declarative Kubernetes Deployment manifest with multi-replica setup and resource boundaries[cite: 10, 15].
  * `kk-payments-service.yaml`: NodePort Service manifest routing traffic to running Pod endpoints[cite: 10, 15].
  * `build-verification.txt`: Cold-build proof verifying size constraints, non-root user execution, and absent compiler[cite: 9, 15].
  * `registry-push.txt`: Proof of dynamic version-SHA tagging, private registry push, and delete-then-pull verification[cite: 10, 15].
  * `deploy-output.txt` & `service-output.txt`: Cluster verification logs showing `2/2` Ready pods, endpoint bindings, and NodePort health responses[cite: 10, 11, 15].
  * `self-healing-rerun.txt`: Fresh deployment evidence demonstrating automated Pod self-healing in 34 seconds[cite: 10, 15].
* **`comparison.md`**: A 600–900 word architectural comparison detailing the trade-offs between VM blue/green and Kubernetes container deployments[cite: 11, 15].
* **`reflection.md`**: Engineering reflection addressing communication precision, post-incident action item confidence, conceptual continuity, and configuration management gaps[cite: 18].
