# Citrix Virtual Apps and Desktops on Nutanix Solution Design

This section covers the design decisions and rationale for Citrix Virtual Apps and Desktops deployments on Nutanix.

_Table: Platform Design Decisions: General_

| Item | Detail | Rationale |
| --- | --- | --- |
| Software versions | Citrix DaaS with Citrix VDA 2203 CU3; AOS 6.5.4.5 | Latest LTS version available |
| Minimum size | 3 Nutanix nodes (3 Nutanix AHV hosts) | Minimum size requirement |
| Scale approach | Incremental modular scale | Allows growth from proof of concept (hundreds of desktops) to massive scale (thousands of desktops) |
| Scale unit | Nodes, blocks, or pods | Granular scale to precisely meet capacity demands; scale in n × node increments |

_Table: Platform Design Decisions: Nutanix AHV_

| Item | Detail | Rationale |
| --- | --- | --- |
| Cluster size | Up to 16 Nutanix AHV hosts (minimum of 3 hosts) | Isolated fault domains (best practice) |
| Datastores | 1 Nutanix datastore per pod (Citrix DaaS VMs, VM clones, and so on) | Nutanix handles I/O distribution and localization; n-Controller model |
| Infrastructure services | Small deployments: Shared cluster; Large deployments: Dedicated cluster | Dedicated infrastructure cluster for larger deployments (best practice) |

_Table: Platform Design Decisions: Nutanix_
  
| Item | Detail | Rationale |
| --- | --- | --- |
| Cluster size | Up to 16 nodes | Isolated fault domains (best practice) |
| Storage pools | 1 storage pool per cluster | Standard practice; intelligent tiering handles data locality |
| Containers | 1 container for VMs | Standard practice |
| Features and enhancements | Increase CVM memory to 24-32 GB. Turn on deduplication and compression for persistent desktops. Turn on compression only for nonpersistent desktops. (We set the CVM to 32 GB for the reference architecture.) | Best practice |
  
_Table: Platform Design Decisions: Citrix DaaS_

| Item | Detail | Rationale |
| --- | --- | --- |
| Cloud Connectors | Minimum: 2 (n + 1); Scale: 1 per additional pod | High availability for Cloud Connectors |
| Users per resource location | Up to 10,000 VDAs with up to 20,000 total sessions | Citrix DaaS limits |
| Load balancing | Built into Cloud Connectors | Ensures availability of Cloud Connectors; balances load between Cloud Connectors |
| Virtual hardware specs | vCPU: 4; Memory: 4+ GB (local host cache); Disk: 60 GB vDisk | Standard sizing practice |
| Desktop management | Nutanix AHV plug-in desktop management | For deployment and management |

_Table: Platform Design Decisions: Citrix Provisioning_

| Item | Detail | Rationale |
| --- | --- | --- |
| Provisioning servers | Minimum: 2 (n + 1); Scale: 2 per additional pod | High availability for Provisioning servers |
| Load balancing | Built into Provisioning servers | Balances load between Provisioning servers |
| Virtual hardware specs | vCPU: 4; Memory: 12+ GB (number of vDisks); Disk: 60 GB vDisk | Standard sizing practice |
| vDisk store | Dedicated disk on Nutanix or Nutanix Files shared vDisk Store | Standard practice |
| Write cache | On local hard drive | Best practice if the storage can provide enough I/O |

_Table: Platform Design Decisions: Citrix StoreFront_

| Item | Detail | Rationale |
| --- | --- | --- |
| StoreFront servers | Minimum: 2 (n + 1) | High availability for StoreFront servers |
| Load balancing | Citrix NetScaler (including Citrix NetScaler VPX) | Ensures availability of StoreFront servers; balances load between StoreFront servers | 
| Virtual hardware specs | vCPU: 2+; Memory: 4+ GB; Disk: 60 GB vDisk | Standard sizing practice |
| NetScaler virtual appliances | Minimum: 2 | High availability for NetScaler (active-passive) |
| Users per NetScaler virtual appliance | See [product data sheet](https://www.citrix.com/products/citrix-adc/platforms.html) | Varies per model |
| Load balancing | NetScaler high availability | Ensures availability of NetScaler virtual appliances; balances load between Application Delivery Controller servers and pods |  

_Table: Infrastructure Design Decisions: Active Directory_

| Item | Detail | Rationale |
| --- | --- | --- |
| Global catalog and DNS servers | Minimum: 2 (n + 1) per site | High availability for global catalog and DNS; Microsoft best practice |

_Table: Infrastructure Design Decisions: DHCP_

| Item | Detail | Rationale |
| --- | --- | --- |
| DHCP servers | Nutanix IPAM | High availability for Nutanix IPAM is built in |
| Load balancing | Built-in | Ensures availability of DHCP | 

_Table: Infrastructure Design Decisions: Nutanix Files_

| Item | Detail | Rationale |
| --- | --- | --- |
| Nutanix Files | Minimum: 3 per site | High availability for Nutanix Files servers |
| Load balancing | Built-in | Ensures availability of Nutanix Files; balances load between Nutanix Files servers |

## VDA Optimizations

We generated our design with the following high-level VDA optimization guidelines in mind:

- Size desktops appropriately for each use case.
- Use a mix of applications installed in template images, application layering, and virtualization.
- Disable unnecessary OS services and applications.
- Redirect home directories or use a profile management tool for user profiles and documents.

For more details on desktop optimizations, refer to the [Citrix Windows 10 Optimization Guide](https://support.citrix.com/article/CTX216252) and the [Citrix Optimizer](https://support.citrix.com/article/CTX224676).