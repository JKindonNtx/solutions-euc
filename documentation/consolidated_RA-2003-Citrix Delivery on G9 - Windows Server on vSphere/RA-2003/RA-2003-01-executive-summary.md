# Executive Summary

In this reference architecture, we make recommendations for designing, optimizing, and scaling Citrix Virtual Apps and Desktops and Citrix Desktop as a Service (DaaS) deployments on Windows Server on Nutanix with VMware vSphere and Citrix Machine Creation Services (MCS) or Citrix Provisioning (sometimes referred to as PVS). We used Login Enterprise (Login VSI) and an automated scripting framework on Nutanix to simulate real-world workloads in a Citrix environment.

In addition to desktop and application performance reliability, deploying Citrix Virtual Apps and Desktops and DaaS solutions on Nutanix provides unlimited scalability, data locality, shadow clones, and a single datastore. Nutanix takes the Citrix commitment to simplicity to another level with streamlined management, reduced rollout time, and lower operating expenses.

This document covers the following topics:

-  Overview of the Nutanix solution
-  Overview of Citrix Virtual Apps and Desktops and DaaS and their use cases
-  The benefits of running Citrix solutions on Nutanix
-  Design and configuration considerations for building a Citrix solution on VMware vSphere with Nutanix
-  Process for benchmarking Citrix performance on vSphere ESXi running on Nutanix NX-3155-G9 Hardware with Windows Server
-  Process for benchmarking Citrix MCS and Provisioning
-  The Impacts of Nutanix Files and Citrix Profile Management Containers when hosted on the workload cluster.

_Table: Document Version History_

| Version Number | Published | Notes |
| :---: | --- | --- |
| 1.0 | July 2024 | First publication. |