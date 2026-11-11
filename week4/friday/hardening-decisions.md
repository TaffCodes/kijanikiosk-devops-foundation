# KijaniKiosk Infrastructure Security Posture

## Executive Summary
This document outlines the security controls implemented in the automated deployment pipeline for the KijaniKiosk staging environment. As our infrastructure transitions from manual configuration to an automated, reproducible system, our security posture must scale accordingly. The deployment pipeline establishes a consistent baseline across our application tier, payment processing services, and logging aggregators. Our primary objective is to ensure that even if an application vulnerability is exploited, the underlying server environment contains the blast radius, preventing lateral movement and unauthorized data access.

To achieve this, we have adopted a defense-in-depth strategy that operates at both the cloud networking layer and the individual server operating system layer. At the cloud level, we control which traffic can reach our servers and how our infrastructure state is protected. At the server level, we strictly govern what our application services are permitted to do. The resulting architecture ensures that our services operate with the principle of least privilege, severely restricting their ability to interact with the broader system ecosystem.

## Core Security Controls and Mitigations

The following table details the specific security directives implemented across our cloud provisioning and server configuration layers. 

| Control | What it does | Risk mitigated |
| :--- | :--- | :--- |
| **Cloud Security Groups** | Restricts incoming network traffic to only required ports, blocking all other external connection attempts. | Prevents unauthorized external access to internal administrative interfaces and internal service ports. |
| **Remote State Storage** | Stores the infrastructure blueprint in a centralized, encrypted cloud bucket rather than on local engineer workstations. | Prevents accidental exposure of sensitive infrastructure data and ensures team synchronization. |
| **State Locking** | Prevents multiple automated or manual deployment pipelines from making conflicting changes simultaneously. | Eliminates the risk of infrastructure corruption caused by overlapping deployment runs. |
| **Dedicated Service Identities** | Runs each application under a unique, non-administrative system identity rather than a shared or privileged user account. | Ensures that a compromise in one service does not grant the attacker automatic access to other services. |
| **Strict File System Protection** | Renders the entire operating system and critical configuration directories completely read-only to the running applications. | Prevents attackers from modifying system binaries, planting malware, or altering core system configurations. |
| **Privilege Escalation Blocking** | Explicitly strips the ability for any running application process to elevate its own permissions, regardless of its initial state. | Mitigates the risk of an attacker using standard administrative exploits to gain full system control. |
| **Kernel Tunable Protection** | Blocks the application from modifying core operating system kernel parameters and network stack configurations. | Prevents sophisticated attackers from altering how the server processes network traffic or manages memory. |
| **Memory Execution Denial** | Prevents the application from creating memory segments that are both writable and executable simultaneously. | Severely limits the effectiveness of memory-based exploits and malicious code injection techniques. |

## Detailed Defense Strategy

Our approach to securing the KijaniKiosk environment focuses on isolation and containment. When we provision a new server, the automated pipeline applies a layered security model before the application even starts. 

First, we establish boundaries at the network level. Our cloud environment is configured to explicitly drop any connection attempt that does not target our intended public-facing endpoints. This means internal service ports used for health checks and database communication are completely invisible to the outside world. 

Second, we protect the deployment process itself. By moving our infrastructure state to a secure, remote cloud storage facility, we ensure that the blueprint of our network is not left scattered across various laptops. This centralized approach allows us to strictly control who can view or modify the architecture.

Third, we implement severe containment strategies within the server operating system. Applications inherently need to read files, write logs, and process data. However, they do not need to modify the operating system, change network rules, or access the personal files of other users. We have applied strict boundaries that mathematically prevent our applications from executing these unnecessary actions. The payment service, handling our most sensitive transactions, operates in a highly restricted sandbox. It cannot see the server's hardware devices, it cannot modify its own execution rules, and it cannot alter the core operating system behavior. If a malicious actor successfully exploits a flaw in the payment application code, they will find themselves trapped in an environment where they cannot install tools, modify system files, or pivot to the database.

## Acknowledged Gaps and Vulnerabilities

While this automated baseline significantly improves our security posture, it is not impenetrable. This configuration contains the blast radius of a compromised application, but it does not protect against vulnerabilities within the application code itself. If the API or Payment service contains logic flaws, SQL injection vulnerabilities, or insecure authentication mechanisms, an attacker can still exploit those flaws to manipulate application data. Furthermore, our current cloud network configuration allows secure administrative access from any external location. While protected by cryptographic keys, this broad administrative access window represents a risk. In a production environment, this administrative access must be restricted to a specific, trusted corporate network or accessed solely through a secure virtual private network. Finally, this pipeline relies on the security of the engineer's local credentials; compromised AWS credentials could bypass all implemented controls.
