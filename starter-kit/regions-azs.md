# Region Selection and Availability Zone Architecture

## Region Selection: af-south-1 (Cape Town)
* **Latency Reduction:** KijaniKiosk's primary user base is located in East Africa. Deploying infrastructure in the closest geographic region minimizes the physical distance data must travel, reducing Round-Trip Time (RTT) and ensuring a responsive web interface.
* **Data Sovereignty:** Keeping data within the African continent aligns with localized data protection compliance standards.

## Multi-Availability Zone (Multi-AZ) Reliability
* **Architecture:** The platform's application tier and database tier are distributed across two independent Availability Zones (e.g., `af-south-1a` and `af-south-1b`).
* **Failure Mitigation:** Availability Zones are physically isolated data centers with redundant power and networking. If AZ-A experiences a catastrophic power failure, the regional Load Balancer will automatically route all incoming user traffic to the healthy application instances in AZ-B.
* **State Management:** The primary database in AZ-A utilizes synchronous replication to a standby instance in AZ-B, ensuring zero data loss during a failover event.
