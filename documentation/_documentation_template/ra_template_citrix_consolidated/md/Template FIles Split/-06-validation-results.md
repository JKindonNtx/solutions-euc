# Citrix Delivery Solutions on Nutanix Test Validation

This section provides the details and results of our Citrix delivery solutions performance tests on Lenovo ThinkAgile HX665 V3 CN nodes with Nutanix AHV. We ran each test scenario at least three times to ensure accuracy.

<!--TEMPLATE CONTENT: Validate Above-->

## Test Objectives

Our overall objective was to determine the session capacity that we could host on Nutanix using a Windows VDA image and running the Login Enterprise tests with Citrix delivery solutions. We tested with the Login Enterprise knowledge worker profile.

Objectives:

-  Determine the maximum number of sessions that we can host on this system with the Login Enterprise knowledge worker workload while maintaining a good user experience.
-  Show the linear scalability of the Nutanix platform.
-  Show how much power (in watts) the Nutanix platform uses.
-  Show the differences between Citrix MCS and Citrix Provisioning on the Nutanix platform.

Testing parameters:

-  We used Citrix MCS and Provisioning to deploy the Windows VMs to validate linear scalability.
-  We tested using a single, full HD screen with the default Citrix frames per second configuration. Using multiple screens or other screen resolution settings affects the results.
-  `Template: Validate_this` We used Citrix Profile Management Container–based profiles for our testing. We deployed a simple configuration with minimal baseline changes.

In the following section, we display information associated with the testing we completed. The following table describes the test naming convention used and displayed in the graphs.

_Table: Test Name Matrix for `Knowledge Worker Profile on Windows Server 2022 on vSphere`_

| Test Name | Provisioning Method | Nodes | AOS Version| VMs | Users | Information |
| --- | --- | --- | --- | --- | --- | --- |
| ws2022_amd_mcs_1n_A6.5.5_AHV_10V_180U_KW | Citrix MCS | 1 | 6.5.5 | 10 | 180 | Testing was completed on AMD processors `Template: Validate_this` |
| ws2022_amd_mcs_2n_A6.5.5_AHV_20V_360U_KW | Citrix MCS | 2 | 6.5.5 | 20 | 360 | Testing was completed on AMD processors `Template: Validate_this` |
| ws2022_amd_mcs_4n_A6.5.5_AHV_40V_720U_KW | Citrix MCS | 4 | 6.5.5 | 40 | 720 | Testing was completed on AMD processors `Template: Validate_this` |
| ws2022_amd_mcs_6n_A6.5.5_AHV_60V_1080U_KW | Citrix MCS | 6 | 6.5.5 | 60 | 1080 | Testing was completed on AMD processors `Template: Validate_this` |
| ws2022_amd_pvs_6n_A6.5.5_AHV_60V_1080U_KW | Citrix Provisioning | 6 | 6.5.5 | 60 | 1080 | Testing was completed on AMD processors `Template: Validate_this` |

<!--TEMPLATE CONTENT: Validate Above-->

## Boot Storm Simulation

We used the following hosting connection settings for our boot storm simulation test:

- Simultaneous actions (absolute): 100
- Simultaneous actions (percentage): 20 percent
- Max new actions per minute (absolute): 50

We started 60 Windows Server session hosts on six Lenovo ThinkAgile HX665 V3 CN nodes. The following table shows the performance results of these tests.
<!--TEMPLATE CONTENT: Validate Above-->
_Table: Boot Storm Simulation: Six-Node MCS Test_

| Measurement | Detail |
| --- | --- |
| Maximum CPU usage | `TBD`% |
| Average CPU usage | `TBD`% |
| Average controller IOPS | `TBD` |
| Boot time | `TBD` min. |

<!--TEMPLATE CONTENT: Validate Above-->

### Linear Scalability in the Logon Phase

The following table and graph detail the user experience during the logon phase of the test. A lower result represents better performance.

_Table: Linear Scalability in the Logon Phase: Logon Time Averages_

| Metric | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: | 
| Average logon time | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| User profile load | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Group policies | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Connection | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 

<!--TEMPLATE CONTENT: Validate Above-->

![Logon times for one, two, four, and six nodes with 10 Windows Server 2022 VMs each](../images/RA-TBD-login_times_total_logon_time_WS22_Lin.png "Linear Scalability Total Logon Times")

<!--TEMPLATE CONTENT: Validate Above-->

The following tables show the linear scalability of application performance over the test runs. A lower result represents better performance.

_Table: Linear Scalability in the Logon Phase: App Start Times_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: |
| Microsoft Outlook | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Word | `TBD` sec | `TBD` sec | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec | `TBD` sec | `TBD` sec | 

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Linear Scalability in the Logon Phase: Specific Action Times_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: |
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 

<!--TEMPLATE CONTENT: Validate Above-->

### Linear Scalability in the Steady State

The following tables show the user experience during the steady state of the test. A lower result represents better performance.

_Table: Linear Scalability Steady State Phase: App Start Times_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: |
| Microsoft Word | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Excel | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft PowerPoint | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 

<!--TEMPLATE CONTENT: Validate Above-->

_Table: Application Performance Linear Scale Steady State Phase: Specific Action Times_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | :---: | :---: | :---: | :---: |
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec |

<!--TEMPLATE CONTENT: Validate Above--> 

## Single-Node Host Resources

The following table and graphs show a single node's host resource usage during the test (logon and steady-state phases). We tested with 180 users per VM and 10 VMs on the node.

<!--TEMPLATE CONTENT: Validate Above--> 

*Table: Single Node Host Resource Usage Metrics*
| Metric | Max | Average |
| --- | :---: | :---: |
| Host CPU usage | `TBD`% | `TBD`% |
| Host memory usage | `TBD`% | `TBD`% |
| Host power usage | `TBD` W | `TBD` W |

<!--TEMPLATE CONTENT: Validate Above--> 

![CPU usage as a percentage peaked at 81.7 during the full test for a single Lenovo ThinkAgile HX665 V3 CN node](../images/RA-TBD-host_resources_cpu_usage_WS22_sn.png "Single-Node Host CPU Usage") 

<!--TEMPLATE CONTENT: Validate Above--> 

![Memory usage as a percentage peaked at 31.5 during the full test for a single Lenovo ThinkAgile HX665 V3 CN node](../images/RA-TBD-host_resources_memory_usage_WS22_sn.png "Single-Node Host Memory Usage") 

<!--TEMPLATE CONTENT: Validate Above--> 

![Power consumption in watts peaked at 777 during the full test for a single Lenovo ThinkAgile HX665 V3 CN node](../images/RA-TBD-host_resources_power_usage_WS22_sn.png "Host Resources Power Usage in Watts during the full test run")

<!--TEMPLATE CONTENT: Validate Above--> 

## Citrix Machine Creation Services vs. Provisioning

This section compares the Login Enterprise test results for using either Citrix MCS or Provisioning to deploy Windows Server 2022 workloads.

<!--TEMPLATE CONTENT: Validate Above--> 

### MCS vs. Provisioning System Performance

The following table provides the averages for the overall system performance results. For an explanation of CPU ready time, see [Nutanix KB 5012: Interpreting CPU Ready Values](https://portal.nutanix.com/kb/5012).

_Table: System Performance MCS vs. Provisioning: System Performance Metric Averages_

| Metric | MCS | Provisioning |
| --- | :---: | :---: | 
| CPU usage | `TBD`% | `TBD`% |
| CPU ready time | `TBD`% | `TBD`% |
| Controller read IOPS | `TBD` | `TBD` | 
| Controller write IOPS | `TBD` | `TBD` | 
| Controller latency | < `TBD` ms | < `TBD` ms | 

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU usage for the six-node cluster peaked at 59.1 percent (MCS-deployed) and 58.8 percent (Provisioning-deployed).](../images/RA-TBD-cluster_resources_cpu_usage_WS22_MCS_PVS.png "MCS vs. Provisioning: CPU Usage")

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU ready times for the six-node cluster peaked at 0.979 percent (MCS-deployed) and 1.17 percent (Provisioning-deployed).](../images/RA-TBD-cluster_resources_cpu_ready_WS22_MCS_PVS.png "MCS vs. Provisioning: CPU Ready Times")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller read IOPS for the six-node cluster peaked at just over 9,600 IOPS (MCS-deployed) and just over 5,600 IOPS (Provisioning-deployed).](../images/RA-TBD-cluster_resources_controller_read_iops_WS22_MCS_PVS.png "MCS vs. Provisioning: Controller Read IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller write IOPS for the six-node cluster peaked at just over 15,000 IOPS (MCS-deployed) and almost 25,000 IOPS (Provisioning-deployed).](../images/RA-TBD-cluster_resources_controller_write_iops_WS22_MCS_PVS.png "MCS vs. Provisioning: Controller Write IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

We saw the following maximum latencies during our testing.

_Table: MCS vs. Provisioning: Cluster Controller Latencies_

| Metric | MCS | Provisioning |
| --- | :---: | :---: |
| Overall controller latency | `TBD` ms | < `TBD` ms |
| Controller write I/O latency | `TBD` ms | < `TBD` ms |
| Controller read I/O latency | `TBD` ms | < `TBD` ms |

<!--TEMPLATE CONTENT: Validate Above--> 

![Controller I/O latency trends for one MCS-deployed and one Provisioning-deployed six-node cluster](../images/RA-TBD-cluster_resources_controller_latency_WS22_MCS_PVS.png "MCS vs. Provisioning: Controller I/O Latency")

<!--TEMPLATE CONTENT: Validate Above--> 

![Controller I/O latency trends for one MCS-deployed and one Provisioning-deployed six-node cluster](../images/RA-TBD-cluster_resources_controller_latency_WS22_MCS_PVS.png "MCS vs. Provisioning: Controller I/O Latency")

<!--TEMPLATE CONTENT: Validate Above--> 

### MCS vs. Provisioning Logon Phase

The following table and figure show the average logon times across the test runs. A lower result represents better performance.

_Table: MCS vs. Provisioning Logon Phase: Logon Time Averages_

| Metric | MCS | Provisioning |
| --- | :---: | :---: | 
| Average logon time | `TBD` sec | `TBD` sec |
| User profile load | `TBD` sec | `TBD` sec | 
| Group policies | `TBD` sec | `TBD` sec |
| Connection | `TBD` sec | `TBD` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

![Overall logon times for the six-node cluster peaked at 11.4 seconds (MCS-deployed) and 13.8 seconds (Provisioning-deployed).](../images/RA-TBD-login_times_total_logon_time_WS22_MCS_PVS.png "MCS vs. Provisioning: Logon Times")

<!--TEMPLATE CONTENT: Validate Above--> 

The following tables show application performance details during the logon phase of the test. A lower result represents better performance.

_Table: MCS vs. Provisioning Logon Phase: App Start Times_

| Application | MCS | Provisioning | 
| --- | :---: | :---: |  
| Microsoft Outlook | `TBD` sec | `TBD` sec |
| Microsoft Word | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: MCS vs. Provisioning Logon Phase: Specific Action Times_

| Application (Action) | MCS | Provisioning | 
| --- | :---: | :---: |
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec |
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec |
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

### MCS vs. Provisioning Steady State

The following tables show application performance details during the steady state of the test. A lower result represents better performance.

_Table: MCS vs. Provisioning Steady State: App Start Times_

| Application | MCS | Provisioning | 
| --- | :---: | :---: |  
| Microsoft Word | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: MCS vs. Provisioning Steady State: Specific Action Times_

| Application (Action) | MCS | Provisioning | 
| --- | :---: | :---: |  
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec |
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec |
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

## Windows 10 vs. Windows 11

<!--TEMPLATE CONTENT: Validate Above. Is this a Desktop or Server RA. Delete if Server--> 

This section compares the Login Enterprise comparison test results for an eight-node cluster running Windows 10 and Windows 11. We kept Windows 10 to the same specification that we have previously used in Nutanix Reference Architectures.

<!--TEMPLATE CONTENT: Validate Above--> 

### Windows 10 vs. Windows 11 System Performance

The following table shows the averages for the overall system performance results.

_Table: Windows 10 vs. Windows 11: System Performance Metric Averages_

| Metric | Windows 10 | Windows 11 |
| --- | :---: | :---: | 
| CPU usage | `TBC`% | `TBC`% |
| CPU ready time | `TBC`% | `TBC`% | 
| Controller read IOPS | `TBC` | `TBC` | 
| Controller write IOPS | `TBC` | `TBC` | 
| Controller latency | < `TBC` ms | < `TBC` ms | 

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU usage for the eight-node cluster peaked at 90.4 percent (Windows 10) and 87.2 percent (Windows 11). Windows 11 showed higher CPU usage during the boot phase than Windows 10, and lower CPU usage during the steady-state phase.](../images/RA-TBD-cluster_resources_cpu_usage_W10_v_W11.png "Windows 10 vs. Windows 11: CPU Usage") 

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU ready times for the eight-node cluster peaked at 1.16 percent (Windows 10) and 3.76 percent (Windows 11).](../images/RA-2022-cluster_resources_cpu_ready_W10_v_W11.png "Windows 10 vs. Windows 11: CPU Ready Time")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller read IOPS for the eight-node clusters peaked at 17,789 IOPS (Windows 10) and 18,592 IOPS (Windows 11).](../images/RA-2022-cluster_resources_controller_read_iops_W10_v_W11.png "Windows 10 vs. Windows 11: Controller Read IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller write IOPS for the eight-node clusters peaked at nearly 18,000 IOPS (Windows 10) and 20,000 IOPS (Windows 11).](../images/RA-2022-cluster_resources_controller_write_iops_W10_v_W11.png "Windows 10 vs. Windows 11: Controller Write IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Windows 10 vs. Windows 11: Maximum Cluster Controller Latencies_

| Metric | Windows 10 | Windows 11 |
| --- | :---: | :---: |
| Overall controller I/O latency | `TBC` ms | `TBC` ms |
| Controller write I/O latency | `TBC` ms | `TBC` ms |
| Controller read I/O latency | `TBC` ms | `TBC` ms |

![Controller latency trends for one eight-node cluster running Windows 10 and one running Windows 11. Windows 11 showed slightly higher latency figures when compared with Windows 10.](../images/RA-2022-cluster_resources_controller_latency_W10_v_W11.png "Windows 10 vs. Windows 11: Controller Latency")

<!--TEMPLATE CONTENT: Validate Above--> 

### Windows 10 vs. Windows 11 Logon Phase

The following table and figure show the average logon times during the logon phase of the test. A lower result represents better performance.

_Table: Windows 10 vs. Windows 11 Logon Phase: Logon Time Averages_

| Metric | Windows 10 | Windows 11 |
| --- | :---: | :---: |
| Logon time | `TBC` sec | `TBC` sec | 
| User profile load | `TBC` | `TBC` sec |
| Group policies | `TBC` sec | `TBC` sec | 
| Connection | `TBC` sec | `TBC` sec | 

![Overall logon times for the eight-node cluster peaked at 8.06 seconds (Windows 10) and 7.92 seconds (Windows 11).](../images/RA-2022-login_times_total_logon_time_W10_v_W11.png "Windows 10 vs. Windows 11: Logon Times")

<!--TEMPLATE CONTENT: Validate Above--> 

The following tables show application performance details during the logon phase of the test. A lower result represents better performance.

_Table: Windows 10 vs. Windows 11 Logon Phase: App Start Times_

| Application | Windows 10 | Windows 11 | 
| --- | :---: | :---: | 
| Microsoft Outlook | `TBC` sec | `TBC` sec | 
| Microsoft Word | `TBC` sec | `TBC` sec |  
| Microsoft Excel | `TBC` sec | `TBC` sec |
| Microsoft PowerPoint | `TBC` sec | `TBC` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Windows 10 vs. Windows 11 Logon Phase: Specific Action Times_

| Application (Action) | Windows 10 | Windows 11 | 
| --- | :---: | :---: | 
| Microsoft Edge (Page Load) | `TBC` sec | `TBC` sec | 
| Microsoft Word (Open Doc) | `TBC` sec | `TBC` sec | 
| Microsoft Excel (Save File) | `TBC` sec | `TBC` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

### Windows 10 vs. Windows 11 Steady State

The following tables show application performance details during the steady state of the test. A lower result represents better performance.

_Table: Windows 10 vs. Windows 11 Steady State: App Start Times_

| Application | Windows 10 | Windows 11 | 
| --- | :---: | :---: | 
| Microsoft Word | `TBC` sec | `TBC` sec | 
| Microsoft Excel | `TBC` sec | `TBC` sec | 
| Microsoft PowerPoint | `TBC` sec | `TBC` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Windows 10 vs. Windows 11 Steady State: Specific Action Times_

| Application (Action) | Windows 10 | Windows 11 | 
| --- | :---: | :---: | 
| Microsoft Edge (Page Load) | `TBC` sec | `TBC` sec | 
| Microsoft Word (Open Doc) | `TBC` sec | `TBC` sec | 
| Microsoft Excel (Save File) | `TBC` sec | `TBC` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

## Nutanix Files and Citrix Profile Containers

<!--TEMPLATE CONTENT: Validate Above--> 

This section compares the Login Enterprise test results for a scenario using local profiles with a scenario using Citrix Profile Containers (CPM) hosted on Nutanix Files. Both scenarios used an eight-node cluster with MCS provisioned workloads. Nutanix Files was collocated on the same cluster as the Windows Server 2022 workloads. We compared the first run of each test to capture the profile creation impact.

When measuring the impact of Nutanix Files collocated on the same cluster as the workloads, we found the following:

-  The overall cluster I/O, as measured by the Nutanix CVM (`controller_num_iops`), shows a reduction in overall cluster IOPS due to a change in the data path for Nutanix Files–based I/O.
-  The Nutanix FSVMs capture and display I/O data as it relates to file serving (`iops`). These I/O operations aren't a one-for-one replacement of the reduced cluster I/O.
-  Enabling continuous availability increases the amount of I/0.
-  The Nutanix CVM measurements associated with the physical disks (`num_iops`) capture the raw impact of Nutanix Files.

To understand the impact of Nutanix Files on the workload cluster, we capture and analyze the following metrics:

-  Cluster controller IOPS measured by the CVM `controller_num_iops`, `controller_num_write_iops`, and `controller_num_read_iops` counters
-  Nutanix Files IOPS measured by the Nutanix Files FSVM `iops`, `metadata_iops`, `read_iops`, and `write_iops` counters
-  Cluster disk IOPS measured by the CVM `num_iops`, `num_read_iops`, and `num_write_iops` counters

### Local Profiles vs. Nutanix Files with Citrix Profile Containers System Performance

The following table provides the averages for the overall system performance results. For an explanation of CPU ready time, see [Nutanix KB 5012: Interpreting CPU Ready Values](https://portal.nutanix.com/kb/5012).

_Table: System Performance Local Profiles vs. Nutanix Files with Citrix Profile Containers: System Performance Metric Averages_

| Metric | Local Profiles | Profile Containers  |
| --- | :---: | :---: | 
| CPU usage | `TBD`% |`TBD`% |
| CPU ready time | `TBD`% |`TBD`% |
| Controller read IOPS | `TBD` | `TBD` | 
| Controller write IOPS | `TBD` | `TBD` | 
| Controller latency | `TBD` ms | `TBD` ms | 

<!--TEMPLATE CONTENT: Validate Above--> 

During the login phase of a test, we expect resource usage to show an upward trend and ultimately result in peak values. During the steady state phase of a test, resource usage should both reduce and stay more consistent.

![The CPU usage for the eight-node cluster peaked at 86.4 percent (using local profiles) and 90.2 percent (using Nutanix Files with Citrix Profiles) during the login phase.](../images/RA-2003-cluster_resources_cpu_usage_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Citrix Profiles: CPU Usage")

<!--TEMPLATE CONTENT: Validate Above--> 

![The CPU ready times for the eight-node cluster peaked at 1.68 percent (using local profiles) and 2.25 percent (using Nutanix Files with Citrix Profiles) during the login phase.](../images/RA-2003-cluster_resources_cpu_ready_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Citrix Profile Containers: CPU Ready Times")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller read IOPS for the eight-node cluster peaked at 11,719 IOPS (using local profiles) and 11,368 IOPS (using Nutanix Files with Citrix Profiles) during the login phase.](../images/RA-2003-cluster_resources_controller_read_iops_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Citrix Profile Containers: Controller Read IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

![The controller write IOPS for the eight-node cluster peaked at 19,794 IOPS (using local profiles) and 14,844 IOPS (using Nutanix Files with Citrix Profiles) during the login phase.](../images/RA-2003-cluster_resources_controller_write_iops_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Citrix Profile Containers: Controller Write IOPS")

<!--TEMPLATE CONTENT: Validate Above--> 

We saw the following maximum latencies during our testing.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Cluster Controller Latencies_

| Metric | Local Profiles | Profile Containers  |
| --- | :---: | :---: |
| Overall controller latency | `TBD` ms | `TBD` ms |
| Controller write I/O latency | `TBD` ms | `TBD` ms |
| Controller read I/O latency | < `TBD` ms | `TBD` ms |

These tests included hosting Nutanix Files on the same workload cluster.

<!--TEMPLATE CONTENT: Validate Above--> 

![Controller I/O latency trends for one MCS-deployed eight-node cluster using local profiles and Nutanix Files with Profiles](../images/RA-2003-cluster_resources_controller_latency_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with Profiles: Controller I/O Latency")

<!--TEMPLATE CONTENT: Validate Above--> 

### Local Profiles vs. Nutanix Files with Citrix Profile Containers Logon Phase

We run each test three times with Login Enterprise. On the first test, Citrix Profile Management creates the profiles for the first time. If you use Nutanix Files with Citrix Profile Management, additional test runs use an existing profile. If you use local profile configurations, when the machine resets back to the default state after each test, it removes the user profile. We used the first-run data set to capture the impact of user profile creation. Subsequent logons show a reduced footprint because the profiles already exist.

The following tables show the average logon times across the test runs. A lower result represents better performance.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Logon Time Averages_

| Metric | Local Profiles | Profile Containers  |
| --- | :---: | :---: | 
| Average logon time | `TBD` sec | `TBD` sec |
| User profile load | `TBD` sec | `TBD` sec | 
| Group policies | `TBD` sec | `TBD` sec |
| Connection | `TBD` sec | `TBD` sec | 

<!--TEMPLATE CONTENT: Validate Above--> 

The following tables show application performance details during the logon phase of the test. A lower result represents better performance.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: App Start Times_

| Application | Local Profiles | Profile Containers |
| --- | :---: | :---: |  
| Microsoft Outlook | `TBD` sec | `TBD` sec |
| Microsoft Word | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Specific Action Times_

| Application (Action) | Local Profiles | Profile Containers |
| --- | :---: | :---: |  
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec | `TBD` sec | `TBD`sec | 
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec |
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

### Local Profiles vs. Nutanix Files with Citrix Profile Containers Steady State

The following tables show the details of application performance during the steady state of the test. A lower result represents better performance.

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: App Start Times_

| Application (Action) | Local Profiles | Profile Containers |
| --- | :---: | :---: |  
| Microsoft Word | `TBD` sec | `TBD` sec |
| Microsoft Excel | `TBD` sec | `TBD` sec |
| Microsoft PowerPoint | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Containers: Specific Action Times_

| Application (Action) | Local Profiles | Profile Containers |
| --- | :---: | :---: |  
| Microsoft Edge (Page Load) | `TBD` sec | `TBD` sec |
| Microsoft Word (Open Doc) | `TBD` sec | `TBD` sec |
| Microsoft Excel (Save File) | `TBD` sec | `TBD` sec |

<!--TEMPLATE CONTENT: Validate Above--> 

### Nutanix Files with Citrix Profile Containers

The following tables and graphs outline the performance impacts associated with Nutanix Files specific metrics.

_Table: Nutanix Files Metrics at the Nutanix FSVM level_

| Metric | Maximum | Average |
| --- | :---: | :---: |
| Nutanix Files IOPS | `TBD` | `TBD` |
| Nutanix Files latency | `TBD` ms | `TBD` ms |
| Nutanix Files throughput | `TBD` MB/s | `TBD` MB/s |

<!--TEMPLATE CONTENT: Validate Above--> 

![Nutanix Files Total IOPS peaked at 12,107 IOPS on a single CA enabled share for Citrix Profiles.](../images/RA-2003-nutanix_files_iops_total_WS22_Local_vs_CPM.png "Nutanix Files Total IOPS with Citrix Profiles")

<!--TEMPLATE CONTENT: Validate Above--> 

![Nutanix Files Total Latency peaked at 15.0 milliseconds on a single CA enabled share for Citrix Profiles. ](../images/RA-2003-nutanix_files_latency_total_WS22_Local_vs_CPM.png "Nutanix Files Total Latency with Citrix Profiles")

<!--TEMPLATE CONTENT: Validate Above--> 

![Nutanix Files Total Throughput peaked at 489 MB/s on a single CA enabled share for Citrix Profiles.](../images/RA-2003-nutanix_files_throughput_total_WS22_Local_vs_CPM.png "Nutanix Files Total Throughput Citrix Profiles")

<!--TEMPLATE CONTENT: Validate Above--> 

The following tables and graphs outline the performance impacts on the Cluster Disks when Nutanix Files is deployed, and Citrix Profile Containers are enabled. 

_Table: Local Profiles vs. Nutanix Files with Citrix Profile Management Containers: Nutanix Cluster Disk metrics (Averages)_

| Metric | Local Profiles | Profile Containers | 
| --- | :---: | :---: |  
| Cluster disk total IOPS | `TBD` | `TBD` |
| Cluster disk read IOPS | `TBD` | `TBD` |
| Cluster disk write IOPS | `TBD` | `TBD` |

<!--TEMPLATE CONTENT: Validate Above--> 

![Cluster Disk Total I/O comparison using local profiles and Nutanix Files with CPM Profiles. The Total I/O peaked at 15,776 for the local profile test, and 17,172 for the Nutanix Files with Citrix Profile Containers test.](../images/RA-2003-cluster_disk_iops_total_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Cluster Disk Total I/O Disk")

<!--TEMPLATE CONTENT: Validate Above--> 

![Cluster Disk Read I/O comparison using local profiles and Nutanix Files with CPM Profiles. The Read I/O peaked at 15,361 for the local profile test, and 16,713 for the Nutanix Files with Citrix Profile Containers test.](../images/RA-2003-cluster_disk_iops_read_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Cluster Disk Read I/O Disk")

<!--TEMPLATE CONTENT: Validate Above--> 

![Cluster Disk Write I/O comparison using local profiles and Nutanix Files with CPM Profiles. The Write I/O peaked at 463 for the local profile test, and 3,634 for the Nutanix Files with Citrix Profile Containers test.](../images/RA-2003-cluster_disk_iops_write_WS22_Local_vs_CPM.png "Local Profiles vs. Nutanix Files with CPM: Cluster Disk Write I/O Disk")

<!--TEMPLATE CONTENT: Validate Above--> 

### Citrix Profile Containers Advanced Information

Citrix Profile Management containers have a range of advanced functionalities and features that can affect performance. For performance impacts and considerations, see [Citrix Profile Management on Nutanix Files](https://portal.nutanix.com/page/documents/solutions/details?targetId=TN-2002-Citrix-User-Profile-Management-on-Nutanix:TN-2002-Citrix-User-Profile-Management-on-Nutanix).

The appendix section of this document includes the Citrix Profile Management container settings that we used during testing.

## Results Summary

Our results show that if you use MCS-provisioned or Provisioning-streamed servers to linearly scale the Citrix Delivery Solutions on Nutanix, the system maintains the same average response times regardless of how many nodes you have. 

Test results summary:

- The tested session host specification provided a consistent user experience across all tests.
- Provisioning and MCS configurations performed similarly, although the Provisioning-deployed cluster saw slightly higher logon times.
- Provisioning had generally shorter application start times than MCS in these tests.
- Provisioning had a greater impact on the writes on the cluster hosting the workloads, and MCS had a greater impact on the reads. We expect these effects due to the write-heavy nature of the Provisioning filter driver.
- Compared with Windows 10, Windows 11 has a higher CPU footprint during the logon phase.
- When you optimize Windows 10 and Windows 11, the logon experience is similar.
- Application response times are generally similar between  Windows 11 and Windows 10.
- Windows 11 CPU configurations are critical: A 3 vCPU instance performed better than a 2 vCPU instance.
- Using 3 vCPU with Windows 11 or 2 vCPU with Windows 10 didn't affect the overall cluster metrics, although the 3 vCPU configuration had a higher CPU ready time.
- Provisioning and MCS configurations performed similarly, although the Provisioning-deployed cluster saw higher logon times.
- MCS had generally shorter application start times than Provisioning, which is expected because Provisioning streams data on first access. Subsequent access launches from the local cache.
- Provisioning has a greater impact on the writes on the cluster hosting the workloads, and MCS has a greater impact on the reads. We expect these effects due to the write-heavy nature of the Provisioning filter driver.

<!--TEMPLATE CONTENT: Validate Above--> 
