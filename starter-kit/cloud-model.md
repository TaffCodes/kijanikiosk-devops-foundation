# Cloud Service Model Justification

## Selected Model: Platform as a Service (PaaS)

### Justification
For the KijaniKiosk web platform, we have selected a **PaaS** architecture (e.g., AWS Elastic Beanstalk, Google Cloud Run, or Azure App Service).

* **Operational Efficiency:** The engineering team is focused on delivering web application features, not managing Linux kernel updates or configuring Nginx reverse proxies. PaaS abstracts the underlying operating system and networking layers.
* **Automated Scaling:** PaaS environments automatically scale compute instances based on HTTP request volume or CPU utilization, handling traffic spikes seamlessly without manual intervention.
* **Trade-off Analysis:** While Infrastructure as a Service (IaaS) offers more granular control over server configurations, it introduces massive operational overhead (patching, securing, and maintaining host machines). Software as a Service (SaaS) is too restrictive for a custom-built proprietary platform. PaaS provides the perfect boundary: we manage the code and data; the cloud provider manages the runtime and hardware.
