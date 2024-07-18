# Validation and Benchmarking for Citrix Delivery Solutions on vSphere

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

### Virtual Desktop Cluster

We used eight Nutanix NX-3155-G9 nodes in a cluster to host all the session hosts. The next tables contain the specifications of this cluster.

_Table: Virtual Desktop Cluster Specifications_

| Parameter | Setting |
| --- | --- |
| Block type | NX-3155-G9 |
| Number of blocks | 8 |
| Number of nodes | 8 |
| CPU type | Intel Xeon Gold 6442Y |
| Number of CPUs per node | 2 |
| Number of cores per CPU | 24 |
| Memory per node | 1.5 TB |
| Disk config per node | 4 × 1.5 TB NVME |
| Network | 2 × 25 GbE |

_Table: Nutanix Software Specifications_

| Parameter | Setting | 
| --- | --- |
| Nutanix AOS version | 6.5.5.1 LTS |
| Hypervisor version (VMware ESXi) | 7.0.3, 21930508 |
| CVM vCPU | 16 |
| CVM memory | 48 GB |
| Redundancy factor | 2 |
| Number of datastores for desktop VMs | 1 |
| Compression | On |
| Compression delay | 0 |
| Deduplication | Off |

_Table: Citrix Software Specifications_ 

| Parameter | Setting |
| --- | --- |
| Citrix VDA version | 7.2402 |
| Provisioning version | 7.2402 |

_Table: Windows Server 2022 Template Image Configuration (MCS)_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows Server 2022 21H2 (x64) (21H2-20348.2031) |
| Windows updates | 06/01/24 |
| CPU | 6 vCPU |
| Memory | 42 GB |
| NICs | 1 |
| Virtual network adapter | VMXNET 3 |
| Virtual SCSI controller 0 | LSI Logic SAS |
| Virtual disk | 80 GB |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |

_Table: Windows Server 2022 Template Image Configuration (Provisioning)_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows Server 2022 21H2 (x64) (21H2-20348.2031) |
| Windows updates | 06/01/24 |
| CPU | 6 vCPU |
| Memory | 42 GB |
| NICs | 1 |
| Virtual network adapter | VMXNET 3 |
| Virtual SCSI controller 0 | LSI Logic SAS |
| Virtual disk | 60 GB (Cache) |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Citrix Provisioning target device | 7.41.100.62 (2402 LTSR) |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |

### Nutanix Files

We deployed Nutanix Files to support the user profile repository for Citrix Profile Management Containers and tested a single file server configuration on the workload cluster.

_Table: Nutanix Files Configuration_

| Parameter | Setting |
| --- | --- |
| Platform | VMware ESXi |
| Version | 5.1 | 
| FSVM Count | 3 |
| FSVM Size | 4 vCPU, 16 GiB Memory | 
| Share Type | Distributed |
| Share Settings: Continuous Availability | Enabled |
| Share Settings: Access Based Enumeration | Disabled | 
| Share Settings: SMB Encryption | Disabled |