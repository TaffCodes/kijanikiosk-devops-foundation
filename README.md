# KijaniKiosk DevOps Foundation

## Overview
This repository serves as the foundational DevOps blueprint and architectural starter kit for the KijaniKiosk platform. Before scaling the application to real customers, this kit establishes the core engineering principles, security boundaries, and cloud infrastructure reasoning required for a resilient, production-ready system.

## Repository Structure

The core documentation is located within the `starter-kit/` directory:

*   **`delivery-notes.md`**: Outlines the DevOps workflow culture, emphasizing the principles of Flow (batch size reduction), Feedback (CI/CD shift-left), and Learning (blameless post-mortems).
*   **`cloud-model.md`**: Justifies the selection of a Platform as a Service (PaaS) architecture to abstract OS management and streamline deployment operations.
*   **`regions-azs.md`**: Details the geographic region selection (`af-south-1`) for latency reduction and the Multi-Availability Zone (Multi-AZ) strategy for fault tolerance.
*   **`iam-least-privilege.md`**: Defines a strict, resource-bound IAM policy for application-level S3 access, preventing lateral movement in the event of a breach.
*   **`network-topology.md` / `.png`**: Maps the Virtual Private Cloud (VPC) segmentation, isolating the database and application compute nodes in private subnets behind a public-facing load balancer and NAT gateway.

## Engineering Goals
1.  **Minimize Operational Overhead:** Leverage managed services (PaaS/Managed Databases) so the engineering team can focus on application logic rather than infrastructure maintenance.
2.  **Ensure High Availability:** Eliminate single points of failure through synchronous database replication and stateless compute nodes distributed across isolated data centers.
3.  **Enforce Default Security:** Apply the principle of least privilege natively to all service accounts and completely restrict inbound internet access to backend components.

## Credits
*   **AI Assistance:** The architectural reasoning, Markdown generation, and Git workflow strategies documented in this repository were developed collaboratively with an AI thought partner to accelerate delivery and ensure best-practice alignment.
