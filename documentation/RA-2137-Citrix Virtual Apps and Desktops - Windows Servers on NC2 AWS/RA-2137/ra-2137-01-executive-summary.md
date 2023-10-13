# Executive Summary

Nutanix designed its software to give customers running workloads in a hybrid cloud environment the same experience they expect from on-premises Nutanix clusters. Because Nutanix in a hybrid multicloud environment runs AOS and AHV with the same CLI, UI, and APIs, existing IT processes and third-party integrations continue to work regardless of where they run.

![Overview of the Nutanix Hybrid Multicloud Software](../images/RA-2137_Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_NC2_AWS_image01.png "Overview of the Nutanix Hybrid Multicloud Software")

Nutanix AOS can withstand hardware failures and software glitches and ensures that application availability and performance are never compromised. Combining features like native rack awareness with public cloud partition placement groups, Nutanix operates freely in a dynamic hybrid multicloud environment.

In addition to desktop and application performance reliability, you get unlimited scalability, data locality, AHV clones, and a single datastore when you deploy Citrix Virtual Apps and Desktops on Nutanix. Nutanix takes the Citrix commitment to simplicity to another level with streamlined management, reduced rollout time, and lower operating expenses.

In this reference architecture, we make recommendations for designing, optimizing, and scaling Citrix Virtual Apps and Desktops (Citrix VAD) deployments on Windows VMs on Nutanix Cloud Clusters (NC2) on AWS with Citrix Machine Creation Services (MCS) and Citrix Provisioning (PVS). We used Login Virtual Session Indexer (Login VSI) and an intelligent scripting framework on Nutanix to simulate real-world workloads in a Citrix VAD environment. 