# Citrix Virtual Apps and Desktops on Nutanix

The Nutanix modular web-scale architecture lets you start small and expand to meet increasing demand—a node, a block, or multiple blocks at a time—with no effect on performance. This design removes the hurdle of a large initial infrastructure purchase, decreasing the time to value for your Citrix Virtual Apps and Desktops implementation. Running Citrix Virtual Apps and Desktops on Nutanix enables you to run multiple workloads, all on the same scalable converged infrastructure, while achieving these benefits:

Modular incremental scale
: With the Nutanix solution, you can start small and scale up. A single Nutanix block provides dozens of terabytes of storage and hundreds to thousands of virtual desktops in a compact footprint. Given the solution's modularity, you can granularly scale by node, by block, or with multiple blocks, accurately matching supply with demand and minimizing the upfront capex.

High performance
: By using system memory caching for read I/O and flash storage for read and write I/O, you can deliver high-performance throughput in a compact form factor. 

Change management
: Maintain environmental control and separation between development, test, staging, and production environments. Snapshots and fast clones can help share production data with nonproduction jobs without requiring full copies and unnecessary data duplication.

Business continuity and data protection
: User data and desktops are mission-critical and need enterprise-grade data management features, including backup and disaster recovery. 

Data efficiency
: Nutanix storage offers both compression and deduplication to help reduce the storage footprint. The compression functionality is truly VM-centric. Unlike traditional solutions that perform compression mainly at the LUN level, the Nutanix solution provides all these capabilities at the VM and file levels, greatly increasing efficiency and simplicity. These capabilities ensure the highest possible compression and decompression performance, even below the block level.

Enterprise-grade cluster management
: Nutanix offers a simplified and intuitive approach to managing large clusters, including a converged GUI that serves as a central point for servers and storage, alert notifications, and the bonjour mechanism that automatically detects new nodes in the cluster. As a result, you can spend time enhancing your environment rather than maintaining it.

High-density architecture
: Nutanix uses an advanced server architecture that, using the NX-3000 series as an example, can house eight Intel CPUs (up to 160 cores) and up to 6 TB of memory in a single 2RU appliance. Coupled with data archiving and compression, Nutanix can make the desktop hardware footprint five times smaller.

Time-sliced clusters
: Like public cloud environments, Nutanix can provide a truly converged cloud infrastructure, allowing you to run your server and desktop virtualization on a single cloud. Get the efficiency and savings you require with a converged cloud on a unified architecture.

## Citrix Virtual Apps and Desktops on VMware vSphere with Nutanix Cloud Platform

The following figure shows the main architectural components of the Citrix Virtual Apps and Desktops on Nutanix solution and the communication path between services. 
 
![Overview of Citrix Virtual Apps and Desktops on Nutanix](../images/cvad-on-nutanix.png "Overview of Citrix Virtual Apps and Desktops on Nutanix")

## Pod Design

The following tables contain high-level details of the Citrix Virtual Apps and Desktops on Nutanix hosted virtual desktop pod.

_Table: Control Pod Details_

| **Item** | **Quantity** |
|---|---|
| Delivery Controllers | 2 |
| StoreFront servers | 2 |

_Table: Services Pod Details_

| **Item** | **Quantity** |
|---|---|
| vSphere hosts | Up to 32 |
| Nutanix clusters | 1 |
| Datastores | 1 |
| Desktops | Up to 3,875 |

You can have a maximum of 32 vSphere host nodes per cluster. We validated Citrix Virtual Apps and Desktops with Windows desktop VDAs and the Login Enterprise knowledge worker workload, using 2 vCPU and 4 GB of memory per VM and 125 VMs per node. When you use 32 vSphere host nodes, you can run up to 3,875 Windows desktop VDAs per Nutanix vSphere cluster.

<note>
This calculation reserves one node as a spare (n + 1).
</note>

We based the sizing of this pod design on the Login Enterprise knowledge worker workload. A more resource-intensive workload results in a lower density, and a less resource-intensive workload results in a higher density. If you change the vCPU count or memory, the number of Windows VDAs per node and per cluster changes as well.

<note>
During testing AOS raised an NFS metadata size overshoot alert for the datastore. Although everything performed normally, we recommend breaking up large datastores into smaller failure domains of 1,000 VMs per datastore.
</note>

## Nutanix Compute and Storage

Nutanix provides an ideal combination of high-performance compute and localized storage to meet any demand. True to this capability, this reference architecture contains no reconfiguration or customization of the Nutanix product to optimize for this use case. The following figure shows a high-level example of the relationship between the Nutanix storage pool and containers.
 
![Storage Overview](../images/nutanix-storage-pools-containers.png "Storage Overview")

The following table details the Nutanix storage pool and container configuration.

| **Name** | **Role** | **Details** |
| --- | --- | --- |
| SP01 | Main storage pool for all data | SSD + HDD |
| VDI | Container for all VMs | vSphere datastore |
| Default-Container | Container for all data (not used here) | vSphere datastore |
