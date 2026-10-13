# KijaniKiosk CI Pipeline: Board-Ready Delivery

## Repository Contents
The following files and directories are included in this project submission to fulfill all deliverables:
* **`src/index.js`**: The main application source code.
* **`test/test.js`**: The unit test file.
* **`ci-pipeline-board-document.md`**: The plain-language pipeline explanation for the board presentation.
* **`credential-audit.txt`**: The output of the security checks ensuring no leaked credentials.
* **`fault-injection-log.md`**: The recorded downstream behaviors and design rationales for each faulted stage.
* **`green-pipeline-run.txt`**: The full console output of a successful sub-10-minute Jenkins build.
* **`Jenkinsfile`**: The Declarative Jenkins pipeline script.
* **`nexus-versions-screenshot-both.png`**: Visual evidence of multiple versioned artifacts in the Nexus registry.
* **`nexus-versions-screenshot.png`**: Visual evidence of the initial versioned artifact in the Nexus registry.
* **`package.json`**: The Node.js project configuration containing the pipeline execution scripts.
* **`README.md`**: This file, containing the repository overview, PR description, and engineering reflection.

---
## Pull Request Description (For Tendo)
This week, I built a production-grade CI pipeline using a Declarative Jenkinsfile that automatically lints, builds, verifies, and securely publishes a versioned Node.js artifact to a private Nexus registry. I am most confident in the fail-fast parallel verification stage, which strictly prevents vulnerable or failing code from wasting compute resources or entering the registry. As a next step, I would add an automated Continuous Deployment (CD) trigger to pull this verified artifact from Nexus and deploy it to a staging environment.

---

## Engineering Reflection

### 1. Requirement Tension & Resolution
A direct tension arose between the requirement to use a lightweight, pinned Docker agent (initially `node:18.19.0-alpine`) and the requirement to dynamically generate the `<semver>-<git-sha>` version string. The highly optimized Alpine image lacks the `git` binary required to execute `git rev-parse`. I resolved this by prioritizing the pipeline's functional need for precise Git traceability. I switched to the standard pinned `node:18.19.0` image, sacrificing a few megabytes of container size to ensure the versioning and artifact tracking requirements were executed flawlessly.

### 2. Contextual Communication Translation
**Original Board Document Sentence:**
> "Every time a software developer finishes a piece of work and saves it to our shared codebase, an automated process immediately takes over to check whether the change meets our quality standards before it is recorded as an approved version."

**Technical Rewrite (For Osei/Jenkinsfile Comments):**
> "The CI pipeline uses a Jenkins Multibranch configuration connected to GitHub, automatically triggering a Declarative Jenkinsfile execution on every push to execute static analysis, unit tests, and security audits prior to pushing the `.tgz` artifact to the Nexus registry."

**Analysis:** Both sentences describe the continuous integration trigger and the enforcement of quality gates. The board version focuses on human actions ("finishes a piece of work", "approved version") and business value. The technical version communicates the exact tooling, protocols, and file formats ("Multibranch configuration", "Declarative Jenkinsfile", "Nexus registry") needed to maintain the infrastructure.

### 3. System Scalability
If KijaniKiosk scales from four developers to forty, the single part of this week's pipeline that would break first is the local, host-mounted Docker daemon running the build agent and the Nexus registry on the same virtual machine. With dozens of concurrent commits, a single Jenkins node would quickly exhaust memory and CPU, leading to massively delayed build queues or crashed containers. To resolve this, we would need to migrate to a distributed infrastructure—utilizing Kubernetes or dedicated cloud instances to dynamically spin up independent Jenkins build agents, and migrating Nexus to a highly available, independent cluster.