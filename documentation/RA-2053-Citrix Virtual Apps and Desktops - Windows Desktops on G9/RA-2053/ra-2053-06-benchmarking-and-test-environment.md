# Citrix Virtual Apps and Desktops Benchmarking and Test Environment

The following sections describe the benchmarking method and test environment used in this reference architecture.

## Login Enterprise

[Login VSI](http://www.loginvsi.com/) provides the industry-standard virtual desktop testing platform, Login Enterprise. It's designed to help organizations benchmark and validate the performance and scalability of their virtual desktop solutions. With Login Enterprise, IT teams can reliably measure the impact of changes to their virtual desktop infrastructure on end-user experience and identify performance issues before they impact the business. Login Enterprise uses synthetic user workloads to simulate real-world user behavior, so IT teams can measure the responsiveness and performance of their virtual desktop environment under different scenarios. Login Enterprise comes with two built-in workloads: The [task worker](https://support.loginvsi.com/hc/en-us/articles/6949195003932-Task-Worker-Out-of-the-box) and [knowledge worker](https://support.loginvsi.com/hc/en-us/articles/6949191203740-Knowledge-Worker-Out-of-the-box). 

<note>
You can't compare either of the Login Enterprise workloads to the workloads included in the previous edition of Login VSI.
</note>

The following table includes both workloads available in Login Enterprise.

_Table: Login Enterprise Workloads_

| **Task Worker** | **Knowledge Worker** |
| --- | --- | 
| Light | Medium | 
| 2 vCPU | 2-4 vCPU |
| 2-3 apps | 4-6 apps |
| No video | 720p video |

### Login Enterprise test phases

A Login Enterprise benchmark test has three phases, the boot phase, the logon phase, and the steady state phase. During the boot phase, we measure the time it takes to boot all the virtual machines. Then we have a wait time of 30 minutes to make sure that all virtual machines are idle when the logon phase starts. We set the logon phase to 48 minutes. Which means that during that 48 minutes, all the sessions we configured to logon, will logon evenly spread over 48 minutes. After a session logs on, the workload will start with launching applications and perform application specific actions, like open files, edit files and save files. After the last session has started, the steady state phase begins. The steady state represents the time after all users have logged and the system has begun to normalize. In our tests, we have set the steady state to 20 minutes. These 20 minutes simulate the EUC workload during a normal working day and is representative for the user experience.

### Login Enterprise EUX Score

Login Enterprise performs mini-benchmark tests (EUX measurements) during the workload. These measurements are used to calculate an EUX score. According to [Login Enterprise documentation](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-), the EUX (End User Experience) score represents the performance of any Windows machine (virtual, physical, cloud, or on-premises). The score ranges from 0 to 10 and is based on the experience of one (minimum) or many users.

<note>
As you add more users to your VDI platform, expect your EUX score to drop. As more users demand a greater share of a VDI system’s shared resources, performance and user experience decrease.
</note>

The default EUX measurements have big impact on the performance. especially on CPU and storage. With these default measurements, the workload profile becomes no longer representative for an EUC workload. For this reason, we modified the EUX measurements to make sure that the workload has an impact on CPU and storage that correlates to an EUC workload. These modifications can be found in the appendix. Instead at comparing EUX scores, we look at the user experience metrics, like logon times and application response times. We also compare the CPU load on the cluster.

### Login Enterprise Metrics

A good user experience is defined by short logon times, short application start times, and consistency. The longer the experience is consistent, the better the result. The tests show you when the user experience is no longer consistent by increasing logon times and increasing application action times.
We quantified the evaluation using the following metrics:

| **Metric** | **Description** |
| --- | --- | 
| Average logon time | The average user logon time. |
| Logon phase application metrics | The average response times of application actions. |
| Steady State Application response times | The average response times of application actions during steady state. |
| Maximum CPU usage | The maximum observed CPU usage during the test. |
| CPU usage during steady state | The average CPU usage during the steady state. |

<note>
Ideal CPU usage during steady state  < 85%
</note>

## Test Environment

In this section you can read about the hardware we used for this reference architecture.

### Management Infrastructure Cluster

We used one Nutanix NX-3060-G7 cluster with four nodes to host all infrastructure and Citrix services and the Login Enterprise appliance. Active Directory services, DNS, DHCP, and the SQL Server also ran inside this cluster, which we designated the management infrastructure cluster. With four nodes we had enough resources available to host these servers. The following table shows the Citrix configuration.

_Table: Citrix Configuration_

| VM | Quantity | vCPU | Memory | Disks |
| --- | :---: | :---: | :---: | :---: |
| Delivery Controllers | 2 | 4 | 8 GB | 1 × 60 GB (OS) |
| StoreFront | 2 | 2 | 4 GB | 1 × 60 GB (OS) |
| SQL | 1 | 4 | 8 GB | 3 × 60 GB (OS, DATA, logs) |

### Login Enterprise Launcher Cluster

To initiate the sessions to the virtual desktops, Login Enterprise uses launcher VMs. Depending on the display protocol used, one launcher VM can host up to 25 sessions. For this reference architecture, we used one Nutanix NX-3060-G7 cluster with four nodes to host 75 launcher VMs. Each launcher VM had 4 vCPU and 6 GB of memory.

### Workload Cluster

Eight Nutanix NX-3155-G9 nodes formed the cluster to host all the test workloads. The next tables contain the specifications of this cluster.

_Table: Virtual Desktop Cluster Specifications_

| Parameter | Setting |
| --- | --- |
| Block type | Nutanix NX-3155-G9 |
| Number of blocks | 8 |
| Number of nodes | 8 |
| CPU type | Xeon Gold 6442Y @ 2.6 Ghz |
| Number of CPUs per node | 2 |
| Number of cores per CPU | 24 |
| Memory per node | 1.5 TB |
| Disk config per node | 4 x 1.92 TB NVMe |
| Network | 2 × 25 GbE |

_Table: Nutanix Software Specifications_

| Parameter | Setting | 
| --- | --- |
| Nutanix AOS version | 6.5.4.5 |
| CVM vCPU | 12 |
| CVM memory | 32 GB |
| Redundancy factor | 2 |
| Number of datastores for desktop VMs | 1 |
| Datastore specifications | Compression: On; Compression delay: 0; Deduplication: Off |

_Table: Citrix Software Specifications_ 

| Parameter | Setting |
| --- | --- |
| Citrix Virtual Apps and Desktops version | 7.2203 |
| Provisioning Services version | 7.2203 |

_Table: Windows OS Template Image Configuration_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows 10 22H2 & Windows 11 23H2 (x64)|
| Windows updates | October 2023 |
| CPU | 2 vCPU |
| Memory | 4 GB |
| NICs | 1 |
| Virtual network adapter | VirtIO Adapter |
| Virtual SCSI controller 0 | LSI Logic |
| Virtual disk | 80 GB |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Microsoft Edge Browser, Microsoft Office 2021 (x64) |
| Citrix Virtual Desktop Agent | 7.2203 |
| Citrix Provisioning Services Target Device | 7.2203 |
| Optimizations | Citrix Optimizer; custom optimizations to the default user profile |