# KijaniKiosk Production Security Posture & Foundation
**Prepared for: Nia (Director of Operations)**

## Executive Summary
As KijaniKiosk prepares to migrate our financial payment processing to a dedicated production environment, ensuring an ironclad security posture is paramount. The infrastructure powering this transition was built from the ground up using automated, repeatable code rather than manual configurations. This ensures that every server we deploy is identical, auditable, and inherently secure by default. 

This document outlines the proactive security controls applied to the payments infrastructure. Our methodology operates on the principle of least privilege: the system is actively denied access to anything it does not explicitly need to function. By stripping away default permissions, we drastically reduce the surface area available to malicious actors, ensuring that even if an application vulnerability is exploited, the underlying server and customer data remain protected.

## Core Security Decisions and Mitigations

The table below outlines the major security restrictions applied to the server environment. These controls operate invisibly beneath the application layer, ensuring rigorous protection without disrupting the customer experience.

| Control | What it does | Risk mitigated |
| :--- | :--- | :--- |
| **Strict File System Protection** | Locks down the server's core operating system files, making them completely read-only to the payment application. | Prevents attackers from permanently altering the server or installing malicious software if the application is compromised. |
| **Privilege Escalation Denial** | Explicitly blocks the application from attempting to gain administrative or "root" rights under any circumstances. | Stops an attacker who gains basic access from escalating their control to take over the entire server. |
| **Temporary Storage Isolation** | Creates a private, invisible temporary storage area exclusively for the payment service. | Prevents cross-application contamination and stops attackers from intercepting temporary data left behind by other system processes. |
| **User Directory Restriction** | Completely blocks the application from seeing or accessing employee and administrator user folders on the server. | Protects administrative passwords, keys, and personal configuration files from being stolen or manipulated. |
| **Memory Execution Locks** | Prevents the server's working memory from being simultaneously written to and executed as a program. | Neutralizes advanced cyberattacks that attempt to inject and run malicious code directly in the system's memory. |
| **Network Traffic Default Denial** | Drops all incoming network connections by default, explicitly allowing only essential web traffic and encrypted administrative access. | Shields internal services from the public internet and prevents unauthorized external scanning or exploitation. |
| **Operating System Capability Drops** | Removes advanced operating system permissions that are normally granted to default services, such as the ability to alter network routing. | Limits the blast radius of a breach by ensuring the compromised application cannot tamper with network traffic routing. |
| **System Call Filtering** | Restricts the application to a pre-approved list of safe operational commands, blocking dangerous or unusual system requests. | Prevents sophisticated exploits from leveraging obscure operating system features to bypass our primary security controls. |

## Automation and Consistency
Beyond specific security controls, the most significant risk reduction comes from our deployment methodology. Historically, servers were configured manually, which introduces human error, configuration drift, and undocumented "quick fixes" that compromise security over time. 

The new production foundation is entirely automated. The infrastructure configuration is treated as code. When a server is deployed, the automated sequence dynamically detects the current state of the machine, corrects any deviations, establishes the exact security permissions required, and performs a programmatic verification check before allowing the system to go live. If any security control fails to apply correctly, the deployment halts immediately rather than launching a vulnerable server.

Furthermore, we have implemented automated health checks and strict log retention policies. System events and access logs are continuously captured, compressed, and archived daily. This ensures that in the event of an anomaly, we have a complete, tamper-proof evidentiary trail to conduct forensic analysis.

## Honest Security Gaps (What This Does Not Cover)

While the foundational server infrastructure is highly secure, it is critical to acknowledge the boundaries of these protections to maintain an honest and accurate risk profile. 

First, these controls do not protect against application-level vulnerabilities. If there is a logical flaw in the payment processing code itself—such as a failure to validate a user's transaction amount or a vulnerability that allows SQL injection—the operating system controls detailed above cannot prevent it. Application security requires separate, dedicated code reviews and penetration testing.

Second, this posture does not currently address distributed denial-of-service disruptions. The server's firewall is designed to block unauthorized ports, but it is not equipped to filter massive floods of illegitimate traffic aimed at our open web ports. We rely on our upstream cloud providers for that level of traffic scrubbing.

Finally, while we have isolated the database credentials from the application codebase, this single-node foundation does not yet implement dynamic, rotating cryptographic secrets. Compromised credentials would still grant database access until manually revoked. Moving forward, integrating a dedicated secret management vault will be our next strategic security priority.
