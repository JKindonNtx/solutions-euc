# Citrix Delivery Solutions on Nutanix Test Validation

This section provides the details and results of our Citrix Delivery Solutions performance tests on Nutanix NX-3155-G9 nodes with VMware vSphere. We ran each test scenario at least three times to ensure accuracy.


## Test Objectives

Our overall objective was to determine the session capacity that we could host on Nutanix using a Windows VDA image and running the Login Enterprise tests with Citrix Delivery Solutions. We tested with the Login Enterprise knowledge worker profile.

Objectives:

-  Determine the maximum number of sessions we can host on this system with the Login Enterprise knowledge worker workload while maintaining a good user experience.
-  Show the linear scalability of the Nutanix platform.
-  Show how much power (in watts) the Nutanix platform uses.
-  Show the differences between Citrix MCS and Citrix Provisioning on the Nutanix platform with VMware vSphere.
-  Identify the impacts of Nutanix Files deployed on the workload cluster hosting Citrix Profile Management Containers for user profiles.

Testing parameters:

-  We used Citrix MCS and Provisioning to deploy the Windows VMs to validate linear scalability.
-  We tested using a single, full HD screen with the default Citrix frames per second configuration. Using multiple screens or other screen resolution settings affects the results.
-  We used Citrix Profile Management Container-based profiles for our testing. We deployed a simple configuration with minimal baseline changes.

In the following section, we display information associated with testing we completed. The following table describes the test naming convention used and displayed in the graphs.

_Table: Test name matrix_

| Test Name | Operating System | Provisioning Method | Nodes | AOS Version | Hypervisor | VMs | Users | Testing Profile | Information |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ws2022_mcs_1n_A6.5.5_esxi_16V_150U_KW_6vCPU | Windows Server 2022 | Citrix MCS | 1 |6.5.5.1 | ESXi | 16 | 150 | Knowledge Worker | The machines used a 6vCPU configuration |
| ws2022_mcs_2n_A6.5.5_esxi_32V_300U_KW_6vCPU | Windows Server 2022 | Citrix MCS | 2 |6.5.5.1 | ESXi | 32 | 300 | Knowledge Worker | The machines used a 6vCPU configuration |
| ws2022_mcs_4n_A6.5.5_esxi_64V_600U_KW_6vCPU | Windows Server 2022 | Citrix MCS | 4 | 6.5.5.1 | ESXi | 64 | 600 | Knowledge Worker | The machines used a 6vCPU configuration |
| ws2022_mcs_6n_A6.5.5_esxi_96V_900U_KW_6vCPU | Windows Server 2022 | Citrix MCS | 6 | 6.5.5.1 | ESXi | 96 | 900 | Knowledge Worker | The machines used a 6vCPU configuration |
| ws2022_mcs_8n_A6.5.5_esxi_128V_1200U_KW_6vCPU | Windows Server 2022 | Citrix MCS | 8 | 6.5.5.1 | ESXi | 128 | 1200 | Knowledge Worker | The machines used a 6vCPU configuration |
| ws2022_pvs_8n_A6.5.5_esxi_128V_1200U_KW_6vCPU | Windows Server 2022 | Citrix Provisioning | 8 | 6.5.5.1 | ESXi | 128 | 1200 | Knowledge Worker | The machines used a 6vCPU configuration |
| ws2022_mcs_8n_A6.5.5_esxi_128V_1200U_KW_6vCPU_CPM | Windows Server 2022 | Citrix MCS | 8 | 6.5.5.1 | ESXi | 128 | 1200 | Knowledge Worker | The machines used a 6vCPU configuration. Citrix Profile Management on Nutanix Files was used |

## Boot Storm Simulation

We used the following hosting connection settings for our boot storm simulation test:

- Simultaneous actions (absolute): 100
- Simultaneous actions (percentage): 20 percent
- Max new actions per minute (absolute): 50

We started 128 Windows Server session hosts on eight Nutanix NX-3155-G9 nodes. The following table shows the performance results of this test.

_Table: Boot Storm Simulation: Eight-Node MCS Test_

| Measurement | Detail |
| --- | --- |
| Maximum CPU usage | 15.2% |
| Average CPU usage | 10.1% |
| Average controller IOPS | 20,375 |
| Boot time | 3.2 min. |

## Linear Scalability

The following section shows the linear scalability of the Nutanix platform. We performed the tests with one, two, four, six and eight nodes with 16 Windows Server 2022 VMs per node. The results display average timings and show good user experience in all scenarios.

### Linear Scalability in the Logon Phase

The following table and graph detail the user experience during the logon phase of the test. A lower result represents better performance.

_Table: Linear Scalability in the Logon Phase: Logon Times_

| Metric | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | :---: | :---: | :---: | :---: | :---: |
| Average logon time | 7.9 sec | 7.9 sec | 7.9 sec | 8.0 sec | 8.1 sec | 
| User profile load | 0.8 sec | 0.8 sec | 0.8 sec | 0.8 sec | 0.8 sec |
| Group policies | 1.3 sec | 1.3 sec | 1.3 sec | 1.2 sec | 1.3 sec | 
| Connection | 3.1 sec | 3.2 sec | 3.2 sec | 3.3 sec| 3.4 sec | 

![Logon times for one, two, four, six and eight nodes with 10 Windows Server 2022 VMs each](../images/RA-2003-login_times_total_logon_time_WS22_Lin.png "Linear Scalability Total Logon Times")

The following tables show the linear scalability of application performance over the test runs. A lower result represents better performance.

_Table: Linear Scalability in the Logon Phase: App Start Times_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | :---: | :---: | :---: | :---: | :---: |
| Microsoft Outlook | 1.87 sec | 1.88 sec | 1.86 sec | 1.86 sec | 1.88 sec | 
| Microsoft Word | 0.73 sec | 0.74 sec | 0.74 sec | 0.74 sec | 0.73 sec | 
| Microsoft Excel | 0.65 sec | 0.67 sec | 0.66 sec | 0.65 sec | 0.65 sec | 
| Microsoft PowerPoint | 0.66 sec | 0.68 sec | 0.67 sec | 0.67 sec | 0.66 sec | 

_Table: Linear Scalability in the Logon Phase: Specific Action Times_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | :---: | :---: | :---: | :---: | :---: |
| Microsoft Edge (Page Load) | 0.98 sec | 1.00 sec | 1.00 sec | 1.00 sec | 0.99 sec | 
| Microsoft Word (Open Doc) | 0.66 sec | 0.67 sec | 0.67 sec | 0.67 sec | 0.66 sec | 
| Microsoft Excel (Save File) | 0.33 sec | 0.33 sec | 0.33 sec | 0.33 sec | 0.33 sec | 

### Linear Scalability in the Steady State

The following tables show the user experience during the steady state of the test. A lower result represents better performance.

_Table: Linear Scalability Steady State Phase: App Start Times_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | :---: | :---: | :---: | :---: | :---: |
| Microsoft Word | 0.82 sec | 0.82 sec | 0.81 sec | 0.82 sec | 0.79 sec | 
| Microsoft Excel | 0.67 sec | 0.69 sec | 0.69 sec | 0.68 sec | 0.67 sec | 
| Microsoft PowerPoint | 0.68 sec | 0.68 sec | 0.68 sec | 0.68 sec | 0.66 sec | 

_Table: Application Performance Linear Scale Steady State Phase: Specific Action Times_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | :---: | :---: | :---: | :---: | :---: |
| Microsoft Edge (Page Load) | 1.11 sec | 1.11 sec | 1.11 sec | 1.09 sec | 1.08 sec | 
| Microsoft Word (Open Doc) | 0.71 sec | 0.72 sec | 0.73 sec | 0.72 sec | 0.70 sec | 
| Microsoft Excel (Save File) | 0.33 sec | 0.34 sec | 0.34 sec | 0.33 sec | 0.33 sec | 

## Single-Node Host Resources

The following table and graphs show a single node's host resource usage during the test (logon and steady-state phases). We tested with 150 users across 16 VMs on the node.

*Table: Single Node Host Resource Usage Metrics*

| Metric | Max | Average |
| --- | :---: | :---: |
| Host CPU usage | 91.2% | 61.5% |
| Host memory usage | 18.0% | 13.7% |
| Host power usage | 856 W | 744 W |

![CPU usage as a percentage peaked at 91.2 percent during the full test for a single NX-3155-G9 node](../images/RA-2003-host_resources_cpu_usage_WS22_SN.png "Single-Node Host CPU Usage")

![Memory usage as a percentage peaked at 18 percent during the full test for a single NX-3155-G9 node](../images/RA-2003-host_resources_memory_usage_WS22_SN.png "Single-Node Host Memory Usage")

![Power consumption in watts peaked at 856 during the full test for a single NX-3155-G9 node](../images/RA-2003-host_resources_power_usage_WS22_SN.png "Single Node Host Power Usage")

## Citrix Machine Creation Services vs. Provisioning

This section compares the Login Enterprise test results for using either Citrix MCS or Provisioning to deploy two eight-node Windows Server 2022 clusters.

### MCS vs. Provisioning System Performance

The following table provides the averages for the overall system performance results. For an explanation of CPU ready time, see [Nutanix KB 5012: Interpreting CPU Ready Values](https://portal.nutanix.com/kb/5012).

_Table: System Performance MCS vs. Provisioning: System Performance Metric Averages_

| Metric | MCS | Provisioning |
| --- | :---: | :---: | 
| CPU usage | 61.8% | 61.5% |
| CPU ready time | 0.797% | 0.926% |
| Controller read IOPS | 8,600 | 4,362 | 
| Controller write IOPS | 14,096 | 19,429 | 
| Controller latency | < 1ms | < 1ms | 

During the login phase of a test, we expect resource utilization to show an upward trend and ultimately result in peak values. During the steady state phase of a test, resource usage should both reduce and stay more consistent.

![The CPU usage for the eight-node cluster peaked at 88.2 percent (using MCS) and 88.2 percent (using Provisioning) during the login phase.](../images/RA-2003-cluster_resources_cpu_usage_WS22_MCS_vs_PVS.png "MCS vs. Provisioning: CPU Usage")

![The CPU ready times for the eight-node cluster peaked at 1.73 percent (using MCS) and 2 percent (using Provisioning) during the login phase.](../images/RA-2003-cluster_resources_cpu_ready_WS22_MCS_vs_PVS.png "MCS vs. Provisioning: CPU Ready Times")

![The controller read IOPS for the eight-node cluster peaked at 11,928 IOPS (using MCS) and 6,566 IOPS (using Provisioning) during the login phase.](../images/RA-2003-cluster_resources_controller_read_iops_WS22_MCS_vs_PVS.png "MCS vs. Provisioning: Controller Read IOPS")

![The controller write IOPS for the eight-node cluster peaked at 20,213 IOPS (using MCS) and 28,399 IOPS (using Provisioning) during the login phase.](../images/RA-2003-cluster_resources_controller_write_iops_WS22_MCS_vs_PVS.png "MCS vs. Provisioning: Controller Write IOPS")

We saw the following maximum latencies during our testing.

_Table: MCS vs. Provisioning: Cluster Controller Latencies_

| Metric | MCS | Provisioning |
| --- | :---: | :---: |
| Overall controller latency | < 1 ms | < 1 ms |
| Controller write I/O latency | < 1 ms | < 1 ms |
| Controller read I/O latency | < 1 ms  | < 1 ms |

When we used Citrix Provisioning, all controller latency figures were lower than when using MCS. We expect these results because MCS is a more disk-intense provisioning method.

![Controller I/O latency trends for one MCS-deployed and one Provisioning-deployed eight-node cluster](../images/RA-2003-cluster_resources_controller_latency_total_WS22_MCS_vs_PVS.png "MCS vs. Provisioning: Controller I/O Latency")

### MCS vs. Provisioning Logon Phase

The following table and figure show the average logon times across the test runs. A lower result represents better performance.

_Table: MCS vs. Provisioning Logon Phase: Logon Time Averages_

| Metric | MCS | Provisioning |
| --- | :---: | :---: | 
| Logon time | 8.1 sec | 8.2 sec |
| User profile load | 0.8 sec | 0.8 sec |
| Group policies | 1.3 sec | 1.3 sec |
| Connection | 3.5 sec | 3.4 sec |

![Overall logon times for the eight-node cluster peaked at 10.1 seconds (using MCS) and 10.4 seconds (using Provisioning).](../images/RA-2003-login_times_total_logon_time_WS22_MCS_vs_PVS.png "MCS vs. Provisioning: Logon Times")

The following tables show application performance details during the logon phase of the test. A lower result represents better performance.

_Table: MCS vs. Provisioning Logon Phase: App Start Times_

| Application | MCS | Provisioning | 
| --- | :---: | :---: |  
| Microsoft Outlook | 1.87 sec | 1.82 sec |
| Microsoft Word | 0.73 sec | 0.74 sec |
| Microsoft Excel | 0.65 sec | 0.65 sec |
| Microsoft PowerPoint | 0.66 sec | 0.66 sec |

_Table: MCS vs. Provisioning Logon Phase: Specific Action Times_

| Application (Action) | MCS | Provisioning | 
| --- | :---: | :---: |
| Microsoft Edge (Page Load) | 0.98 sec | 0.99 sec |
| Microsoft Word (Open Doc) | 0.66 sec | 0.65 sec |
| Microsoft Excel (Save File) | 0.33 sec | 0.33 sec |

### MCS vs. Provisioning Steady State

The following tables show the details of application performance during the steady state of the test. A lower result represents better performance.

_Table: MCS vs. Provisioning Steady State: App Start Times_

| Application | MCS | Provisioning | 
| --- | :---: | :---: |  
| Microsoft Word | 0.79 sec | 0.82 sec |
| Microsoft Excel | 0.68 sec | 0.68 sec |
| Microsoft PowerPoint | 0.67 sec | 0.67 sec |

_Table: MCS vs. Provisioning Steady State: Specific Action Times_

| Application (Action) | MCS | Provisioning | 
| --- | :---: | :---: |  
| Microsoft Edge (Page Load) | 1.09 sec | 1.10 sec |
| Microsoft Word (Open Doc) | 0.71 sec | 0.70 sec |
| Microsoft Excel (Save File) | 0.33 sec | 0.33 sec |

## Nutanix Files and Citrix Profile Containers

This section compares the Login Enterprise test results for a scenario using local profiles with a scenario using Citrix Profile Containers (CPM) hosted on Nutanix Files. Both scenarios used an eight-node cluster with MCS provisioned workloads. Nutanix Files was collocated on the same cluster as the Windows Server 2022 workloads. We compared the first run of each test to capture the profile creation impact.

When measuring the impact of Nutanix Files collocated on the same cluster as the workloads:

-  The overall cluster I/O, as measured by the Nutanix CVM (`controller_num_iops`), will show a reduction in overall Cluster IOPS. This is due to a change in the data path for Nutanix Files based I/O.
-  The Nutanix Files Server VMs will capture and display I/O data as it relates to File Serving (`iops`). These I/O operations are not a one-for-one replacement of the reduced Cluster I/O. Enabling Continuous Availability will increase the amount of I/0.
-  The Nutanix CVM measurements associated with the physical disks (`num_iops`) capture the raw impact of Nutanix Files.

To understand the impact of Nutanix Files on the workload cluster, we capture and analyze the following metrics:

-  Cluster Controller IOPS measured by the CVM `controller_num_iops`, `controller_num_write_iops` and `controller_num_read_iops` counters.
-  Nutanix Files IOPS measured by the Nutanix Files FSVM `iops`, `metadata_iops`, `read_iops` and `write_iops` counters.
-  Cluster Disk IOPS measured by the CVM `num_iops`, `num_read_iops`, and `num_write_iops` counters.

### Local Profiles vs. Nutanix Files with Citrix Profile Containers System Performance

The following table provides the averages for the overall system performance results.

_Table: System Performance Local Profiles vs. Nutanix Files with Citrix Profile Containers: System Performance Metric Averages_

| Metric | Local Profiles | Nutanix Files with CPM |
| --- | :---: | :---: | 
| CPU usage | 61.2% | 63.1% |
| CPU ready time | 0.771% | 0.975% |
| Controller read IOPS | 8,609 | 3,296 | 
| Controller write IOPS | 14,040 | 10,947 | 
| Controller latency | < 1 ms | < 1 ms | 

During the login phase of a test, we expect resource utilization to show an upward trend and ultimately result in peak values. During the steady state phase of a test, resource usage should both reduce and stay more consistent.

![The CPU usage for the eight-node cluster peaked at 88.4 percent (using local profiles) and 90.6 percent (using Nutanix Files with CPM Profiles).](../images/RA-2003-cluster_resources_cpu_usage_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: CPU Usage")

![The CPU ready times for the eight-node cluster peaked at 1.71 percent (using local profiles) and 2.03 percent (using Nutanix Files with CPM Profiles).](../images/RA-2003-cluster_resources_cpu_ready_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: CPU Ready Times")

![The controller read IOPS for the eight-node cluster peaked at 12,088 IOPS (using local profiles) and 10,872 IOPS (using Nutanix Files with CPM Profiles).](../images/RA-2003-cluster_resources_controller_read_iops_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Controller Read IOPS")

![The controller write IOPS for the eight-node cluster peaked at 20,224 IOPS (using local profiles) and 14,893 IOPS (using Nutanix Files with CPM Profiles).](../images/RA-2003-cluster_resources_controller_write_iops_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Controller Write IOPS")

We saw the following maximum latencies during our testing.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Cluster Controller Latencies_

| Metric | Local Profiles | Nutanix Files with CPM |
| --- | :---: | :---: |
| Overall controller latency | < 1 ms | < 1 ms |
| Controller write I/O latency | < 1 ms | < 1 ms |
| Controller read I/O latency | < 1 ms | 1.48 ms |

These tests included hosting Nutanix Files on the same workload cluster.

![Controller I/O latency trends for one MCS-deployed eight-node cluster using local profiles and Nutanix Files with CPM Profiles](../images/RA-2003-cluster_resources_controller_latency_total_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Controller I/O Latency")

### Local Profiles vs. Nutanix Files with Citrix Profile Containers Logon Phase

We run each test three times with Login Enterprise. On the first test, profiles are created for the first time. When using Nutanix Files with Citrix Profile Management, additional test runs use an existing profile. When using local profile configurations, the user profile is removed after each test as the machine is reset back to the default state. We used the first run data set comparison to capture the user profile creation. Subsequent logons will show a reduced footprint as profiles already exist.

The following tables show the average logon times across the test runs. A lower result represents better performance.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Logon Time Averages_

| Metric | Local Profiles | Nutanix Files with CPM |
| --- | :---: | :---: | 
| Logon time | 8.14 sec | 11.6 sec |
| User profile load | < 1 sec | < 1 sec |
| Group policies | 1.27 sec | 1.29 sec |
| Connection | 3.42 sec | 6.94 sec |

The following tables show application performance details during the logon phase of the test. A lower result represents better performance.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: App Start Times_

| Application | Local Profiles | Nutanix Files with CPM |
| --- | :---: | :---: |  
| Microsoft Outlook | 1.88 sec | 1.96 sec | 
| Microsoft Word | 0.73 sec | 0.75 sec | 
| Microsoft Excel | 0.65 sec | 0.67 sec | 
| Microsoft PowerPoint | 1.22 sec | 1.25 sec | 

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Specific Action Times_

| Application (Action) | Local Profiles | Nutanix Files with CPM |
| --- | :---: | :---: |  
| Microsoft Edge (Page Load) | 0.99 sec | 1.02 sec | 
| Microsoft Word (Open Doc) | 0.66 sec | 0.67 sec | 
| Microsoft Excel (Save File) | 0.33 sec | 0.33 sec | 

### Local Profiles vs. Nutanix Files with Citrix Profile Containers Steady State

The following tables show the details of application performance during the steady state of the test. A lower result represents better performance.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: App Start Times_

| Application (Action) | Local Profiles | Nutanix Files with CPM |
| --- | :---: | :---: |  
| Microsoft Word | 0.79 sec | 0.81 sec | 
| Microsoft Excel | 0.67 sec | 0.68 sec | 
| Microsoft PowerPoint | 0.66 sec | 0.68 sec | 

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Specific Action Times_

| Application (Action) | Local Profiles | Nutanix Files with CPM |
| --- | :---: | :---: |  
| Microsoft Edge (Page Load) | 1.08 sec | 1.12 sec | 
| Microsoft Word (Open Doc) | 0.70 sec | 0.71 sec | 
| Microsoft Excel (Save File) | 0.33 sec | 0.34 sec | 

### Nutanix Files with Citrix Profile Containers

The following tables and graphs outline the performance impacts associated with Nutanix Files specific metrics.

_Table: Nutanix Files Metrics captured at the Nutanix File Server VM level_

| Metric | Maximum | Average |
| --- | :---: | :---: |
| Nutanix Files IOPS | 11,437 | 7,118 |
| Nutanix Files latency | 4.18 ms | 2.47 ms |
| Nutanix Files throughput | 468 MB/s | 301 MB/s |

![Nutanix Files Total IOPS peaked at 11,437 IOPS on a single CA enabled share for CPM Profiles.](../images/RA-2003-nutanix_files_iops_total_WS22_Local_vs_CPM.png "Nutanix Files Total IOPS with CPM Profiles")

![Nutanix Files Total Latency peaked at 4.18 milliseconds on a single CA enabled share for CPM Profiles. ](../images/RA-2003-nutanix_files_latency_total_WS22_Local_vs_CPM.png "Nutanix Files Total Latency with CPM Profiles")

![Nutanix Files Total Throughput peaked at 468 MB/s on a single CA enabled share for CPM Profiles.](../images/RA-2003-nutanix_files_throughput_total_WS22_Local_vs_CPM.png "Nutanix Files Total Throughput CPM Profiles")

The following tables and graphs outline the performance impacts on the Cluster Disks when Nutanix Files is deployed, and Citrix Profile Containers are enabled. 

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Nutanix Cluster Disk metrics (Averages)_

| Metric | Local Profiles | Nutanix Files with CPM | 
| --- | :---: | :---: |  
| Cluster Disk Total IOPS | 2,516 | 3,547 |
| Cluster Disk Read IOPS | 2,212 | 2,739 |
| Cluster Disk Write IOPS | 304 | 807 |

![Cluster Disk Total I/O comparison using local profiles and Nutanix Files with CPM Profiles. The Total I/O peaked at 12,810 for the local profile test, and 16,585 for the CPM with Files test.](../images/RA-2003-cluster_disk_iops_total_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Cluster Disk Total I/O Disk")

![Cluster Disk Read I/O comparison using local profiles and Nutanix Files with CPM Profiles. The Read I/O peaked at 12,431 for the local profile test, and 16,183 for the CPM with Files test.](../images/RA-2003-cluster_disk_iops_read_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Cluster Disk Read I/O Disk")

![Cluster Disk Write I/O comparison using local profiles and Nutanix Files with CPM Profiles. The Write I/O peaked at 457 for the local profile test, and 1,518 for the CPM with Files test.](../images/RA-2003-cluster_disk_iops_write_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Cluster Disk Write I/O Disk")

### Nutanix Files Citrix Profile Containers Advanced Information

CPM containers have a range of advanced functionalities and features that can impact performance. You should consult further guidance on [Citrix Profile Management on Nutanix Files](https://portal.nutanix.com/page/documents/solutions/details?targetId=TN-2002-Citrix-User-Profile-Management-on-Nutanix:TN-2002-Citrix-User-Profile-Management-on-Nutanix) for additional performance impacts and considerations.

The appendix section of this document includes the CPM container settings that were used in testing.

## Results Summary

Our results show that if you use MCS-provisioned or Provisioning-streamed servers to linearly scale the Citrix Delivery Solutions on Nutanix, the system maintains the same average response times regardless of how many nodes you have. 

Test results summary:

-  The overall cluster CPU usage was similar between MCS and Citrix Provisioning.
-  The Cluster Read IOPS was higher with MCS, but Write IOPS was higher with Citrix Provisioning. We expect these effects due to the write-heavy nature of the Provisioning filter driver.
-  Logon Times were almost identical with both MCS and Citrix Provisioning.
-  Application response times were consistent across both MCS and Citrix Provisioning.
-  With Nutanix Files housed on the workload cluster, there was around a two percent overall CPU increase on the cluster.
-  The cluster IO profile reported a reduced IO footprint for both read and write IOPS at the cluster level when hosting Nutanix Files. This is due to Nutanix Files providing caching capability, and how Files ultimately writes IO to the cluster disks.
Overall first logon times were higher with Citrix Profile Containers on Nutanix files due to the first profile creation tax. Subsequent logon times are lower
-  Application response times were similar across local profiles and Citrix Profile Containers. 
-  The tested File Server VM instance size was sufficient to handle the workload.