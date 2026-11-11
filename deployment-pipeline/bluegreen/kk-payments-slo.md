# Service Level Objectives (SLOs) for kk-payments

## 1. Service Level Indicators (SLIs)
* **Availability:** 
  * **Measurement Method:** Percentage of successful HTTP requests (returning status code `< 500`) over total requests.
  * **Data Source:** Nginx access logs (`/var/log/nginx/access.log`).
  * **Window:** Rolling 30-day window.
* **Latency:** 
  * **Measurement Method:** Percentage of payment requests completed in under 250 milliseconds.
  * **Data Source:** Application-level request duration metrics and proxy timing logs.
  * **Window:** Rolling 30-day window.
* **Payment Error Rate:** 
  * **Measurement Method:** Ratio of failed payment gateway transactions resulting in HTTP 5xx or unhandled transaction exceptions to total payment attempts.
  * **Data Source:** Application transaction error logs and gateway response codes.
  * **Window:** Rolling 30-day window.

## 2. SLO Targets (30-Day Window)
* **Availability SLO:** 99.9% successful requests.
* **Latency SLO:** 95% of requests served under 250ms.
* **Error Rate SLO:** Fewer than 0.1% unhandled payment errors.

## 3. Automated Rollback Threshold Table
| SLI | Short-Window Threshold (5-Minute Window) | Relationship to 30-Day SLO Target | Automated Action |
| :--- | :--- | :--- | :--- |
| **Availability** | < 98.0% success rate | Directly violates the 99.9% monthly uptime budget if sustained | Triggers immediate automated rollback |
| **Latency** | > 10% of requests exceeding 500ms | Signals performance degradation leading to timeout spikes | Triggers automated rollback |
| **Payment Error Rate** | > 1.0% transaction failure rate | Breaches the 0.1% reliability threshold by an order of magnitude | Triggers immediate automated rollback |

## 4. What We Do Not Commit To (Explicit Exclusions)
* **Client-Side Network Connectivity:** We explicitly exclude user-side internet packet loss, cellular carrier timeouts, and local Wi-Fi disruptions from our availability and latency calculations.
* **Third-Party Banking Downtime:** We do not commit to maintaining payment processing uptime during outages originating directly from external banking partners and mobile money gateways.
