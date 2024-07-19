# Citrix Delivery on VMware vSphere on NX-3155-G9 Solution Design

The following tables describe the design decisions and rationale for Citrix deployments on Nutanix.

_Table: Platform Design Decisions: Nutanix Common_

| Design Area | Item | Detail | Rationale |
| --- | --- | --- | --- |
| General | Software versions | Citrix DaaS; Citrix Virtual Apps and Desktops 2402; Citrix Provisioning 2402; AOS 6.5.5.1 | — |
| General | Minimum size | 3 Nutanix nodes running VMware vSphere | Minimum size requirement |
| General | Scale approach | Incremental modular scale | Allows growth from proof of concept (hundreds of desktops) to massive scale (thousands of desktops) |
| General | Scale unit | Nodes, blocks, or pods | Granular scale to precisely meet capacity demands; scale in n × node increments |
| VMware vSphere | Software Versions | VMware ESXi 7.0.3 and VMware vCenter Server 7.0.3.01200 | - | 
| VMware vSphere | Cluster size | Up to 16 vSphere hosts (minimum of 3 hosts) | Isolated fault domains (best practice) |
| VMware vSphere | Clusters per vCenter | `Up to 2 × 24-host or 4 × 12-host clusters` | Task parallelization |
| VMware vSphere | Datastores | 1 Nutanix storage datastore per pod (Citrix Virtual Apps and Desktops Desktop VMs, VM clones, and so on) | Nutanix handles I/O distribution and localization; n-Controller model |
| VMware vSphere | Infrastructure services | Small deployments: Shared cluster; Large deployments: Dedicated cluster | Dedicated infrastructure cluster for larger deployments (best practice) |
| Nutanix | Cluster size | As many as 16 nodes | Isolated fault domains (best practice) |
| Nutanix | Storage pools | 1 storage pool per cluster | Standard practice; intelligent tiering handles data locality |
| Nutanix | Containers | 1 container for VMs | Standard practice |
| Nutanix | Features and enhancements | Increase CVM memory to 24–32+ GB. Turn on deduplication and compression for persistent desktops. Turn on compression only for nonpersistent desktops. We set the CVM to `32 GB` for the reference architecture. | Best practice |
<!--SH: It's actually set to 48GB, because of all-NVMe --> 
| Nutanix Files | Deployment Location | Workload Cluster | SMB File Services for Citrix Profile Management Containers hosted locally to the workloads |
| Nutanix Files | FSVM configuration | 3 x FSVM, 4 vCPU, 16 GiB memory per FSVM | Recommended size for FSVM configuration for this workload |
| Nutanix Files | FSVM placement | DRS placed per VMWare vCenter recommendations | No preference on FSVM location on a workload cluster when load is evenly spread |

<!--JK: Sven, the Cluster for vCenter Guidance above, is this relevant??-->
<!--SH: I'm not sure where this is coming from. Let discuss Monday-->

The following components are specific to Citrix Virtual Apps and Desktops.

_Table: Platform Design Decisions: Citrix Virtual Apps and Desktops_

| Item | Detail | Rationale |
| --- | --- | --- |
| Delivery Controllers | Minimum: 2 (n + 1); Scale: 1 per additional pod | High availability for Delivery Controllers |
| Users per controller | Up to 5,000 users | Citrix Virtual Apps and Desktops best practice |
| Load balancing | Built into Delivery Controllers | Ensures availability of Delivery Controllers; balances load between Delivery Controllers |
| Virtual hardware specs | vCPU: 4; Memory: 4+ GB (Local Host Cache); Disk: 60 GB vDisk | Standard sizing practice |
| Desktop management | Integration with VMware vCenter Server | Allows deployment and management |

The following components are specific to Citrix DaaS.

_Table: Platform Design Decisions: Citrix DaaS_

| Item | Detail | Rationale |
| --- | --- | --- |
| Cloud Connectors | Minimum: 2 (n + 1); Scale: 1 per additional pod | High availability for Cloud Connectors |
| Users per Resource Location | Up to 10,000 VDAs with up to 25,000 total sessions | Citrix DaaS limits |
| Load balancing | Built into Cloud Connectors | Ensures availability of Cloud Connectors; balances load between Cloud Connectors |
| Virtual hardware specs | vCPU: 4; Memory: 4+ GB (local host cache); Disk: 60 GB vDisk | Standard sizing practice |
| Desktop management | Integration with VMware vCenter Server | Allows deployment and management |

The following components are relevant to both Citrix Virtual Apps and Desktops, along with Citrix DaaS:

_Table: Platform Design Decisions: Citrix Common Components_

| Design Area | Item | Detail | Rationale |
| --- | --- | --- | --- |
| Citrix Provisioning | Provisioning servers | Minimum: 2 (n + 1); Scale: 2 per additional pod | High availability for Provisioning Services |
| Citrix Provisioning | Load balancing | Built into Provisioning servers | Balances load between Provisioning servers |
| Citrix Provisioning | Virtual hardware specs | vCPU: 8; Memory: 12+ GB (number of vDisks); Disk: 60 GB vDisk | Standard sizing practice |
| Citrix Provisioning | vDisk store | Dedicated disk on Nutanix or Nutanix Files shared vDisk Store | Standard practice |
| Citrix Provisioning | Write cache | Cache in Device RAM with Overflow to Disk (set vDisk Cache size to 0) | Best practice for Citrix Provisioning with Nutanix |
| Citrix StoreFront | StoreFront servers | Minimum: 2 (n + 1) | High availability for StoreFront servers |
| Citrix StoreFront | Load balancing | Citrix NetScaler (including Citrix NetScaler VPX) | Ensures availability of StoreFront servers; balances load between StoreFront servers | 
| Citrix StoreFront | Virtual hardware specs | vCPU: 2+; Memory: 4+ GB; Disk: 60 GB vDisk | Standard sizing practice |
| Citrix StoreFront | NetScaler virtual appliances | Minimum: 2 | High availability for NetScaler (active-passive) |
| Citrix StoreFront | Users per NetScaler virtual appliance | See [product data sheet](https://www.citrix.com/products/citrix-adc/platforms.html) | Varies per model |
| Citrix StoreFront | Load balancing | NetScaler high availability | Ensures availability of NetScaler virtual appliances; balances load between Delivery services and pods | 

<note>Not all Citrix DaaS deployments require components such as Citrix Provisioning, Citrix StoreFront, or Citrix NetScaler.</note>

_Table: Infrastructure Design Decisions_

| Design Area | Item | Detail | Rationale |
| --- | --- | --- | --- |
| Active Directory | Global catalog and DNS servers | Minimum: 2 (n + 1) per site | High availability for global catalog and DNS; Microsoft best practice |
| DHCP | DHCP servers | Windows or 3rd Party DHCP services | High availability depends on chosen solution |
| SQL Server | SQL Servers | Minimum: 2 (n + 1) per site; Scale: 2 per additional pod | High availability for SQL Servers |
| SQL Server | Data protection | SQL Server clustering, mirroring, or Always On availability groups (including basic availability groups) | Ensures availability of SQL Server instances |

<note>Not all Citrix DaaS deployments require SQL. Components such as Citrix Provisioning require SQL.</note>

You should consult the [Microsoft SQL Server on Nutanix](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2015-Microsoft-SQL-Server:BP-2015-Microsoft-SQL-Server) best practices guide when deploying Microsoft SQL.

## Virtual Delivery Agent Optimizations

We generated our design with the following high-level Virtual Delivery Agent (VDA) optimization guidelines in mind:

- Size desktops appropriately for each use case.
- Disable unnecessary OS services and applications.
- Redirect home directories or use a profile management tool for user profiles and documents.

For more information on desktop optimizations, see the [Citrix Windows 10 Optimization Guide](https://support.citrix.com/article/CTX216252), [End-User Computing Performance Benchmarking](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2161-EUC-Performance-Benchmarking:BP-2161-EUC-Performance-Benchmarking) and [Citrix Optimizer](https://support.citrix.com/article/CTX224676) guides.