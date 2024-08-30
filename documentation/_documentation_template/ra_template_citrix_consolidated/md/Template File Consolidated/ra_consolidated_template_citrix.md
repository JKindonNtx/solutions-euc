# Executive Summary

Nutanix designed its software to give customers running workloads in a hybrid cloud environment the same experience that they expect from on-premises Nutanix clusters. Because Nutanix in a hybrid multicloud runs [Nutanix AOS](https://www.nutanix.com/products/nutanix-cloud-infrastructure/distributed-storage) and `Template: Validate_this` [Nutanix AHV](https://www.nutanix.com/products/ahv) with the same CLI, UI, and APIs, existing IT processes and third-party integrations continue to work regardless of where they run.

![The Nutanix Cloud Platform runs workloads both on-premises and in public cloud environments.](../images/overview-hybrid-multicloud-software.png "Overview of the Nutanix Hybrid Multicloud Software")

Nutanix AOS can withstand hardware failures and software glitches and ensures that application availability and performance are never compromised. By combining features like native rack awareness with public cloud partition placement groups, Nutanix operates freely in a dynamic hybrid multicloud environment.

In this reference architecture, we make recommendations for designing, optimizing, and scaling Citrix Virtual Apps and Desktops and Citrix Desktop as a Service (DaaS) deployments on Windows Server on Nutanix AHV with Citrix Machine Creation Services (MCS) and Citrix Provisioning (sometimes referred to as PVS). We used Login Enterprise (Login VSI) and an automated scripting framework on Nutanix to simulate real-world workloads in a Citrix environment.

In addition to desktop and application performance reliability, deploying Citrix Virtual Apps and Desktops and DaaS solutions on Nutanix provides unlimited scalability, data locality, AHV clones, and a single datastore. Nutanix takes the Citrix commitment to simplicity to another level with streamlined management, reduced rollout time, and lower operating expenses.

<!--TEMPLATE CONTENT: AHV or ESXi? AHV or Shadow Clones?-->

This document covers the following topics:

-  Overview of the Nutanix solution
-  Overview of Citrix Virtual Apps and Desktops and DaaS and their use cases
-  The benefits of running Citrix solutions on `Nutanix AHV`
-  Design and configuration considerations for building a Citrix solution on `Nutanix AHV`
-  `Process for benchmarking Citrix performance on Nutanix AHV running on AMD processors using Lenovo hardware with Windows Server`
-  `Process for benchmarking Citrix MCS and Provisioning`
-  `The effects of Nutanix Files and Citrix Profile Management Containers hosted on the workload cluster`

<!--TEMPLATE CONTENT: Validate Above. Is this a Windows Desktop or Windows Server RA-->

_Table: Document Version History_

| Version Number | Published | Notes |
| :---: | --- | --- |
| 1.0 | June 2024 | Example Single Document. |

# Citrix Desktop and Application Delivery Solution Overview

Citrix Virtual Apps and Desktops and Citrix Desktop as a Service (DaaS) are desktop virtualization solutions that transform desktops and applications into secure, on-demand services available to any user, anywhere, on any device. With Citrix solutions, you can deliver individual Windows, web, and software as a service (SaaS) applications and even full virtual desktops to PCs, Macs, tablets, smartphones, laptops, and thin clients with a high-definition user experience.

Both solutions provide a complete virtual desktop and application delivery system by integrating several distributed components with advanced configuration tools that simplify the creation and real-time management of the virtual desktop infrastructure (VDI).

Both solutions deliver the same capability, with differing components and considerations: 

The following are the core components of a Citrix Delivery Solution.

Delivery Controller
: The Delivery Controller authenticates users, manages the assembly of users' virtual desktop environments, and brokers connections between users and their virtual desktops. It's installed on servers in the datacenter and controls the state of the desktops, starting and stopping them based on demand and administrative configuration. In some editions, the Citrix license needed to run Citrix Virtual Apps and Desktops also includes profile management to manage user personalization settings in virtualized or physical Windows environments. In a Citrix DaaS deployment, Citrix hosts the Delivery Controller.

Cloud Connector
: The Cloud Connector runs on servers in the datacenter and serves as a communication channel between Citrix DaaS and the datacenter. It enables authentication by allowing you to use Active Directory forests and domains, supports Citrix DaaS resource publishing, and facilitates machine catalog provisioning while removing the need to manage Citrix DaaS delivery infrastructure components such as Delivery Controllers, SQL Server, Director, StoreFront, Licensing, and Citrix Gateway. Cloud Connectors are only used in Citrix DaaS deployments.

Studio
: Citrix Studio is the management console that allows you to configure and manage your Citrix DaaS environment. It provides different wizard-based deployment or configuration scenarios to publish resources using desktops or applications.

Machine Creation Services (MCS)
: Machine Creation Services is the building mechanism of the Citrix Delivery Controller that automates and orchestrates desktop deployment using a single image. MCS communicates with the orchestration layer of your hypervisor, providing a robust and flexible method of image management.

Provisioning
: Citrix Provisioning creates and provisions virtual desktops from a single desktop image on demand, optimizing storage utilization and providing a pristine virtual desktop to each user every time they log on. Desktop provisioning also simplifies desktop images, provides optimal flexibility, and offers fewer points of desktop management for both applications and desktops.

Virtual Delivery Agent (VDA)
: The Virtual Delivery Agent is installed on virtual desktops and enables direct FlexCast Management Architecture (FMA) connections between the virtual desktop and user devices.

Workspace app
: The Citrix Workspace app, installed on user devices, enables direct HDX connections from user devices to applications and desktops using Citrix DaaS. The Citrix Workspace app allows access to published resources from your desktop, Start menu, web browser, or Citrix Workspace app.

FlexCast
: Citrix DaaS with FlexCast delivers virtual desktops and applications tailored to meet the diverse performance, security, and flexibility requirements of every worker in your organization. Centralized, single-instance management helps you deploy, manage, and secure user desktops more easily and efficiently.

StoreFront
: StoreFront is an enterprise app store that aggregates applications and desktops from Citrix Virtual Apps and Desktops sites and Citrix DaaS into a single store for users to access published resources.

NetScaler
: NetScaler provides application delivery and secure remote access for applications published by Citrix Virtual Apps and Desktops and Citrix DaaS. NetScaler provides gateway capabilities for remote access and load-balancing capabilities for service resiliency.

For more detailed information about these components, as well as best practices for running them on Nutanix, see the following guides:

-  [Citrix Virtual Apps and Desktops on Nutanix best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2079-Citrix-Virtual-Apps-and-Desktops:BP-2079-Citrix-Virtual-Apps-and-Desktops)
-  [Citrix DaaS on Nutanix best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2062-Citrix-Virtual-Apps-and-Desktops-Service:BP-2062-Citrix-Virtual-Apps-and-Desktops-Service)

## Provisioning Software Development Kit

The Citrix Provisioning Software Development Kit (SDK) applies the power and flexibility of Citrix-provisioned VMs to any hypervisor or cloud infrastructure service that you choose.

The SDK enables you to create your own Provisioning plug-in, which you can add to the plug-ins installed by default by the Citrix installer. Once you install your plug-in, the Delivery Controller services discover and load it automatically. It then appears as a new connection type in Citrix Studio or Citrix Web Studio, allowing you to easily connect, configure, and provision on your chosen infrastructure platform using two key features:

- A set of .NET programming interfaces that are used to call your Provisioning plug-in whenever it needs to act. Your plug-in takes the form of a .NET assembly (DLL) that implements these interfaces. A plug-in must implement several .NET interfaces, but each is designed to be small and easy to understand. Most interfaces have both a synchronous and an asynchronous variant, allowing you to choose the programming pattern that works best.
- The Citrix Common Capability Framework, which provides information to the product about the specific custom features of your infrastructure and how to display those features in Citrix Studio. The framework uses a high-level XML-based description language. Your plug-in uses this language to produce specifications that allow Citrix Studio to intelligently adapt its task flows and wizard pages.

The plug-in made with the Citrix Provisioning SDK allows you to create the connection between Citrix Studio and AHV and gives you access to all the APIs offered through AHV. However, before you can use it, you must install the Nutanix AHV plug-in for Citrix on Delivery Controllers for Citrix Virtual Apps and Desktops or Cloud Connectors for Citrix DaaS. For more information, see [AHV Plug-in for Citrix](https://portal.nutanix.com/page/documents/details?targetId=NTNX-AHV-Plugin-Citrix:NTNX-AHV-Plugin-Citrix) (Nutanix portal credentials required).

<!--TEMPLATE CONTENT: AHV or ESXi? No need for the SDK for vSphere environments-->

# Citrix Desktop Delivery Solutions on Nutanix

The Nutanix modular web-scale architecture lets you start small and expand to meet increasing demand—a node, a block, or multiple blocks at a time—with no impact on performance. This design removes the hurdle of a large initial infrastructure purchase, decreasing the time to value for your Citrix implementation. Running Citrix desktop delivery solutions on Nutanix enables you to run multiple workloads, all on the same scalable converged infrastructure, while achieving these benefits:

Modular incremental scale
: With the Nutanix solution, you can start small and scale up. A single Nutanix block provides dozens of terabytes of storage and hundreds to thousands of virtual desktops in a compact footprint. With this modular solution, you can granularly scale by node, by block, or with multiple blocks, accurately matching supply with demand and minimizing upfront capital expenditure.

High performance
: By using system memory caching for read I/O and flash storage for read and write I/O, you can deliver high-performance throughput in a compact form factor. 

Change management
: Maintain environmental control and separation between development, test, staging, and production environments. Snapshots and fast clones can help share production data with nonproduction jobs without requiring full copies and unnecessary data duplication.

Business continuity and data protection
: User data and desktop are mission-critical and need enterprise-grade data management features, including backup and disaster recovery. 

Data efficiency
: Nutanix storage offers compression and deduplication to reduce your storage footprint. The compression functionality is truly VM-centric: Unlike traditional solutions that perform compression mainly at the LUN level, the Nutanix solution provides all these capabilities at the VM and file levels, greatly increasing efficiency and simplicity. These capabilities ensure the highest possible compression and decompression performance, even below the block level.

Enterprise-grade cluster management
: Nutanix offers a simplified and intuitive approach to managing large clusters, including a converged user interface that serves as a central point for servers and storage, alert notifications, and the bonjour mechanism that automatically detects new nodes in the cluster. As a result, you can spend time enhancing your environment rather than maintaining it.

High-density architecture
: Nutanix uses an advanced server architecture coupled with data archiving and compression that can make your desktop hardware footprint five times smaller.

Time-sliced clusters
: Like public cloud environments, Nutanix can provide a truly converged cloud infrastructure, allowing you to run your server and desktop virtualization on a single cloud. Gain the efficiency and savings you require with a converged cloud on a unified architecture.

## Citrix Desktop Delivery Solutions on Nutanix AHV

<!--TEMPLATE CONTENT: Validate Above - AHV or vSphere?-->

The following figure shows the main architectural components of the Citrix Virtual Apps and Desktops on Nutanix solution and the communication path between services. The user accesses resources presented to them from the Delivery Controllers via Citrix StoreFront, which can either be load-balanced or gateway-proxied by a NetScaler. Workloads that the user accesses can be provisioned by Citrix MCS or Citrix Provisioning. This reference architecture hosts workloads on `VMware vSphere` running on Nutanix NX-3155-G9 nodes.

<!--TEMPLATE CONTENT: Validate Above - AHV or vSphere?-->

![Communication path between Citrix Virtual Apps and Desktops and Nutanix components](../images/communication-path.png "Citrix Virtual Apps and Desktops Communication Path and Components")

The following figure shows the main architectural components of the Citrix DaaS on Nutanix solution and the communication path between services. The user accesses resources presented to them by Citrix DaaS via Citrix StoreFront, which can either be load-balanced or gateway-proxied by a NetScaler. Workloads that the user accesses can be provisioned by Citrix MCS or Citrix Provisioning. In a Citrix DaaS deployment, the Cloud Connectors replace the Delivery Controller component for resource enumeration by StoreFront. Citrix offers a cloud-native solution called Workspace which incorporates some functions of StoreFront. This reference architecture uses Citrix StoreFront and hosts workloads on `VMware vSphere` running on Nutanix NX-3155-G9 nodes.

<!--TEMPLATE CONTENT: Validate Above - AHV or vSphere?-->

![Communication path between Citrix Desktop as a Service and Nutanix components](../images/citrix-daas-overview.png "Citrix DaaS Communication Path and Components")

## Pod Design

The following tables contain highlights from a high-level snapshot of the Citrix solution on a Nutanix virtual desktop pod.

_Table: Control Pod Details_

| Solution Deployment Type | Component | Quantity |
| :--- | :--- | :---: |
| Citrix Virtual Apps and Desktops | Delivery Controllers | 2 |
| Citrix DaaS | Cloud Connectors | 2 |
| Citrix Common | StoreFront servers | 2 |
| Citrix Common | Provisioning servers | 2 |
| Citrix Common | NetScaler | 2 |

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Services Pod Details_

| Item | Quantity |
| --- | :---: |
| AHV hosts | 16 | 
| Nutanix clusters | 1 |
| Containers | 1 |

<!--TEMPLATE CONTENT: Validate Above. AHV or ESX RA?-->

Limiting the cluster size to 16 nodes reduces the failure domain and the time to patch and update the clusters. This reference architecture uses 16-node building blocks to take advantage of `single-rack design`, smaller failure domains, and reduced time to patch and update. 

<!--TEMPLATE CONTENT: Validate Above-->

We validated the Citrix solution with pod design sizing based on the Login Enterprise knowledge worker workload. A more resource-intensive workload results in a lower density, and a less resource-intensive workload results in a higher density. If you change the vCPU count or memory, the number of VDAs per node and per cluster changes as well.

The following table shows the configuration details and results for the pod-based testing and the associated projected cluster densities.

_Table: Windows Server 2022 Configuration Details_

| Item | Value |
| --- | :---: |
| Windows Server 2022 configuration | `TBD` vCPU and 42 GB of memory |
| VMs per node | `TBD` |
| Users per VM | `TBD` |
| VMs in a 6-node cluster (baseline testing) | `TBD` |
| User sessions in a 6-node cluster (baseline testing) | `TBD` |
| VMs in a 16-node cluster with n + 1 resilience | `TBD` |
| User sessions in a 16-node cluster with n + 1 resilience | `TBD` |

<!--TEMPLATE CONTENT: Validate Above. Is this a Windows Desktop or Windows Server RA-->

_Table: Windows 11 Configuration Details_

| Item | Value |
| --- | :---: |
| Windows 11 configuration | 3 vCPU and 6 GB of memory |
| VMs per node | `TBD` |
| VMs in a 8-node cluster (baseline testing) | `TBD` |
| VMs in a 16-node cluster with n + 1 resilience | `TBD` |

<!--TEMPLATE CONTENT: Validate Above. Is this a Windows Desktop or Windows Server RA-->

_Table: Windows 10 Configuration Details_

| Item | Value |
| --- | :---: |
| Windows 10 configuration | 2 vCPU and 4 GB of memory |
| VMs per node | `TBD` |
| VMs in a 8-node cluster (baseline testing) | `TBD` |
| VMs in a 16-node cluster with n + 1 resilience | `TBD` |

<!--TEMPLATE CONTENT: Validate Above. Is this a Windows Desktop or Windows Server RA-->

## Nutanix Compute and Storage

Nutanix provides an ideal combination of high-performance compute resources and localized storage to meet any demand. True to this capability, this reference architecture contains no reconfiguration or customization of the Nutanix product to optimize for this use case. The following figure shows a high-level example of the relationship between the Nutanix storage pool and containers, where a single storage pool can host multiple containers with different configurations.

![You can seamlessly add containers to a Nutanix storage pool and have it grow dynamically.](../images/nutanix-logical-storage-configuration.png "Nutanix Storage Overview")

The following table details the Nutanix storage pool and container configuration.

_Table: Nutanix Storage Configuration_

| Name | Role | Details |
| --- | --- | --- |
| SP01 | Main storage pool for all data | `SSD` or `NVMe` |
| VDI | Container for all VMs | `AHV` datastore |
| Default-Container | Container for all data (not used here) | `AHV` datastore |

<!--TEMPLATE CONTENT: Validate Above. Is this an AHV or ESX RA?-->

## Nutanix Files

[Nutanix Files](https://www.nutanix.com/products/files) is a software-defined, scale-out file storage solution that provides a repository for unstructured data, such as home directories, user profiles, departmental shares, application logs, backups, and archives. You can deploy Nutanix Files on an existing or standalone cluster. Unlike standalone NAS appliances, Nutanix Files consolidates VM and file storage so that you don't need to create an infrastructure silo.

Administrators can use Nutanix Prism to manage Nutanix Files, just like VM services, which unifies and simplifies management. Integration with Active Directory enables support for quotas, access-based enumeration (ABE), and self-service restores with the Windows Previous Versions feature. Nutanix Files also supports native remote replication and file server cloning, so you can back up Files off-site and run antivirus scans and machine learning without affecting production.

Nutanix Files can run on a dedicated cluster or a cluster running user VMs. Nutanix supports Files with both ESXi and AHV. Files includes native high availability and uses Nutanix storage for intracluster data resilience and data efficiency techniques such as erasure coding.

Nutanix Files includes File Analytics, which gives you a variety of useful insights into your data, including full audit trails, anomaly detection, ransomware detection and intelligence, data age analytics, and custom reporting. You can also use Nutanix Data Lens for deeper insights and ransomware protection for your Nutanix Files environment. Data Lens provides analytics and ransomware defense at scale for Nutanix Unified Storage.

_Table: Nutanix Files Configuration Overview_

| Item | Value |
| --- | :---: |
| Nutanix Files version | `5.0.0.1` |
| Nutanix Files deployment location | `Workload cluster` |
| File server VM (FSVM) count | 3 |
| FSVM specifications | `4` vCPU and `16` GB of memory |
| Share count | 1 |
| Share type | Distributed |
| Continuous availability enabled | Yes |

<!--TEMPLATE CONTENT: Validate Above. Is Files used in this RA-->

# Citrix Delivery on AMD Solution Design

<!--TEMPLATE CONTENT: Validate Above-->

The following tables describe the design decisions and rationale for Citrix deployments on Nutanix.

_Table: Platform Design Decisions: Nutanix Common_

| Design Area | Item | Detail | Rationale |
| --- | --- | --- | --- |
| General | Software versions | Citrix DaaS; Citrix Virtual Apps and Desktops 2402; Citrix Provisioning 2402; AOS 6.5.5.1 `Template: Validate_this` | — |
| General | Minimum size | 3 Nutanix nodes running `Template: AHV` | Minimum size requirement |
| General | Scale approach | Incremental modular scale | Allows growth from proof of concept (tens of servers) to massive scale (hundreds of servers) `Template: Validate_this` |
| General | Scale unit | Nodes, blocks, or pods | Granular scale to precisely meet capacity demands; scale in n × node increments |
| Nutanix AHV `Template: Validate_this` | Cluster size | As many as 16 hosts (minimum of 3 hosts) | Isolated fault domains (best practice) |
| Nutanix AHV `Template: Validate_this` | Datastores | 1 Nutanix storage datastore per pod (Workload VMs, VM clones, and so on) | Nutanix handles I/O distribution and localization; n-Controller model |
| Nutanix AHV `Template: Validate_this` | Infrastructure services | Small deployments: Shared cluster; Large deployments: Dedicated cluster | Dedicated infrastructure cluster for larger deployments (best practice) |
| VMware vSphere `Template: Validate_this` | Software Versions | VMware ESXi 7.0.3 and VMware vCenter Server 7.0.3.01200 | — | 
| VMware vSphere `Template: Validate_this` | Cluster size | Up to 16 vSphere hosts (minimum of 3 hosts) | Isolated fault domains (best practice) |
| VMware vSphere `Template: Validate_this` | Datastores | 1 Nutanix storage datastore per pod (workload VMs, VM clones, and so on) | Nutanix handles I/O distribution and localization; n-Controller model |
| VMware vSphere `Template: Validate_this` | Infrastructure services | Small deployments: Shared cluster; Large deployments: Dedicated cluster | Dedicated infrastructure cluster for larger deployments (best practice) |
| Nutanix | Cluster size | As many as 16 nodes | Isolated fault domains (best practice) |
| Nutanix | Storage pools | 1 storage pool per cluster | Standard practice; intelligent tiering handles data locality |
| Nutanix | Containers | 1 container for VMs | Standard practice |
| Nutanix | Features and enhancements | Increase CVM memory to 24–32+ GB. Turn on deduplication and compression for persistent desktops. Turn on compression only for nonpersistent desktops. We set the CVM to `32` GB for the reference architecture. | Best practice |
| Nutanix Files `Template: Validate_this` | Deployment location | Workload cluster | SMB file services for Citrix Profile Management Containers hosted locally to the workloads |
| Nutanix Files `Template: Validate_this` | FSVM configuration | 3 × FSVM, 4 vCPU, 16 GiB of memory per FSVM | Recommended size for FSVM configuration for this workload |
| Nutanix Files `Template: Validate_this` | FSVM placement | DRS placed per VMWare vCenter recommendations | No preference on FSVM location on a workload cluster when load is evenly spread |

<!--TEMPLATE CONTENT: Validate Above. Is this RA using Files?-->
<!--TEMPLATE CONTENT: Validate Above. Is this an AHV or ESX RA-->
<!--TEMPLATE CONTENT: Validate Above. CVM configuration might be larger due to NVMe-->

The following components are specific to Citrix Virtual Apps and Desktops.

_Table: Platform Design Decisions: Citrix Virtual Apps and Desktops_

| Item | Detail | Rationale |
| --- | --- | --- |
| Delivery Controllers | Minimum: 2 (n + 1); Scale: 1 per additional pod | High availability for Delivery Controllers |
| Users per controller | Up to 5,000 users | Citrix Virtual Apps and Desktops best practice |
| Load balancing | Built into Delivery Controllers | Ensures availability of Delivery Controllers; balances load between Delivery Controllers |
| Virtual hardware specs | vCPU: 4; Memory: 4+ GB (Local Host Cache); Disk: 60 GB vDisk | Standard sizing practice |
| Desktop management | Nutanix AHV plug-in desktop management | Allows deployment and management `Template: Validate_this` |
| Desktop management | Integration with VMware vCenter Server | Allows deployment and management `Template: Validate_this` |
<!--TEMPLATE CONTENT: Validate Above - some components not relevant for ESXi such as AHV Plugin-->

The following components are specific to Citrix DaaS.

_Table: Platform Design Decisions: Citrix DaaS_

| Item | Detail | Rationale |
| --- | --- | --- |
| Cloud Connectors | Minimum: 2 (n + 1); Scale: 1 per additional pod | High availability for Cloud Connectors |
| Users per Resource Location | Up to 10,000 VDAs with up to 25,000 total sessions | Citrix DaaS limits |
| Load balancing | Built into Cloud Connectors | Ensures availability of Cloud Connectors; balances load between Cloud Connectors |
| Virtual hardware specs | vCPU: 4; Memory: 4+ GB (local host cache); Disk: 60 GB vDisk | Standard sizing practice |
| Desktop management | Nutanix AHV plug-in desktop management | For deployment and management `Template: Validate_this` |
| Desktop management | Integration with VMware vCenter Server | Allows deployment and management `Template: Validate_this` |

<!--TEMPLATE CONTENT: Validate Above - some components not relevant for ESXi such as AHV Plugin-->

The following components are relevant to both Citrix Virtual Apps and Desktops, along with Citrix DaaS:

_Table: Platform Design Decisions: Citrix Common Components_

| Design Area | Item | Detail | Rationale |
| --- | --- | --- | --- |
| Citrix Provisioning | Provisioning servers | Minimum: 2 (n + 1); Scale: 2 per additional pod | High availability for Provisioning Services |
| Citrix Provisioning | Load balancing | Built into Provisioning servers | Balances load between Provisioning servers |
| Citrix Provisioning | Virtual hardware specs | vCPU: 8; Memory: 12+ GB (number of vDisks); Disk: 60 GB vDisk | Standard sizing practice |
| Citrix Provisioning | vDisk store | Dedicated disk on Nutanix or Nutanix Files shared vDisk Store | Standard practice |
| Citrix Provisioning | Write cache | Cache on Device RAM with overflow on hard disk (set vDisk cache size to 0) | Best practice for Citrix Provisioning with Nutanix |
| Citrix StoreFront | StoreFront servers | Minimum: 2 (n + 1) | High availability for StoreFront servers |
| Citrix StoreFront | Load balancing | Citrix NetScaler (including Citrix NetScaler VPX) | Ensures availability of StoreFront servers; balances load between StoreFront servers | 
| Citrix StoreFront | Virtual hardware specs | vCPU: 2+; Memory: 4+ GB; Disk: 60 GB vDisk | Standard sizing practice |
| Citrix NetScaler | NetScaler virtual appliances | Minimum: 2 | High availability for NetScaler (active-passive) |
| Citrix NetScaler | Users per NetScaler virtual appliance | See [product data sheet](https://www.citrix.com/products/citrix-adc/platforms.html) | Varies per model |
| Citrix NetScaler | Load balancing | NetScaler high availability | Ensures availability of NetScaler virtual appliances; balances load between Delivery services and pods | 

<note>Not all Citrix DaaS deployments require components such as Citrix Provisioning, Citrix StoreFront, or Citrix NetScaler.</note>

_Table: Infrastructure Design Decisions_

| Design Area | Item | Detail | Rationale |
| --- | --- | --- | --- |
| Active Directory | Global catalog and DNS servers | Minimum: 2 (n + 1) per site | High availability for global catalog and DNS; Microsoft best practice |
| DHCP | DHCP servers | Nutanix IPAM | High availability for Nutanix IPAM is built in `Template: Validate_this` |
| DHCP | Load balancing | Built-in | Ensures availability of DHCP `Template: Validate_this` |
| DHCP | DHCP servers | Windows or third-party DHCP services | High availability depends on chosen solution `Template: Validate_this: good for ESXi` |
| SQL Server | SQL Servers | Minimum: 2 (n + 1) per site; Scale: 2 per additional pod | High availability for SQL Servers |
| SQL Server | Data protection | SQL Server clustering, mirroring, or Always On availability groups (including basic availability groups) | Ensures availability of SQL Server instances |

<note>Not all Citrix DaaS deployments require SQL Server, but some, such as Citrix Provisioning, do.</note>

You should consult the [Microsoft SQL Server on Nutanix](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2015-Microsoft-SQL-Server:BP-2015-Microsoft-SQL-Server) best practices guide when deploying Microsoft SQL.

<!--TEMPLATE CONTENT: Validate Above - some components not relevant for ESXi, such as IPAM-->

## Virtual Delivery Agent Optimizations

We generated our design with the following high-level Virtual Delivery Agent (VDA) optimization guidelines in mind:

- Size desktops appropriately for each use case.
- Disable unnecessary OS services and applications.
- Redirect home directories or use a profile management tool for user profiles and documents.

For more information on desktop optimizations, see the [Citrix Windows 10 Optimization Guide](https://support.citrix.com/article/CTX216252), [End-User Computing Performance Benchmarking best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2161-EUC-Performance-Benchmarking:BP-2161-EUC-Performance-Benchmarking), and [Citrix Optimizer article](https://support.citrix.com/article/CTX224676).

# Validation and Benchmarking for Citrix Delivery Solutions on AMD

<!--TEMPLATE CONTENT: Validate Above-->

The following sections describe the benchmarking method and test environment we used in this reference architecture.

## Login Enterprise

[Login VSI](http://www.loginvsi.com/) provides performance insights for virtualized desktop and server environments. Enterprise IT departments use Login VSI products in all phases of VDI operations management—from planning to deployment to change management—for more predictable performance, higher availability, and a more consistent user experience. Login Enterprise comes with two built-in workloads: The [task worker](https://support.loginvsi.com/hc/en-us/articles/6949195003932-Task-Worker-Out-of-the-box) and [knowledge worker](https://support.loginvsi.com/hc/en-us/articles/6949191203740-Knowledge-Worker-Out-of-the-box). Neither workload is comparable to the workloads included in the previous edition of Login VSI.

The following table includes both workloads available in Login Enterprise.

_Table: Login Enterprise Workloads_

| Task Worker | Knowledge Worker |
| --- | --- |
| Light | Medium |
| 2 vCPU | 2–4 vCPU |
| 2–3 apps | 4–6 apps |
| No video | 720p video |

### Login Enterprise Test Phases

A Login Enterprise benchmark test has three phases: the boot phase, the logon phase, and the steady state. During the boot phase, we measure the time it takes to start all the VMs. Then we have a 30-minute wait time to ensure that all VMs are idle when the logon phase starts. We set the logon phase to 48 minutes, which means that all the sessions that we configured to logon do so evenly paced over 48 minutes. After a session logs on, the workload starts launching applications and performs application-specific actions such as opening, editing, and saving files. After the last session starts, the steady state begins. The steady state represents the time after all users are logged on and the system begins to normalize. In our tests, we set the steady state to 20 minutes. These 20 minutes simulate the EUC workload and typical user experience during a normal workday.

### Login Enterprise EUX Score

According to [Login Enterprise documentation](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-), the End User Experience (EUX) Score represents the performance of any Windows machine (virtual, physical, cloud, or on-premises). The score ranges from 0 to 10 and measures the experience of one to many users. Expect your EUX Score to drop as you add users to your VDI. More users demand a greater share of a VDI system’s shared resources, so performance and user experience decrease.

The default EUX measurements significantly affect the performance, especially CPU and storage. With the default measurements, the workload profile doesn't represent an EUC workload, so we modified the EUX measurements to ensure that the workload has an impact on CPU and storage that correlates to an EUC workload. You can find these modifications in the appendix. Instead of comparing EUX scores, we look at the user experience metrics, like logon times and application response times, and compare the CPU load on the cluster.

### Login Enterprise Metrics

A good user experience is defined by short logon times, short application start times, and consistency. EUC benchmark tests show you when the user experience is no longer consistent. The longer the experience is consistent, the better the result.

We quantified the evaluation using the following metrics:

-  Average logon time
-  Logon phase application metrics: The average response times of application actions
-  Steady-state application response times 
-  Maximum CPU usage 
-  CPU usage during steady state (ideally less than 85 percent)

## Test Environment

In this section, we describe the hardware we used for this reference architecture.

### Management Infrastructure Cluster

We used one Nutanix NX-3060-G7 cluster with four nodes to host all infrastructure and Citrix services and the Login Enterprise appliance. Active Directory services, DNS, DHCP, and the SQL Server also ran inside this cluster, which we call the management infrastructure cluster. With four nodes we had enough resources available to host these servers. The following table shows the Citrix configuration.

_Table: Citrix Configuration: Virtual Apps and Desktops_

| VM | Quantity | vCPU | Memory | Disks |
| --- | :---: | :---: | :---: | :--- |
| Delivery Controllers | 2 | 4 | 8 GB | 1 × 60 GB (OS) |
| Provisioning servers | 2 | 8 | 16 GB | 1 × 60 GB (OS) + 1 × 150 GB (Provisioning Store) |
| StoreFront | 2 | 2 | 4 GB | 1 × 60 GB (OS) |
| SQL | 1 | 4 | 8 GB | 3 × 60 GB (OS, DATA, logs) |
| NetScalers | 2 | 8 | 16 | 20 GB |

_Table: Citrix Configuration: DaaS_

| VM | Quantity | vCPU | Memory | Disks |
| --- | :---: | :---: | :---: | :--- |
| Cloud Connectors | 2 | 4 | 8 GB | 1 × 60 GB (OS) |
| Provisioning servers | 2 | 8 | 16 GB | 1 × 60 GB (OS) + 1 × 150 GB (Provisioning Store) |
| StoreFront | 2 | 2 | 4 GB | 1 × 60 GB (OS) |
| SQL | 1 | 4 | 8 GB | 3 × 60 GB (OS, DATA, logs) |
| NetScalers | 2 | 8 | 16 | 20 GB |

### Login Enterprise Launcher Cluster

To initiate the sessions to the virtual desktops, Login Enterprise uses launcher VMs. Depending on the display protocol used, one launcher VM can host up to 25 sessions. For this reference architecture, we used one Nutanix NX-3155G-G8 cluster with four nodes to host 75 launcher VMs. Each launcher VM had 4 vCPU and 6 GB of memory.

<!--TEMPLATE CONTENT: Validate Above-->

### Virtual Desktop Cluster

We used six Lenovo ThinkAgile HX665 V3 CN nodes in a cluster to host all the session hosts. The next tables contain the specifications of this cluster.

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Virtual Desktop Cluster Specifications_

| Parameter | Setting |
| --- | --- |
| Block type | Lenovo ThinkAgile HX665 V3 CN |
| Number of blocks | 6 |
| Number of nodes | 6 |
| CPU type | AMD EPYC 9274F 24-core processor |
| Number of CPUs per node | 2 |
| Number of cores per CPU | 24 |
| Memory per node | 1.5 TB |
| Disk config per node | 6 × 1.2 TB SSD |
| Network | 2 × 25 GbE |

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Nutanix Software Specifications_

| Parameter | Setting | 
| --- | --- |
| Nutanix AOS version | 6.5.5.1 LTS |
| Hypervisor version | 20220304.478 |
| CVM vCPU | 12 |
| CVM memory | 32 GB |
| Redundancy factor | 2 |
| Number of datastores for desktop VMs | 1 |
| Compression | On |
| Compression delay | 0 |
| Deduplication | Off |

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Citrix Software Specifications_ 

| Parameter | Setting |
| --- | --- |
| Citrix VDA version | 7.2402 |
| Provisioning version | 7.2402 |

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Windows Server 2022 Template Image Configuration (MCS)_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows Server 2022 21H2 (x64) (21H2-20348.2031) |
| Windows updates | 04/15/24 |
| CPU | 8 vCPU |
| Memory | 42 GB |
| NICs | 1 |
| Virtual network adapter | Nutanix VirtIO Adapter |
| Virtual SCSI controller 0 | Nutanix VirtIO SCSI passthrough |
| Virtual disk | 80 GB |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Windows Server 2022 Template Image Configuration (Provisioning)_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows Server 2022 21H2 (x64) (21H2-20348.2031) |
| Windows updates | 04/15/24 |
| CPU | 8 vCPU |
| Memory | 42 GB |
| NICs | 1 |
| Virtual network adapter | Nutanix VirtIO Adapter |
| Virtual SCSI controller 0 | Nutanix VirtIO SCSI passthrough |
| Virtual disk | 40 GB (Cache) |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Citrix Provisioning target device | 7.41.100.62 (2402 LTSR) |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |

<!--TEMPLATE CONTENT: Validate Above-->

<!--TEMPLATE CONTENT: Validate Above. Is this a Desktop or Server RA.--> 

_Table: Windows 11 Template Image Configuration (MCS)_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows 11 23H2 (x64) (23H2-22631.2428) |
| Windows updates | 06/04/24 |
| CPU | 3 vCPU |
| Memory | 6 GB |
| NICs | 1 |
| Virtual network adapter | VMXNET 3 |
| Virtual SCSI controller 0 | LSI Logic SAS |
| Virtual disk | 60 GB |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |

<!--TEMPLATE CONTENT: Validate Above. Is this a Desktop or Server RA.--> 

_Table: Windows 11 Template Image Configuration (Provisioning)_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows Server 2022 21H2 (x64) (23H2-22631.2428) |
| Windows updates | 06/01/24 |
| CPU | 3 vCPU |
| Memory | 6 GB |
| NICs | 1 |
| Virtual network adapter | VMXNET 3 |
| Virtual SCSI controller 0 | LSI Logic SAS |
| Virtual disk | 60 GB (Cache) |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Citrix Provisioning target device | 7.41.100.62 (2402 LTSR) |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |

<!--TEMPLATE CONTENT: Validate Above. Is this a Desktop or Server RA.--> 

_Table: Windows 10 Template Image Configuration (MCS)_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows 10 22H2 (x64) (22H2-19045.3570) |
| Windows updates | 06/04/24 |
| CPU | 2 vCPU |
| Memory | 4 GB |
| NICs | 1 |
| Virtual network adapter | VMXNET 3 |
| Virtual SCSI controller 0 | LSI Logic SAS |
| Virtual disk | 60 GB |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |

<!--TEMPLATE CONTENT: Validate Above. Is this a Desktop or Server RA.--> 

### Nutanix Files

We deployed Nutanix Files to support the user profile repository for Citrix Profile Management Containers and tested a single file server configuration on the workload cluster.

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Nutanix Files Configuration_

| Parameter | Setting |
| --- | --- |
| Platform | `VMware ESXi` |
| Version | 5.0.0.1 | 
| FSVM count | 3 |
| FSVM size | 4 vCPU, 16 GiB of memory | 
| Share type | Distributed |
| Share settings: Continuous availability | Enabled |
| Share settings: Access-based enumeration | Disabled | 
| Share settings: SMB encryption | Disabled |

<!--TEMPLATE CONTENT: Validate Above-->

# Citrix Delivery Solutions on Nutanix Test Validation

This section provides the details and results of our Citrix delivery solutions performance tests on Lenovo ThinkAgile HX665 V3 CN nodes with Nutanix AHV. We ran each test scenario at least three times to ensure accuracy.

<!--TEMPLATE CONTENT: Validate Above-->

## Test Objectives

Our overall objective was to determine the session capacity that we could host on Nutanix using a Windows VDA image and running the Login Enterprise tests with Citrix delivery solutions. We tested with the Login Enterprise knowledge worker profile.

Objectives:

-  Determine the maximum number of sessions that we can host on this system with the Login Enterprise knowledge worker workload while maintaining a good user experience.
-  Show the linear scalability of the Nutanix platform.
-  Show how much power (in watts) the Nutanix platform uses.
-  Show the differences between Citrix MCS and Citrix Provisioning on the Nutanix platform.

Testing parameters:

-  We used Citrix MCS and Provisioning to deploy the Windows VMs to validate linear scalability.
-  We tested using a single, full HD screen with the default Citrix frames per second configuration. Using multiple screens or other screen resolution settings affects the results.
-  `Template: Validate_this` We used Citrix Profile Management Container–based profiles for our testing. We deployed a simple configuration with minimal baseline changes.

In the following section, we display information associated with the testing we completed. The following table describes the test naming convention used and displayed in the graphs.

_Table: Test Name Matrix for `Knowledge Worker Profile on Windows Server 2022 on vSphere`_

| Test Name | Provisioning Method | Nodes | AOS Version| VMs | Users | Information |
| --- | --- | --- | --- | --- | --- | --- |
| ws2022_amd_mcs_1n_A6.5.5_AHV_10V_180U_KW | Citrix MCS | 1 | 6.5.5 | 10 | 180 | Testing was completed on AMD processors `Template: Validate_this` |
| ws2022_amd_mcs_2n_A6.5.5_AHV_20V_360U_KW | Citrix MCS | 2 | 6.5.5 | 20 | 360 | Testing was completed on AMD processors `Template: Validate_this` |
| ws2022_amd_mcs_4n_A6.5.5_AHV_40V_720U_KW | Citrix MCS | 4 | 6.5.5 | 40 | 720 | Testing was completed on AMD processors `Template: Validate_this` |
| ws2022_amd_mcs_6n_A6.5.5_AHV_60V_1080U_KW | Citrix MCS | 6 | 6.5.5 | 60 | 1080 | Testing was completed on AMD processors `Template: Validate_this` |
| ws2022_amd_pvs_6n_A6.5.5_AHV_60V_1080U_KW | Citrix Provisioning | 6 | 6.5.5 | 60 | 1080 | Testing was completed on AMD processors `Template: Validate_this` |

<!--TEMPLATE CONTENT: Validate Above-->

## Boot Storm Simulation

We used the following hosting connection settings for our boot storm simulation test:

- Simultaneous actions (absolute): 100
- Simultaneous actions (percentage): 20 percent
- Max new actions per minute (absolute): 50

We started 60 Windows Server session hosts on six Lenovo ThinkAgile HX665 V3 CN nodes. The following table shows the performance results of these tests.
<!--TEMPLATE CONTENT: Validate Above-->
_Table: Boot Storm Simulation: Six-Node MCS Test_

| Measurement | Detail |
| --- | --- |
| Maximum CPU usage | `TBD`% |
| Average CPU usage | `TBD`% |
| Average controller IOPS | `TBD` |
| Boot time | `TBD` min. |

<!--TEMPLATE CONTENT: Validate Above-->

### Linear Scalability in the Logon Phase

The following table and graph detail the user experience during the logon phase of the test. A lower result represents better performance.

_Table: Linear Scalability in the Logon Phase: Logon Time Averages_

| Metric | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: | 
| Average logon time | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| User profile load | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Group policies | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Connection | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 

<!--TEMPLATE CONTENT: Validate Above-->

![Logon times for one, two, four, and six nodes with 10 Windows Server 2022 VMs each](../images/RA-TBD-login_times_total_logon_time_WS22_Lin.png "Linear Scalability Total Logon Times")

<!--TEMPLATE CONTENT: Validate Above-->

The following tables show the linear scalability of application performance over the test runs. A lower result represents better performance.

_Table: Linear Scalability in the Logon Phase: App Start Times_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: |
| Microsoft Outlook | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Word | `TBD` sec | `TBD` sec | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec | `TBD` sec | `TBD` sec | 

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Linear Scalability in the Logon Phase: Specific Action Times_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: |
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 

<!--TEMPLATE CONTENT: Validate Above-->

### Linear Scalability in the Steady State

The following tables show the user experience during the steady state of the test. A lower result represents better performance.

_Table: Linear Scalability Steady State Phase: App Start Times_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: |
| Microsoft Word | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Excel | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft PowerPoint | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Application Performance Linear Scale Steady State Phase: Specific Action Times_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: |
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec |

<!--TEMPLATE CONTENT: Validate Above--> 

## Single-Node Host Resources

The following table and graphs show a single node's host resource usage during the test (logon and steady-state phases). We tested with 180 users per VM and 10 VMs on the node.

<!--TEMPLATE CONTENT: Validate Above--> 

*Table: Single Node Host Resource Usage Metrics*
| Metric | Max | Average |
| --- | :---: | :---: |
| Host CPU usage | `TBD`% | `TBD`% |
| Host memory usage | `TBD`% | `TBD`% |
| Host power usage | `TBD` W | `TBD` W |

<!--TEMPLATE CONTENT: Validate Above--> 

![CPU usage as a percentage peaked at 81.7 during the full test for a single Lenovo ThinkAgile HX665 V3 CN node](../images/RA-TBD-host_resources_cpu_usage_WS22_sn.png "Single-Node Host CPU Usage") 

<!--TEMPLATE CONTENT: Validate Above--> 

![Memory usage as a percentage peaked at 31.5 during the full test for a single Lenovo ThinkAgile HX665 V3 CN node](../images/RA-TBD-host_resources_memory_usage_WS22_sn.png "Single-Node Host Memory Usage") 

<!--TEMPLATE CONTENT: Validate Above--> 

![Power consumption in watts peaked at 777 during the full test for a single Lenovo ThinkAgile HX665 V3 CN node](../images/RA-TBD-host_resources_power_usage_WS22_sn.png "Host Resources Power Usage in Watts during the full test run")

<!--TEMPLATE CONTENT: Validate Above--> 

## Citrix Machine Creation Services vs. Provisioning

This section compares the Login Enterprise test results for using either Citrix MCS or Provisioning to deploy Windows Server 2022 workloads.

<!--TEMPLATE CONTENT: Validate Above--> 

### MCS vs. Provisioning System Performance

The following table provides the averages for the overall system performance results. For an explanation of CPU ready time, see [Nutanix KB 5012: Interpreting CPU Ready Values](https://portal.nutanix.com/kb/5012).

_Table: System Performance MCS vs. Provisioning: System Performance Metric Averages_

| Metric | MCS | Provisioning |
| --- | :---: | :---: | 
| CPU usage | `TBD`% | `TBD`% |
| CPU ready time | `TBD`% | `TBD`% |
| Controller read IOPS | `TBD` | `TBD` | 
| Controller write IOPS | `TBD` | `TBD` | 
| Controller latency | < `TBD` ms | < `TBD` ms | 

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU usage for the six-node cluster peaked at 59.1 percent (MCS-deployed) and 58.8 percent (Provisioning-deployed).](../images/RA-TBD-cluster_resources_cpu_usage_WS22_MCS_PVS.png "MCS vs. Provisioning: CPU Usage")

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU ready times for the six-node cluster peaked at 0.979 percent (MCS-deployed) and 1.17 percent (Provisioning-deployed).](../images/RA-TBD-cluster_resources_cpu_ready_WS22_MCS_PVS.png "MCS vs. Provisioning: CPU Ready Times")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller read IOPS for the six-node cluster peaked at just over 9,600 IOPS (MCS-deployed) and just over 5,600 IOPS (Provisioning-deployed).](../images/RA-TBD-cluster_resources_controller_read_iops_WS22_MCS_PVS.png "MCS vs. Provisioning: Controller Read IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller write IOPS for the six-node cluster peaked at just over 15,000 IOPS (MCS-deployed) and almost 25,000 IOPS (Provisioning-deployed).](../images/RA-TBD-cluster_resources_controller_write_iops_WS22_MCS_PVS.png "MCS vs. Provisioning: Controller Write IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

We saw the following maximum latencies during our testing.

_Table: MCS vs. Provisioning: Cluster Controller Latencies_

| Metric | MCS | Provisioning |
| --- | :---: | :---: |
| Overall controller latency | `TBD` ms | < `TBD` ms |
| Controller write I/O latency | `TBD` ms | < `TBD` ms |
| Controller read I/O latency | `TBD` ms | < `TBD` ms |

<!--TEMPLATE CONTENT: Validate Above--> 

![Controller I/O latency trends for one MCS-deployed and one Provisioning-deployed six-node cluster](../images/RA-TBD-cluster_resources_controller_latency_WS22_MCS_PVS.png "MCS vs. Provisioning: Controller I/O Latency")

<!--TEMPLATE CONTENT: Validate Above--> 

![Controller I/O latency trends for one MCS-deployed and one Provisioning-deployed six-node cluster](../images/RA-TBD-cluster_resources_controller_latency_WS22_MCS_PVS.png "MCS vs. Provisioning: Controller I/O Latency")

<!--TEMPLATE CONTENT: Validate Above--> 

### MCS vs. Provisioning Logon Phase

The following table and figure show the average logon times across the test runs. A lower result represents better performance.

_Table: MCS vs. Provisioning Logon Phase: Logon Time Averages_

| Metric | MCS | Provisioning |
| --- | :---: | :---: | 
| Average logon time | `TBD` sec | `TBD` sec |
| User profile load | `TBD` sec | `TBD` sec | 
| Group policies | `TBD` sec | `TBD` sec |
| Connection | `TBD` sec | `TBD` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

![Overall logon times for the six-node cluster peaked at 11.4 seconds (MCS-deployed) and 13.8 seconds (Provisioning-deployed).](../images/RA-TBD-login_times_total_logon_time_WS22_MCS_PVS.png "MCS vs. Provisioning: Logon Times")

<!--TEMPLATE CONTENT: Validate Above--> 

The following tables show application performance details during the logon phase of the test. A lower result represents better performance.

_Table: MCS vs. Provisioning Logon Phase: App Start Times_

| Application | MCS | Provisioning | 
| --- | :---: | :---: |  
| Microsoft Outlook | `TBD` sec | `TBD` sec |
| Microsoft Word | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: MCS vs. Provisioning Logon Phase: Specific Action Times_

| Application (Action) | MCS | Provisioning | 
| --- | :---: | :---: |
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec |
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec |
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

### MCS vs. Provisioning Steady State

The following tables show application performance details during the steady state of the test. A lower result represents better performance.

_Table: MCS vs. Provisioning Steady State: App Start Times_

| Application | MCS | Provisioning | 
| --- | :---: | :---: |  
| Microsoft Word | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: MCS vs. Provisioning Steady State: Specific Action Times_

| Application (Action) | MCS | Provisioning | 
| --- | :---: | :---: |  
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec |
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec |
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

## Windows 10 vs. Windows 11

<!--TEMPLATE CONTENT: Validate Above. Is this a Desktop or Server RA. Delete if Server--> 

This section compares the Login Enterprise comparison test results for an eight-node cluster running Windows 10 and Windows 11. We kept Windows 10 to the same specification that we have previously used in Nutanix Reference Architectures.

<!--TEMPLATE CONTENT: Validate Above--> 

### Windows 10 vs. Windows 11 System Performance

The following table shows the averages for the overall system performance results.

_Table: Windows 10 vs. Windows 11: System Performance Metric Averages_

| Metric | Windows 10 | Windows 11 |
| --- | :---: | :---: | 
| CPU usage | `TBC`% | `TBC`% |
| CPU ready time | `TBC`% | `TBC`% | 
| Controller read IOPS | `TBC` | `TBC` | 
| Controller write IOPS | `TBC` | `TBC` | 
| Controller latency | < `TBC` ms | < `TBC` ms | 

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU usage for the eight-node cluster peaked at 90.4 percent (Windows 10) and 87.2 percent (Windows 11). Windows 11 showed higher CPU usage during the boot phase than Windows 10, and lower CPU usage during the steady-state phase.](../images/RA-TBD-cluster_resources_cpu_usage_W10_v_W11.png "Windows 10 vs. Windows 11: CPU Usage") 

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU ready times for the eight-node cluster peaked at 1.16 percent (Windows 10) and 3.76 percent (Windows 11).](../images/RA-2022-cluster_resources_cpu_ready_W10_v_W11.png "Windows 10 vs. Windows 11: CPU Ready Time")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller read IOPS for the eight-node clusters peaked at 17,789 IOPS (Windows 10) and 18,592 IOPS (Windows 11).](../images/RA-2022-cluster_resources_controller_read_iops_W10_v_W11.png "Windows 10 vs. Windows 11: Controller Read IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller write IOPS for the eight-node clusters peaked at nearly 18,000 IOPS (Windows 10) and 20,000 IOPS (Windows 11).](../images/RA-2022-cluster_resources_controller_write_iops_W10_v_W11.png "Windows 10 vs. Windows 11: Controller Write IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Windows 10 vs. Windows 11: Maximum Cluster Controller Latencies_

| Metric | Windows 10 | Windows 11 |
| --- | :---: | :---: |
| Overall controller I/O latency | `TBC` ms | `TBC` ms |
| Controller write I/O latency | `TBC` ms | `TBC` ms |
| Controller read I/O latency | `TBC` ms | `TBC` ms |

![Controller latency trends for one eight-node cluster running Windows 10 and one running Windows 11. Windows 11 showed slightly higher latency figures when compared with Windows 10.](../images/RA-2022-cluster_resources_controller_latency_W10_v_W11.png "Windows 10 vs. Windows 11: Controller Latency")

<!--TEMPLATE CONTENT: Validate Above--> 

### Windows 10 vs. Windows 11 Logon Phase

The following table and figure show the average logon times during the logon phase of the test. A lower result represents better performance.

_Table: Windows 10 vs. Windows 11 Logon Phase: Logon Time Averages_

| Metric | Windows 10 | Windows 11 |
| --- | :---: | :---: |
| Logon time | `TBC` sec | `TBC` sec | 
| User profile load | `TBC` | `TBC` sec |
| Group policies | `TBC` sec | `TBC` sec | 
| Connection | `TBC` sec | `TBC` sec | 

![Overall logon times for the eight-node cluster peaked at 8.06 seconds (Windows 10) and 7.92 seconds (Windows 11).](../images/RA-2022-login_times_total_logon_time_W10_v_W11.png "Windows 10 vs. Windows 11: Logon Times")

<!--TEMPLATE CONTENT: Validate Above--> 

The following tables show application performance details during the logon phase of the test. A lower result represents better performance.

_Table: Windows 10 vs. Windows 11 Logon Phase: App Start Times_

| Application | Windows 10 | Windows 11 | 
| --- | :---: | :---: | 
| Microsoft Outlook | `TBC` sec | `TBC` sec | 
| Microsoft Word | `TBC` sec | `TBC` sec |  
| Microsoft Excel | `TBC` sec | `TBC` sec |
| Microsoft PowerPoint | `TBC` sec | `TBC` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Windows 10 vs. Windows 11 Logon Phase: Specific Action Times_

| Application (Action) | Windows 10 | Windows 11 | 
| --- | :---: | :---: | 
| Microsoft Edge (Page Load) | `TBC` sec | `TBC` sec | 
| Microsoft Word (Open Doc) | `TBC` sec | `TBC` sec | 
| Microsoft Excel (Save File) | `TBC` sec | `TBC` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

### Windows 10 vs. Windows 11 Steady State

The following tables show application performance details during the steady state of the test. A lower result represents better performance.

_Table: Windows 10 vs. Windows 11 Steady State: App Start Times_

| Application | Windows 10 | Windows 11 | 
| --- | :---: | :---: | 
| Microsoft Word | `TBC` sec | `TBC` sec | 
| Microsoft Excel | `TBC` sec | `TBC` sec | 
| Microsoft PowerPoint | `TBC` sec | `TBC` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Windows 10 vs. Windows 11 Steady State: Specific Action Times_

| Application (Action) | Windows 10 | Windows 11 | 
| --- | :---: | :---: | 
| Microsoft Edge (Page Load) | `TBC` sec | `TBC` sec | 
| Microsoft Word (Open Doc) | `TBC` sec | `TBC` sec | 
| Microsoft Excel (Save File) | `TBC` sec | `TBC` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

## Nutanix Files and Citrix Profile Containers

<!--TEMPLATE CONTENT: Validate Above--> 

This section compares the Login Enterprise test results for a scenario using local profiles with a scenario using Citrix Profile Containers (CPM) hosted on Nutanix Files. Both scenarios used an eight-node cluster with MCS provisioned workloads. Nutanix Files was collocated on the same cluster as the Windows Server 2022 workloads. We compared the first run of each test to capture the profile creation impact.

When measuring the impact of Nutanix Files collocated on the same cluster as the workloads, we found the following:

-  The overall cluster I/O, as measured by the Nutanix CVM (`controller_num_iops`), shows a reduction in overall cluster IOPS due to a change in the data path for Nutanix Files–based I/O.
-  The Nutanix FSVMs capture and display I/O data as it relates to file serving (`iops`). These I/O operations aren't a one-for-one replacement of the reduced cluster I/O.
-  Enabling continuous availability increases the amount of I/0.
-  The Nutanix CVM measurements associated with the physical disks (`num_iops`) capture the raw impact of Nutanix Files.

To understand the impact of Nutanix Files on the workload cluster, we capture and analyze the following metrics:

-  Cluster controller IOPS measured by the CVM `controller_num_iops`, `controller_num_write_iops`, and `controller_num_read_iops` counters
-  Nutanix Files IOPS measured by the Nutanix Files FSVM `iops`, `metadata_iops`, `read_iops`, and `write_iops` counters
-  Cluster disk IOPS measured by the CVM `num_iops`, `num_read_iops`, and `num_write_iops` counters

### Local Profiles vs. Nutanix Files with Citrix Profile Containers System Performance

The following table provides the averages for the overall system performance results. For an explanation of CPU ready time, see [Nutanix KB 5012: Interpreting CPU Ready Values](https://portal.nutanix.com/kb/5012).

_Table: System Performance Local Profiles vs. Nutanix Files with Citrix Profile Containers: System Performance Metric Averages_

| Metric | Local Profiles | Profile Containers  |
| --- | :---: | :---: | 
| CPU usage | `TBD`% |`TBD`% |
| CPU ready time | `TBD`% |`TBD`% |
| Controller read IOPS | `TBD` | `TBD` | 
| Controller write IOPS | `TBD` | `TBD` | 
| Controller latency | `TBD` ms | `TBD` ms | 

<!--TEMPLATE CONTENT: Validate Above--> 

During the login phase of a test, we expect resource usage to show an upward trend and ultimately result in peak values. During the steady state phase of a test, resource usage should both reduce and stay more consistent.

![The CPU usage for the eight-node cluster peaked at 86.4 percent (using local profiles) and 90.2 percent (using Nutanix Files with Citrix Profiles) during the login phase.](../images/RA-2003-cluster_resources_cpu_usage_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Citrix Profiles: CPU Usage")

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU ready times for the eight-node cluster peaked at 1.68 percent (using local profiles) and 2.25 percent (using Nutanix Files with Citrix Profiles) during the login phase.](../images/RA-2003-cluster_resources_cpu_ready_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Citrix Profile Containers: CPU Ready Times")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller read IOPS for the eight-node cluster peaked at 11,719 IOPS (using local profiles) and 11,368 IOPS (using Nutanix Files with Citrix Profiles) during the login phase.](../images/RA-2003-cluster_resources_controller_read_iops_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Citrix Profile Containers: Controller Read IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller write IOPS for the eight-node cluster peaked at 19,794 IOPS (using local profiles) and 14,844 IOPS (using Nutanix Files with Citrix Profiles) during the login phase.](../images/RA-2003-cluster_resources_controller_write_iops_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Citrix Profile Containers: Controller Write IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

We saw the following maximum latencies during our testing.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Cluster Controller Latencies_

| Metric | Local Profiles | Profile Containers  |
| --- | :---: | :---: |
| Overall controller latency | `TBD` ms | `TBD` ms |
| Controller write I/O latency | `TBD` ms | `TBD` ms |
| Controller read I/O latency | < `TBD` ms | `TBD` ms |

These tests included hosting Nutanix Files on the same workload cluster.

<!--TEMPLATE CONTENT: Validate Above--> 

![Controller I/O latency trends for one MCS-deployed eight-node cluster using local profiles and Nutanix Files with Profiles](../images/RA-2003-cluster_resources_controller_latency_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Profiles: Controller I/O Latency")

<!--TEMPLATE CONTENT: Validate Above--> 

### Local Profiles vs. Nutanix Files with Citrix Profile Containers Logon Phase

We run each test three times with Login Enterprise. On the first test, Citrix Profile Management creates the profiles for the first time. If you use Nutanix Files with Citrix Profile Management, additional test runs use an existing profile. If you use local profile configurations, when the machine resets back to the default state after each test, it removes the user profile. We used the first-run data set to capture the impact of user profile creation. Subsequent logons show a reduced footprint because the profiles already exist.

The following tables show the average logon times across the test runs. A lower result represents better performance.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Logon Time Averages_

| Metric | Local Profiles | Profile Containers  |
| --- | :---: | :---: | 
| Average logon time | `TBD` sec | `TBD` sec |
| User profile load | `TBD` sec | `TBD` sec | 
| Group policies | `TBD` sec | `TBD` sec |
| Connection | `TBD` sec | `TBD` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

The following tables show application performance details during the logon phase of the test. A lower result represents better performance.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: App Start Times_

| Application | Local Profiles | Profile Containers |
| --- | :---: | :---: |  
| Microsoft Outlook | `TBD` sec | `TBD` sec |
| Microsoft Word | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Specific Action Times_

| Application (Action) | Local Profiles | Profile Containers |
| --- | :---: | :---: |  
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec |
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

### Local Profiles vs. Nutanix Files with Citrix Profile Containers Steady State

The following tables show the details of application performance during the steady state of the test. A lower result represents better performance.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: App Start Times_

| Application (Action) | Local Profiles | Profile Containers |
| --- | :---: | :---: |  
| Microsoft Word | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Specific Action Times_

| Application (Action) | Local Profiles | Profile Containers |
| --- | :---: | :---: |  
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec |
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec |
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

### Nutanix Files with Citrix Profile Containers

The following tables and graphs outline the performance impacts associated with Nutanix Files specific metrics.

_Table: Nutanix Files Metrics at the Nutanix FSVM level_

| Metric | Maximum | Average |
| --- | :---: | :---: |
| Nutanix Files IOPS | `TBD` | `TBD` |
| Nutanix Files latency | `TBD` ms | `TBD` ms |
| Nutanix Files throughput | `TBD` MB/s | `TBD` MB/s |

<!--TEMPLATE CONTENT: Validate Above--> 

![Nutanix Files Total IOPS peaked at 12,107 IOPS on a single CA enabled share for Citrix Profiles.](../images/RA-2003-nutanix_files_iops_total_WS22_Local_vs_CPM.png "Nutanix Files Total IOPS with Citrix Profiles")

<!--TEMPLATE CONTENT: Validate Above--> 

![Nutanix Files Total Latency peaked at 15.0 milliseconds on a single CA enabled share for Citrix Profiles. ](../images/RA-2003-nutanix_files_latency_total_WS22_Local_vs_CPM.png "Nutanix Files Total Latency with Citrix Profiles")

<!--TEMPLATE CONTENT: Validate Above--> 

![Nutanix Files Total Throughput peaked at 489 MB/s on a single CA enabled share for Citrix Profiles.](../images/RA-2003-nutanix_files_throughput_total_WS22_Local_vs_CPM.png "Nutanix Files Total Throughput Citrix Profiles")

<!--TEMPLATE CONTENT: Validate Above--> 

The following tables and graphs outline the performance impacts on the Cluster Disks when Nutanix Files is deployed, and Citrix Profile Containers are enabled. 

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Management Containers: Nutanix Cluster Disk metrics (Averages)_

| Metric | Local Profiles | Profile Containers | 
| --- | :---: | :---: |  
| Cluster disk total IOPS | `TBD` | `TBD` |
| Cluster disk read IOPS | `TBD` | `TBD` |
| Cluster disk write IOPS | `TBD` | `TBD` |

<!--TEMPLATE CONTENT: Validate Above--> 

![Cluster Disk Total I/O comparison using local profiles and Nutanix Files with CPM Profiles. The Total I/O peaked at 15,776 for the local profile test, and 17,172 for the Nutanix Files with Citrix Profile Containers test.](../images/RA-2003-cluster_disk_iops_total_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Cluster Disk Total I/O Disk")

<!--TEMPLATE CONTENT: Validate Above--> 

![Cluster Disk Read I/O comparison using local profiles and Nutanix Files with CPM Profiles. The Read I/O peaked at 15,361 for the local profile test, and 16,713 for the Nutanix Files with Citrix Profile Containers test.](../images/RA-2003-cluster_disk_iops_read_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Cluster Disk Read I/O Disk")

<!--TEMPLATE CONTENT: Validate Above--> 

![Cluster Disk Write I/O comparison using local profiles and Nutanix Files with CPM Profiles. The Write I/O peaked at 463 for the local profile test, and 3,634 for the Nutanix Files with Citrix Profile Containers test.](../images/RA-2003-cluster_disk_iops_write_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Cluster Disk Write I/O Disk")

<!--TEMPLATE CONTENT: Validate Above--> 

### Citrix Profile Containers Advanced Information

Citrix Profile Management containers have a range of advanced functionalities and features that can affect performance. For performance impacts and considerations, see [Citrix Profile Management on Nutanix Files](https://portal.nutanix.com/page/documents/solutions/details?targetId=TN-2002-Citrix-User-Profile-Management-on-Nutanix:TN-2002-Citrix-User-Profile-Management-on-Nutanix).

The appendix section of this document includes the Citrix Profile Management container settings that we used during testing.

## Results Summary

Our results show that if you use MCS-provisioned or Provisioning-streamed servers to linearly scale the Citrix Delivery Solutions on Nutanix, the system maintains the same average response times regardless of how many nodes you have. 

Test results summary:

- The tested session host specification provided a consistent user experience across all tests.
- Provisioning and MCS configurations performed similarly, although the Provisioning-deployed cluster saw slightly higher logon times.
- Provisioning had generally shorter application start times than MCS in these tests.
- Provisioning had a greater impact on the writes on the cluster hosting the workloads, and MCS had a greater impact on the reads. We expect these effects due to the write-heavy nature of the Provisioning filter driver.
- Compared with Windows 10, Windows 11 has a higher CPU footprint during the logon phase.
- When you optimize Windows 10 and Windows 11, the logon experience is similar.
- Application response times are generally similar between  Windows 11 and Windows 10.
- Windows 11 CPU configurations are critical: A 3 vCPU instance performed better than a 2 vCPU instance.
- Using 3 vCPU with Windows 11 or 2 vCPU with Windows 10 didn't affect the overall cluster metrics, although the 3 vCPU configuration had a higher CPU ready time.
- Provisioning and MCS configurations performed similarly, although the Provisioning-deployed cluster saw higher logon times.
- MCS had generally shorter application start times than Provisioning, which is expected because Provisioning streams data on first access. Subsequent access launches from the local cache.
- Provisioning has a greater impact on the writes on the cluster hosting the workloads, and MCS has a greater impact on the reads. We expect these effects due to the write-heavy nature of the Provisioning filter driver.

<!--TEMPLATE CONTENT: Validate Above--> 

# Conclusion

The combined Citrix on Nutanix solution provides a single high-density platform for virtual desktop delivery. This modular, linearly scaling approach lets you grow Virtual Apps and Desktops and Citrix DaaS deployments easily. Localized and distributed caching and integrated disaster recovery enable quick deployments and simplify day-to-day operations. Robust self-healing and multistorage controllers deliver high availability in the face of failure or rolling upgrades.

On Nutanix, available host CPU resources drive Citrix user density, rather than any I/O or resource bottlenecks for virtual desktops. Login Enterprise test results showed densities at 180 sessions per node for virtual workloads running the Login Enterprise knowledge worker workload. Nutanix offers a pay-as-you grow model that works like public cloud.

# Appendix

## Network

- Arista 7050Q: L3 spine
- Arista 7050S: L2 leaf

## Citrix Policy Customization

We applied the Citrix policies in the following table.

_Table: Custom Citrix Policies_

| Parameter | Value |
| --- | --- |
| Audio quality | Medium |
| Auto connect client drives | Disabled |
| Auto-create client printers | Do not auto-create client printers |
| Automatic installation of in-box printer drivers | Disabled |
| Client fixed drives | Prohibited |
| Client network drives | Prohibited |
| Client optical drives | Prohibited |
| Client removable drives | Prohibited |
| Desktop wallpaper | Prohibited |
| HDX Adaptive Transport | Off |
| Menu animation | Prohibited |
| Multimedia conferencing | Prohibited |
| Optimization for Windows Media multimedia redirection over WAN | Prohibited |
| Use video codec for compression | Do not use video codec |
| View window contents while dragging | Prohibited |
| Windows Media fallback prevention | Play all content |

## Citrix Profile Management Configuration

_Table: Custom Profile Management Configuration_

| Parameter | Value |
| --- | --- |
| Enable Profile management | Enabled |
| Path to user store | Nutanix Files SMB Share |
| Processed Groups | Domain Users |
| Profile Container | Enabled with * to include the entire profile in the container |
| Automatically reattach VHDX disks in sessions | Enabled |
| Disable automatic configuration | Enabled |
| Enable logging | Enabled |
| Log settings | Common warnings, Common information, Logon, Logoff, Personalized user information |
| Enable exclusive access to VHD containers | Enabled |
| Enable local caching for profile containers | Disabled |
| Local profile conflict handling | Delete local profile |

<!--TEMPLATE CONTENT: Validate Above-->

## EUX Setting Customization

We used the Login Enterprise EUX settings in the following table.

_Table: EUX Actions Settings_

| Action | App | Argument | Label |
| --- | --- | --- | --- | 
| diskmydocs | diskspeed | `folder=\"{myDocs}\" blockSize=4k bufferSize=4K writeMask=0x5555 cachePct=97 latencyPct=99 threads=1 duration=250` | MyDocuments |
| cpuspeed | cpuspeed | `d=250 t=4` | CPU |
| highcompression | compressionspeed | `folder=\"{appData}\" cachePct=95 writePct=100 duration=250 threads=1 -high` | Compression |
| fastcompression | compressionspeed | `folder=\"{appData}\" cachePct=95 writePct=100 duration=250 threads=1` | CachedHigh&ZeroWidthSpace;Compression |
| appspeed | appspeed | `folder=\"{appData}\" duration=10000 launchtimestamp=`&ZeroWidthSpace;`{launchTimestamp}` | App |

_Table: EUX Tuning Settings_

| Parameter | Value |
| --- | :---: |
| PerformancePenalty | 3.0 |
| BucketSizeInMinutes  | 5 |
| NumSamplesForBaseline | 5 |
| CapacityRollingAverageSize | 3 |
| MaxBaselineForCapacity | 4,000 |
| CapacityTrigger | < 80% |
| SteadyStateCooldownWindow | 5 |
| BaselineScoreWindowSize | 5 |

_Table: EUX Measurement Tuning Settings_

| Action | Weight | NominalValue | CapacityTrigger |
| --- | :---: | :---: | :---: | 
| DiskMyDocs | 0 | 8,500 | < 25% | 
| DiskMyDocsLatency | 0 | 1,200 | < 5% | 
| CpuSpeed | 0 | 50,000 | < 55% | 
| HighCompression | 1 | 2,000 | < 5% | 
| FastCompression | 1 | 2,000 | < 5% | 
| AppSpeed | 6 | 2,700 | < 80% | 
| AppSpeedUserInput | 1 | 500 | < 35% | 

## References

1.  [End-User Computing Performance Benchmarking](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2161-EUC-Performance-Benchmarking:BP-2161-EUC-Performance-Benchmarking)
2.  [Login Enterprise](https://www.loginvsi.com/)
3.  [Login Enterprise EUX Score](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-#h_01GS8W30049HVB851TX60TDKS3)
4.  [Login Enterprise Workload Templates](https://support.loginvsi.com/hc/en-us/sections/360001765419-Workload-Templates)
5.  [Citrix DaaS Documentation](https://docs.citrix.com/en-us/citrix-daas/overview)
6.  [Microsoft SQL Server on Nutanix](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2015-Microsoft-SQL-Server:BP-2015-Microsoft-SQL-Server)

<!--TEMPLATE CONTENT: Validate Above-->
