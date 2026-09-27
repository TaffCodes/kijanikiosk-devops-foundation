# Network Segmentation Topology

## Routing Logic
* **Public Subnet (DMZ):** Contains the Load Balancer and NAT Gateway. It has a direct route to the Internet Gateway (IGW), allowing inbound traffic from users.
* **Private Subnet:** Contains the application servers and database. It has NO route to the IGW. Application servers access the internet for outbound updates via the NAT Gateway in the public subnet. Inbound traffic only reaches the private subnet via the Load Balancer.

## Architecture Diagram (ASCII)

[ Internet ]
      │
      ▼
 ┌────────────────────────────────────────────────────────┐
 │ Virtual Private Cloud (VPC)                            │
 │                                                        │
 │  ┌──────────────────────────────────────────────────┐  │
 │  │ Public Subnet (Route to IGW)                     │  │
 │  │                                                  │  │
 │  │  [ Internet Gateway (IGW) ]                      │  │
 │  │             │                                    │  │
 │  │  [ Application Load Balancer ]   [ NAT Gateway ] │  │
 │  └─────────────┼──────────────────────────▲─────────┘  │
 │                │                          │            │
 │  ┌─────────────┼──────────────────────────┼─────────┐  │
 │  │ Private Subnet (No route to IGW)       │         │  │
 │  │             ▼                          │         │  │
 │  │     [ Web App Instance ] ──────────────┘         │  │
 │  │             │ (Outbound updates only)            │  │
 │  │             ▼                                    │  │
 │  │     [ Managed Database ]                         │  │
 │  └──────────────────────────────────────────────────┘  │
 └────────────────────────────────────────────────────────┘

## Mermaid JS Format (For PNG Generation)
```mermaid
graph TD
    Internet((Internet)) --> IGW[Internet Gateway]
    
    subgraph VPC [Virtual Private Cloud]
        IGW --> ALB
        
        subgraph Public_Subnet [Public Subnet - Internet Accessible]
            ALB[Application Load Balancer]
            NAT[NAT Gateway]
        end
        
        subgraph Private_Subnet [Private Subnet - Isolated]
            APP[Web App Instance]
            DB[(Managed Database)]
        end
        
        ALB -->|HTTP/HTTPS| APP
        APP -->|Outbound traffic| NAT
        APP -->|SQL queries| DB
    end
    
    NAT -.->|Routes to| IGW
