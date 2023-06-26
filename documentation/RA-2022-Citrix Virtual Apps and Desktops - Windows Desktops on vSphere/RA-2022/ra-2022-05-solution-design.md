# Citrix Virtual Apps and Desktops on Nutanix Solution Design

In this section, we cover the design decisions and rationale for Citrix Virtual Apps and Desktops deployments on Nutanix.

_Table: Platform Design Decisions: General_

| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| Software versions | Citrix Virtual Apps and Desktops 2203 CU2; AOS 6.5.1 | Latest LTS version available |
| Minimum size | 3 Nutanix nodes (3 vSphere hosts) | Minimum size requirement |
| Scale approach | Incremental modular scale | Allows growth from PoC (hundreds of desktops) to massive scale (thousands of desktops) |
| Scale unit | Nodes, blocks, or pods | Granular scale to precisely meet capacity demands; scale in n × node increments |

_Table: Platform Design Decisions: VMware vSphere_

| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| Cluster size | Up to 32 vSphere hosts (minimum of 3 hosts) | Isolated fault domains (best practice) |
| Clusters per vCenter | Up to 2 × 24-host or 4 × 12-host clusters | Task parallelization |
| Datastores | 1 Nutanix datastore per pod (Citrix Virtual Apps and Desktops server VMs, VM clones, and so on) | Nutanix handles I/O distribution and localization; n-Controller model |
| Infrastructure services | Small deployments: Shared cluster; Large deployments: Dedicated cluster | Dedicated infrastructure cluster for larger deployments (best practice) |

_Table: Platform Design Decisions: Nutanix_
  
| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| Cluster size | Up to 32 nodes | Isolated fault domains (best practice) |
| Storage pools | 1 storage pool per cluster | Standard practice; intelligent tiering handles data locality |
| Containers | 1 container for VMs | Standard practice |
| Features and enhancements | Increase CVM memory to 24–32+ GB. Turn on deduplication and compression for persistent desktops. Turn on compression only for nonpersistent desktops. (We set the CVM to 32 GB for the reference architecture.) | Best practice |
  
_Table: Platform Design Decisions: Citrix Virtual Apps and Desktops_

| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| Delivery Controllers | Minimum: 2 (n + 1); Scale: 1 per additional pod | High availability for Delivery Controllers |
| Users per controller | Up to 5,000 users | Citrix Virtual Apps and Desktops best practice |
| Load balancing | Built into Delivery Controllers | Ensures availability of Delivery Controllers; balances load between Delivery Controllers |
| Virtual hardware specs | vCPU: 4; Memory: 4+ GB (local host cache); Disk: 60 GB vDisk | Standard sizing practice |
| Desktop management | Nutanix AHV plug-in desktop management | For deployment and management |

_Table: Platform Design Decisions: Citrix Provisioning_

| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| Provisioning servers | Minimum: 2 (n + 1); Scale: 2 per additional pod | High availability for Provisioning servers |
| Load balancing | Built into Provisioning servers | Balances load between Provisioning servers |
| Virtual hardware specs | vCPU: 4; Memory: 12+ GB (number of vDisks); Disk: 60 GB vDisk | Standard sizing practice |
| vDisk store | Dedicated disk on Nutanix or Nutanix Files shared vDisk Store | Standard practice |
| Write cache | On local hard drive | Best practice if the storage can provide enough I/O |

_Table: Platform Design Decisions: Citrix StoreFront_

| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| StoreFront servers | Minimum: 2 (n + 1) | High availability for StoreFront servers |
| Load balancing | Citrix NetScaler (including Citrix NetScaler VPX) | Ensures availability of StoreFront servers; balances load between StoreFront servers | 
| Virtual hardware specs | vCPU: 2+; Memory: 4+ GB; Disk: 60 GB vDisk | Standard sizing practice |
| NetScaler virtual appliances | Minimum: 2 | High availability for NetScaler (active-passive) |
| Users per NetScaler virtual appliance | See [product data sheet](https://www.citrix.com/products/citrix-adc/platforms.html) | Varies per model |
| Load balancing | NetScaler high availability | Ensures availability of NetScaler virtual appliances; balances load between Application Delivery Controller servers and pods |  

_Table: Infrastructure Design Decisions: Active Directory_

| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| Global catalog and DNS servers | Minimum: 2 (n + 1) per site | High availability for global catalog and DNS; Microsoft best practice |

_Table: Infrastructure Design Decisions: DHCP_

| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| DHCP servers | Nutanix IPAM | High availability for Nutanix IPAM is built in |
| Load balancing | Built-in | Ensures availability of DHCP | 

_Table: Infrastructure Design Decisions: Nutanix Files_

| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| Nutanix Files | Minimum: 3 per site | High availability for Nutanix Files servers |
| Load balancing | Built-in | Ensures availability of Nutanix Files; balances load between Nutanix Files servers |

_Table: Infrastructure Design Decisions: SQL Server_

| **Item** | **Detail** | **Rationale** |
| --- | --- | --- |
| SQL Servers | Minimum: 2 (n + 1) per site; Scale: 2 per additional pod | High availability for SQL Servers |
| Data protection | SQL Server clustering, mirroring, or Always On availability groups (including basic availability groups) | Ensures availability of SQL Server instances |

## Desktop Optimizations

We generated our design with the following high-level desktop optimization guidelines in mind:

- Size desktops appropriately for each use case.
- Use a mix of applications installed in template images, application layering, and virtualization.
- Disable unnecessary OS services and applications.
- Redirect home directories or use a profile management tool for user profiles and documents.

For more details on desktop optimizations, refer to the [Citrix Windows 10 Optimization Guide](https://support.citrix.com/article/CTX216252) and the [Citrix Optimizer](https://support.citrix.com/article/CTX224676).
