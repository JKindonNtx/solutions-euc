# Benchmarking and Test Environment

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

A Login Enterprise benchmark test has three phases: the boot phase, the logon phase, and the steady state. During the boot phase, we measure the time it takes to start all the VMs. Then we have a 30-minute wait time to ensure that all VMs are idle when the logon phase starts. We set the logon phase to 48 minutes, which means that all the sessions that we configured to logon do so evenly paced over 48 minutes. After a session logs on, the workload starts launching applications and performs application-specific actions such as opening, editing, and saving files. After the last session starts, the steady state begins. The steady state represents the time after all users are logged on and the system begins to normalize. In our tests, we set the steady state to 20 minutes. These 20 minutes simulate the EUC workload and typical user experience during a normal work day.

### Login Enterprise EUX Score

According to [Login Enterprise documentation](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-), the End User Experience (EUX) Score represents the performance of any Windows machine (virtual, physical, cloud, or on-premises). The score ranges from 0 to 10 and is based on the experience of one (minimum) or many users. As you add more users to your VDI platform, expect your EUX score to drop: As more users demand a greater share of a VDI system’s shared resources, performance and user experience decrease.

The default EUX measurements significantly affect the performance, especially CPU and storage. With the default measurements, the workload profile doesn't represent an EUC workload, so we modified the EUX measurements to ensure that the workload has an impact on CPU and storage that correlates to an EUC workload. You can find these modifications in the appendix. Instead of comparing EUX scores, we look at the user experience metrics, like logon times and application response times, and compare the CPU load on the cluster.

### Login Enterprise Metrics

A good user experience is defined by short logon times, short application start times, and consistency. The longer the experience is consistent, the better the result. The tests show you when the user experience is no longer consistent by increasing logon times and increasing application action times.

We quantified the evaluation using the following metrics:

-  Average logon time
-  Logon phase application metrics: The average response times of application actions
-  Steady-state application response times 
-  Maximum CPU usage 
-  CPU usage during steady state (ideally less than 85 percent)

## Test Environment

In this section, we describe the hardware we used for this reference architecture.

### Management Infrastructure Cluster

We used one Nutanix NX-3060-G7 cluster with 4 nodes to host all infrastructure and Citrix services and the Login Enterprise appliance. Active Directory services, DNS, DHCP, and the SQL Server also ran inside this cluster, which we designated the management infrastructure cluster. With four nodes we had enough resources available to host these servers. The following table shows the Citrix configuration.

_Table: Citrix Configuration_

| VM | Quantity | vCPU | Memory | Disks |
| --- | :---: | :---: | :---: | :---: |
| Cloud Connectors | 2 | 4 | 8 GB | 1 × 60 GB (OS) |
| Provisioning Servers | 2 | 8 | 16 GB | 1 × 60 GB (OS) + 1 x 150 GB (PVS Store) |
| StoreFront | 2 | 2 | 4 GB | 1 × 60 GB (OS) |
| SQL | 1 | 4 | 8 GB | 3 × 60 GB (OS, DATA, logs) |
| NetScalers | 2 | 8 | 16 | 20 GB |

### Login Enterprise Launcher Cluster

To initiate the sessions to the virtual desktops, Login Enterprise uses launcher VMs. Depending on the display protocol used, one launcher VM can host up to 25 sessions. For this reference architecture, we used one Nutanix NX-3155G-G8 cluster with four nodes to host 75 launcher VMs. Each launcher VM had 4 vCPU and 6 GB of memory.

### Virtual Desktop Cluster

Six Lenovo ThinkAgile HX665 V3 CN nodes formed the cluster to host all session hosts. The next tables contain the specifications of this cluster.

_Table: Virtual Desktop Cluster Specifications_

| Parameter | Setting |
| --- | --- |
| Block type | Lenovo ThinkAgile HX665 V3 CN |
| Number of blocks | 6 |
| Number of nodes | 6 |
| CPU type | AMD EPYC 9274F 24-Core Processor |
| Number of CPUs per node | 2 |
| Number of cores per CPU | 24 |
| Memory per node | 1.5 TB |
| Disk config per node | 6 x 1.2 TB SSD |
| Network | 2 × 25 GbE |

_Table: Nutanix Software Specifications_

| Parameter | Setting | 
| --- | --- |
| Nutanix AOS version | 6.5.5.1 LTS |
| Hypervisor Version | 20220304.478 |
| CVM vCPU | 12 |
| CVM memory | 32 GB |
| Redundancy factor | 2 |
| Number of datastores for desktop VMs | 1 |
| Datastore specifications | Compression: On; Compression delay: 0; Deduplication: Off |

_Table: Citrix Software Specifications_ 

| Parameter | Setting |
| --- | --- |
| Citrix VDA version | 7.2402 |
| Provisioning Services version | 7.2402 |

_Table: Windows Template Image Configuration Windows 11 (MCS)_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows 11 23H2 (x64) (23H2-22631.2428) |
| Windows updates | 04/15/24 |
| CPU | 3 vCPU |
| Memory | 6 GB |
| NICs | 1 |
| Virtual network adapter | Nutanix VirtIO Adapter |
| Virtual SCSI controller 0 | Nutanix VirtIO SCSI passthrough |
| Virtual disk | 64 GB |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |

_Table: Windows Template Image Configuration Windows 11 (PVS)_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows 11 23H2 (x64) (23H2-22631.2428) |
| Windows updates | 04/15/24 |
| CPU | 3 vCPU |
| Memory | 6 GB |
| NICs | 1 |
| Virtual network adapter | Nutanix VirtIO Adapter |
| Virtual SCSI controller 0 | Nutanix VirtIO SCSI passthrough |
| Virtual disk | 40 GB (Cache) |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Citrix Provisioning Services Target Device | 7.41.100.62 (2402 LTSR) |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |

_Table: Windows Template Image Configuration Windows 10_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows 10 22H2 (x64) (22H2-19045.3570) |
| Windows updates | 04/15/24 |
| CPU | 2 vCPU |
| Memory | 4 GB |
| NICs | 1 |
| Virtual network adapter | Nutanix VirtIO Adapter |
| Virtual SCSI controller 0 | Nutanix VirtIO SCSI passthrough |
| Virtual disk | 64 GB |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 2402.0.100.629 |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |