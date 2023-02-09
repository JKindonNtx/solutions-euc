# Executive Summary

Because Nutanix AOS can withstand hardware failures and software glitches, it ensures that application availability and performance are never compromised.

![Nutanix Hybrid Multicloud Software Overview](../images/overview-hybrid-multicloud-software.png "Nutanix Hybrid Multicloud Software Overview")

In this tech note, we make recommendations for designing and protecting Citrix Virtual Apps and Desktops deployments running Windows workloads on Nutanix AHV with Citrix Machine Creation Services (MCS), Citrix Provisioning (PVS), and persistent VMs.

We take into consideration the supporting infrastructure surrounding and enabling the Citrix Virtual Apps and Desktops stack as well as the Citrix components. The Citrix solution depends on the ability to recover your network, Active Directory, file services, and backend application services.

## Citrix Virtual Apps and Desktops Disaster Recovery Scenario Assumptions

This document assumes the following:

- You're using Citrix Virtual Apps and Desktops 1912 LTSR or a later version with a single-site architecture.
- You have two datacenters with adequate compute to satisfy disaster recovery requirements.
- You're using Nutanix AHV as the hypervisor.
- You're using Nutanix Files for file services (including profiles, user data, and App Layers).
- You're using the relevant Nutanix Disaster Recovery features.
- You have adequate Citrix licensing for services such as Citrix NetScaler in case you need to start standby instances.

There are multiple strategies for providing business continuity and high availability with Citrix Virtual Apps and Desktops solutions. Citrix documents and details these techniques and capabilities for each product and provides more general recommendations in [TechZone documentation for disaster recovery planning](https://docs.citrix.com/en-us/tech-zone/design/design-decisions/cvad-disaster-recovery.html).

The following high-level conceptual diagram outlines the components that might exist in a Citrix Virtual Apps and Desktops site architecture. You might need to restore all of these components in a disaster recovery scenario.

![Citrix Virtual Apps and Desktops Site Architecture on Nutanix: Component Overview](../images/TN-2169-Disaster-Recovery-for-Citrix-Virtual-Apps-and-Desktops_image1.png "Citrix Virtual Apps and Desktops Site Architecture on Nutanix: Component Overview")