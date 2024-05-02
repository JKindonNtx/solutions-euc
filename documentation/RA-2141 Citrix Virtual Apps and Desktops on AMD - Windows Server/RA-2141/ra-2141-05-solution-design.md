#  Solution Design

In the following section, we cover the design decisions and rationale for Citrix Virtual Apps and Desktops deployments on Nutanix.

_Table: Platform Design Decisions_

| Design Area | Item | Detail | Rationale |
| --- | --- | --- | --- |
| General | Software versions | Citrix Virtual Apps and Desktops 2402; Citrix Provisioning 2402; AOS 6.5.5.1 | – |
| General | Minimum size | 3 Nutanix nodes running AHV | Minimum size requirement |
| General | Scale approach | Incremental modular scale | (hundreds of desktops) to massive scale (thousands of desktops) `Allows growth from proof of concept (tens of servers) to massive scale (hundreds of servers)` |
| General | Scale unit | Nodes, blocks, or pods | Granular scale to precisely meet capacity demands; scale in n × node increments |
| Nutanix AHV | Cluster size | As many as 16 hosts (minimum of 3 hosts) | Isolated fault domains (best practice) |
| Nutanix AHV | Datastores | 1 Nutanix storage datastore per pod (Citrix Virtual Apps and Desktops Desktop VMs, VM clones, and so on) | Nutanix handles I/O distribution and localization; n-Controller model |
| Nutanix AHV | Infrastructure services | Small deployments: Shared cluster; Large deployments: Dedicated cluster | Dedicated infrastructure cluster for larger deployments (best practice) |
| Nutanix | Cluster size | As many as 16 nodes | Isolated fault domains (best practice) |
| Nutanix | Storage pools | 1 storage pool per cluster | Standard practice; intelligent tiering handles data locality |
| Nutanix | Containers | 1 container for VMs | Standard practice |
| Nutanix | Features and enhancements | Increase CVM memory to 24–32+ GB. Turn on deduplication and compression for persistent desktops. Turn on compression only for nonpersistent desktops. (We set the CVM to 32 GB for the reference architecture.) | Best practice |
| Citrix Virtual Apps and Desktops | Delivery Controllers | Minimum: 2 (n + 1); Scale: 1 per additional pod | High availability for Delivery Controllers |
| Citrix Virtual Apps and Desktops | Users per controller | Up to 5,000 users | Virtual Apps and Desktops best practice |
| Citrix Virtual Apps and Desktops | Load balancing | Built into Delivery Controllers | Ensures availability of Delivery Controllers ; balances load between Delivery Controllers |
| Citrix Virtual Apps and Desktops | Virtual hardware specs | vCPU: 4; Memory: 4+ GB (local host cache); Disk: 60 GB vDisk | Standard sizing practice |
| Citrix Virtual Apps and Desktops | Desktop management | Nutanix AHV plug-in desktop management | Allows deployment and management |
| Citrix Provisioning | Provisioning servers | Minimum: 2 (n + 1); Scale: 2 per additional pod | High availability for Provisioning server |
| Citrix Provisioning | Load balancing | Built into Provisioning servers | Balances load between Provisioning servers |
| Citrix Provisioning | Virtual hardware specs | vCPU: 8; Memory: 12+ GB (number of vDisks); Disk: 60 GB vDisk | Standard sizing practice |
| Citrix Provisioning | vDisk store | Dedicated disk on Nutanix or Nutanix Files shared vDisk Store | Standard practice |
| Citrix Provisioning | Write cache | On local hard drive | Best practice if the storage can provide enough I/O |
| Citrix StoreFront | StoreFront servers | Minimum: 2 (n + 1) | High availability for StoreFront servers |
| Citrix StoreFront | Load balancing | Citrix NetScaler (including Citrix NetScaler VPX) | Ensures availability of StoreFront servers; balances load between StoreFront servers | 
| Citrix StoreFront | Virtual hardware specs | vCPU: 2+; Memory: 4+ GB; Disk: 60 GB vDisk | Standard sizing practice |
| Citrix StoreFront | NetScaler virtual appliances | Minimum: 2 | High availability for NetScaler (active-passive) |
| Citrix StoreFront | Users per NetScaler virtual appliance | See [product data sheet](https://www.citrix.com/products/citrix-adc/platforms.html) | Varies per model |
| Citrix StoreFront | Load balancing | NetScaler high availability | Ensures availability of NetScaler virtual appliances; balances load between Delivery services and pods |  

_Table: Infrastructure Design Decisions_

| Design Area | Item | Detail | Rationale |
| --- | --- | --- | --- |
| Active Directory | Global catalog and DNS servers | Minimum: 2 (n + 1) per site | High availability for global catalog and DNS; Microsoft best practice |
| DHCP | DHCP servers | Nutanix IPAM | High availability for Nutanix IPAM is built in |
| DHCP | Load balancing | Built-in | Ensures availability of DHCP | 
| SQL Server | SQL Servers | Minimum: 2 (n + 1) per site; Scale: 2 per additional pod | High availability for SQL Servers |
| SQL Server | Data protection | SQL Server clustering, mirroring, or Always On availability groups (including basic availability groups) | Ensures availability of SQL Server instances |

## Virtual Delivery Agent Optimizations

We generated our design with the following high-level Virtual Delivery Agent (VDA) optimization guidelines in mind:

- Size desktops appropriately for each use case.
- Disable unnecessary OS services and applications.
- Redirect home directories or use a profile management tool for user profiles and documents.

For more details on desktop optimizations, refer to the [Citrix Windows 10 Optimization Guide](https://support.citrix.com/article/CTX216252) and the [Citrix Optimizer](https://support.citrix.com/article/CTX224676).