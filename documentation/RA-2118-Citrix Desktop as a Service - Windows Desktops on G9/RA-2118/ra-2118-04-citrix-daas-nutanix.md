# Citrix Desktop as a Service on Nutanix

The Nutanix modular web-scale architecture lets you start small and expand to meet increasing demand—a node, a block, or multiple blocks at a time—with no impact on performance. This design removes the hurdle of a large initial infrastructure purchase, decreasing the time to value for your Citrix Desktop as a Service (DaaS) implementation. Running Citrix DaaS on Nutanix enables you to run multiple workloads, all on the same scalable converged infrastructure, while achieving these benefits:

Modular incremental scale
: With the Nutanix solution you can start small and scale up. A single Nutanix block provides dozens of terabytes of storage and hundreds to thousands of virtual desktops in a compact footprint. With this modular solution, you can granularly scale by node, by block, or with multiple blocks, accurately matching supply with demand and minimizing the upfront capital expenditure.

High performance
: By using system memory caching for read I/O and flash storage for read and write I/O, you can deliver high-performance throughput in a compact form factor.

Change management
: Maintain environmental control and separation between development, test, staging, and production environments. Snapshots and fast clones can help share production data with nonproduction jobs without requiring full copies and unnecessary data duplication.

Business continuity and data protection
: User data and desktops are mission-critical and need enterprise-grade data management features, including backup and disaster recovery.

Data efficiency
: Nutanix storage offers both compression and deduplication to help reduce the storage footprint. The compression functionality is truly VM-centric. Unlike traditional solutions that perform compression mainly at the LUN level, the Nutanix solution provides all these capabilities at the VM and file levels, greatly increasing efficiency and simplicity. These capabilities ensure the highest possible compression and decompression performance, even below the block level.

Enterprise-grade cluster management
: Nutanix offers a simplified and intuitive approach to managing large clusters, including a converged GUI that serves as a central point for servers and storage, alert notifications, and the bonjour mechanism that automatically detects new nodes in the cluster.

High-density architecture
: Nutanix uses an advanced server architecture that, using the NX-3000 series as an example, can house eight Intel CPUs (up to 192 cores) and up to 8 TB of memory in a single 2RU appliance. Coupled with data archiving and compression, Nutanix can make the desktop hardware footprint five times smaller.

## Citrix DaaS on Nutanix AHV with Nutanix Cloud Platform

The following figure shows the main architectural components of the Citrix Virtual Apps and Desktops on Nutanix solution and the communication path between services. 
 
![Image showing the main architectural components of the Citrix Virtual Apps and Desktops on Nutanix solution and the communication path between the different services](../images/RA-2118_image02.png "Overview of Citrix Virtual Apps and Desktops on Nutanix")

## Pod Design

The following tables contain high-level details of the Citrix Virtual Apps and Desktops on Nutanix hosted virtual desktop pod.

_Table: Control Pod Details_

| Item | Quantity |
| --- | :---: |
| Cloud Connectors | 2 |
| StoreFront servers | 2 |

_Table: Services Pod Details_

| Item | Quantity |
| --- | :---: |
| Nutanix hosts | 16 |
| Nutanix clusters | 1 |
| Datastores | 1 |

We recommend having a maximum of 16 Nutanix AHV host nodes per cluster. We validated Citrix DaaS, using 2 vCPU and 4 GB of memory per VM and 130 VMs per node. When you use 8 Nutanix AHV host nodes.

<note>
Note: Limiting the cluster sizes to 16 nodes reduces the failure domain and the time to patch and update the clusters. This reference architecture uses 16-node building blocks to take advantage of single-rack design, smaller failure domain, and reduced time to patch and update.
</note>

<note>
This calculation reserves one node as a spare (n + 1).
</note>

We based the sizing of this pod design on the Login Enterprise Knowledge Worker workload. A more resource-intensive workload results in a lower density, and a less resource-intensive workload results in a higher density. If you change the vCPU count or memory, the number of VDAs per node and per cluster changes as well.

## Nutanix Compute and Storage

Nutanix provides an ideal combination of high-performance compute and localized storage to meet any demand. True to this capability, this reference architecture contains no reconfiguration or customization of the Nutanix product to optimize for this use case. The following figure shows a high-level example of the relationship between the Nutanix storage pool and containers.
 
![Image showing the Nutanix Storage Pool and Container layout. It demonstrated the ability to seamlessly add containers to a storage pool and have it grow dynamically](../images/RA-2118_image03.png "Nutanix Storage Overview")

The following table details the Nutanix storage pool and container configuration.

_Table: Nutanix Storage Configuration_

| Name | Role | Details |
| --- | --- | --- |
| SP01 | Main storage pool for all data | SSD + HDD |
| VDI | Container for all VMs | Nutanix datastore |
| Default-Container | Container for all data (not used here) | Nutanix datastore |