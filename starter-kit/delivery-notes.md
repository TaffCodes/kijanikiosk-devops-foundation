# DevOps Delivery Notes: Flow, Feedback, and Learning

## 1. Flow (Optimizing Delivery Speed)
* **Implementation:** We enforce a strict Git branching strategy (`main`, `develop`, `feature/*`). 
* **Reasoning:** By isolating work into small, short-lived feature branches, we reduce the batch size of deployments. This prevents integration bottlenecks and merge conflicts, allowing code to move from a developer's local environment to production predictably and rapidly.

## 2. Feedback (Catching Errors Early)
* **Implementation:** Pull Requests (PRs) act as our primary feedback loop.
* **Reasoning:** Before any code reaches `develop`, it must pass peer review and (eventually) automated CI checks (linting, unit tests). This "shift-left" approach ensures that architectural flaws or bugs are caught when they are cheapest and fastest to fix, rather than after deployment.

## 3. Learning (Continuous Improvement)
* **Implementation:** Blameless post-mortems and iterative documentation (like this Starter Kit).
* **Reasoning:** When a deployment fails, the focus is placed on the system, not the individual. The resulting operational knowledge is captured in updated IAM policies, tighter network rules, or CI pipeline guardrails to ensure the same failure cannot recur.
