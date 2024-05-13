# Citrix Desktop as a Service on Nutanix Test Validation

This section provides the details and results of our Citrix DaaS performance tests on Lenovo ThinkAgile HX665 V3 CN nodes with Nutanix AHV. We ran each test scenario at least 3 times to ensure accuracy.

## Test Objectives

Our objective was to determine the session capacity we could host on Nutanix using a Windows VDA image and running the Login Enterprise tests with Citrix DaaS. We tested with the Login Enterprise Knowledge Worker profile.

Objectives:

-  Determine the maximum number of sessions we can host on this system with the Login Enterprise Knowledge Worker workload while maintaining a good user experience.
-  Show the linear scalability of the Nutanix platform.
-  Show the Power Usage in Watts of the Nutanix platform.
-  Show the differences between Machine Creation Services and Citrix Provisioning on the Nutanix platform.
-  Show the differences between Windows 10 and Windows 11 on the Nutanix platform.

Testing parameters:

-  We used Citrix MCS and PVS to deploy the Windows VMs to validate linear scalability.
-  We tested using a single, full-HD screen with the default Citrix frames per second configuration. Using multiple screens or other screen resolution settings affects the results.

## Boot Storm Simulation

We used the following hosting connection settings for our boot storm simulation test.

_Table: Hosting Connection Settings_ 

| Setting | Detail |
| --- | --- |
| Simultaneous Actions (Absolute) | 100 |
| Simultaneous Actions (Percentage) | 20 % |
| Max New Actions per Minute (Absolute) | 50 |

We started 900 Windows desktops on six Lenovo ThinkAgile HX665 V3 CN nodes. The following table shows the performance results of this test.

_Table: Boot Storm Simulation: Six Node MCS Test_

| Measurement | Detail |
| --- | --- |
| Maximum CPU Usage | 87.2 % |
| Average CPU Usage | 67.5 % |
| Average Controller IOPS | 27,483 |

## Linear Scalability

The following section shows the linear scalability of the Nutanix platform. We performed the tests with one, two, four, and six nodes with 150 Windows 11 VMs per node. The results display average timings and show good user experience in all scenarios.

### Linear Scalability Logon Phase

The following charts detail the user experience during the logon phase of the test. A lower result represents better performance.

_Table: Linear Scalability Logon Phase: Logon Times_

| Measurement | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | --- | --- | --- | --- | 
| Average Logon Time | 5.1 seconds | 5.2 seconds | 5.5 seconds | 5.5 seconds | 
| User Profile Load | 0.4 seconds | 0.4 seconds | 0.5 seconds | 0.5 seconds | 
| Group Policies | 1.1 seconds | 1.1 seconds | 1.1 seconds | 1.1 seconds | 
| Connection | 2.6 seconds | 2.7 seconds | 2.8 seconds | 2.8 seconds| 

The following chart displays the login times across the tests. A lower result represents a better experience.

![The chart shows the total Login Times across the tests](../images/login_times_total_logon_time_W11_Lin.png "Login Times Total Logon Time W11 Lin")

The following shows the linear scalability of application performance over the test runs. A lower result represents better performance.

_Table: Linear Scalability Logon Phase: App Start Times_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | --- | --- | --- | --- |
| Microsoft Outlook | 3.23 seconds | 3.53 seconds | 3.76 seconds | 3.92 seconds | 
| Microsoft Word | 0.75 seconds | 0.73 seconds | 0.76 seconds | 0.74 seconds | 
| Microsoft Excel | 1.02 seconds | 1.02 seconds | 1.07 seconds | 1.09 seconds | 
| Microsoft PowerPoint | 0.87 seconds | 0.90 seconds | 0.97 seconds | 0.98 seconds | 

_Table: Linear Scalability Logon Phase: Specific Action Times_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | --- | --- | --- | --- |
| Microsoft Edge (Page Load) | 0.98 seconds | 1.01 seconds | 1.05 seconds | 1.06 seconds | 
| Microsoft Word (Open Doc) | 0.77 seconds | 0.80 seconds | 0.87 seconds | 0.90 seconds | 
| Microsoft Excel (Save File) | 0.33 seconds | 0.33 seconds | 0.34 seconds | 0.34 seconds | 

### Linear Scalability Steady State

The following tables detail the user experience during the steady state of the test. A lower result represents better performance.

_Table: Linear Scalability Steady State Phase: App Start Times_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | --- | --- | --- | --- | 
| Microsoft Word | 0.75 seconds | 0.75 seconds | 0.78 seconds | 0.76 seconds | 
| Microsoft Excel | 0.74 seconds | 0.74 seconds | 0.79 seconds | 0.78 seconds | 
| Microsoft PowerPoint | 0.72 seconds | 0.71 seconds | 0.76 seconds | 0.75 seconds | 

_Table: Application Performance Linear Scale Steady State Phase: Specific Action (in Seconds)_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes |
| --- | --- | --- | --- | --- |
| Microsoft Edge (Page Load) | 0.98 seconds | 0.93 seconds | 1.04 seconds | 1.01 seconds |
| Microsoft Word (Open Doc) | 0.78 seconds | 0.80 seconds | 0.91 seconds | 0.91 seconds | 
| Microsoft Excel (Save File) | 0.32 seconds | 0.33 seconds | 0.33 seconds | 0.33 seconds | 

### Single Node Host Resources

The following tables detail the host utilization of a single node during the entire duration of the test, both boot and steady state phases. We tested 150 VMs per Node and captured the following metrics.

| Host Metric | Max | Average |
| --- | --- | --- |
| Host CPU Usage | 84.1 % | 65.9 % |
| Host Memory Usage | 63.3 % | 63.3 % |
| Host Power Usage | 793 W | 695 W |

The following charts detail the host utilization during the entire test duration, both the boot and steady state phases.

![This image shows a chart with cpu usage as a percentage during the full test for a single Lenovo ThinkAgile HX665 V3 CN node.](../images/host_resources_cpu_usage_W11_Lin.png "Host Resources Cpu Usage during the full test run")
![This image shows a chart with memory usage as a percentage during the full test for a single Lenovo ThinkAgile HX665 V3 CN node.](../images/host_resources_memory_usage_W11_Lin.png "Host Resources Memory Usage during the full test run")
![This image shows a chart with the power consumption used in watts during the full test for a single Lenovo ThinkAgile HX665 V3 CN node.](../images/host_resources_power_usage_W11_Lin.png "Power Usage in Watts during the full test run")

## Citrix MCS vs. PVS

In this section, we compare the results of a Login Enterprise test on six nodes, using Machine Creation Services (MCS) and Citrix Provisioning (PVS) as the deployment methods.

### MCS vs. PVS System Performance

The following charts show the overall system performance during the entire test run.

![CPU usage trends for two six-node clusters, one deployed using Citrix MCS and one deployed using Citrix PVS](../images/cluster_resources_cpu_usage_W11_MCS_PVS.png "MCS vs. PVS: CPU Usage")

![CPU ready time trends for two six-node clusters, one deployed using Citrix MCS and one deployed using Citrix PVS](../images/cluster_resources_cpu_ready_W11_MCS_PVS.png "MCS vs. PVS: CPU Ready Times")

![Controller read IOPS trends for two six-node clusters, one deployed using Citrix MCS and one deployed using Citrix PVS](../images/cluster_resources_controller_read_iops_W11_MCS_PVS.png "MCS vs. PVS: Controller Read IOPS")

![Controller write IOPS trends for two six-node clusters, one deployed using Citrix MCS and one deployed using Citrix PVS](../images/cluster_resources_controller_write_iops_W11_MCS_PVS.png "MCS vs. PVS: Controller Write IOPS")

![Controller latency trends for two six-node clusters, one deployed using Citrix MCS and one deployed using Citrix PVS](../images/cluster_resources_controller_latency_W11_MCS_PVS.png "MCS vs. PVS: Controller Latency")

The following table provides the averages for the overall system performance results displayed in the graphs above.

_Table: System Performance MCS vs. PVS: System Performance Summary_

| Measurement | MCS | PVS |
| --- | --- | --- | 
| CPU Usage | 67.5 % | 66.8 % |
| CPU Ready Time | 1.16 % |1.40 % | 
| Controller Read IOPS | 13,195 | 3,400 | 
| Controller Write IOPS | 14,287 | 21,466 | 
| Controller Latency | <1 ms | <1 ms | 

### MCS vs. PVS Logon Phase

The following charts detail the user experience during the logon phase.

#### Logon Time Scores

The following shows the logon times over the test runs. A lower result represents better performance.

_Table: Logon Performance MCS vs. PVS Logon Phase: Logon Times_

| Measurement | MCS | PVS |
| --- | --- | --- | 
| Average Logon Time | 5.52 seconds | 6.41 seconds |
| User Profile Load | 0.5 seconds | 0.5 seconds | 
| Group Policies | 1.15 seconds | 1.14 seconds | 
| Connection | 2.8 seconds | 2.8 seconds | 

The following chart displays the login times across the tests. A lower result represents a better experience.

![Logon time trends for two six-node clusters, one deployed using Citrix MCS and one deployed using Citrix PVS](../images/login_times_total_logon_time_W11_MCS_PVS.png "Login Times Total Logon Time W11 MCS PVS")

The following tables show the details for application performance during the logon phase of the test. A lower result represents better performance.

_Table: Application Performance MCS vs. PVS Logon Phase: App Start Times_

| Application | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Outlook | 3.92 seconds | 3.21 seconds | 
| Microsoft Word | 0.74 seconds | 0.76 seconds | 
| Microsoft Excel | 1.09 seconds | 1.14 seconds | 
| Microsoft PowerPoint | 0.98 seconds | 0.92 seconds | 

_Table: Application Performance MCS vs. PVS Logon Phase:  Specific Action Times_

| Application (Action) | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Word (Open Doc) | 0.90 seconds | 0.79 seconds | 
| Microsoft Excel (Save File) | 0.34 seconds | 0.33 seconds |

### MCS vs. PVS Steady State

The following tables show the details for application performance during the steady state of the test. A lower result represents better performance.

_Table: MCS vs. PVS Steady State Phase: App Start Times_

| Application | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Word | 0.76 seconds | 0.77 seconds | 
| Microsoft Excel | 0.78 seconds | 0.79 seconds | 
| Microsoft PowerPoint | 0.75 seconds | 0.74 seconds | 

_Table: MCS vs. PVS Steady State Phase: Specific Action Times_

| Application (Action) | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | 1.01 seconds | 1.04 seconds | 
| Microsoft Word (Open Doc) | 0.91 seconds | 0.79 seconds | 
| Microsoft Excel (Save File) | 0.33 seconds | 0.33 seconds | 

## Windows 10 vs. Windows 11

In this section, we compare the results of a Login Enterprise test on six nodes using Windows 10 versus six nodes using Windows 11.

### Windows 10 vs. Windows 11 System Performance

The following graphs show the overall system performance during the entire test run.

![CPU usage trends for two six-node clusters, one using Windows 10 and one using Windows 11](../images/cluster_resources_cpu_usage_W10_v_W11.png "Windows 10 vs. Windows 11: CPU Usage")

![CPU ready time trends for two six-node clusters, one using Windows 10 and one using Windows 11](../images/cluster_resources_cpu_ready_W10_v_W11.png "Windows 10 vs. Windows 11: CPU Ready Time")

![Controller read IOPS trends for two six-node clusters, one using Windows 10 and one using Windows 11](../images/cluster_resources_controller_read_iops_W10_v_W11.png "Windows 10 vs. Windows 11: Controller Read IOPS")

![Controller write IOPS trends for two six-node clusters, one using Windows 10 and one using Windows 11](../images/cluster_resources_controller_write_iops_W10_v_W11.png "Windows 10 vs. Windows 11: Controller Write IOPS")

![Controller latency trends for two six-node clusters, one using Windows 10 and one using Windows 11](../images/cluster_resources_controller_latency_W10_v_W11.png "Windows 10 vs. Windows 11: Controller Latency")

The following table provides the averages for the overall system performance results displayed in the graphs above.

_Table: System Performance Windows 10 vs. Windows 11: System Performance Summary_

| Measurement | Windows 10 | Windows 11 |
| --- | --- | --- | 
| CPU Usage | 64.2 % | 67.5 % |
| CPU Ready Time | 0.37 % | 1.16 % | 
| Controller Read IOPS | 12,618 | 13,195 | 
| Controller Write IOPS | 12,360 | 14,287 | 
| Controller Latency | <1 ms | <1 ms | 

### Windows 10 vs. Windows 11 Logon Phase

The following table shows the logon times during the logon phase of the test. A lower result represents better performance.

_Table: Logon Performance Windows 10 vs. Windows 11 Logon Phase: Logon Time_

| Measurement | Windows 10 | Windows 11 |
| --- | --- | --- |
| Average Logon Time | 6.7 seconds | 5.5 seconds | 
| User Profile Load | 0.5 seconds | 0.5 seconds |
| Group Policies | 2.0 seconds | 1.1 seconds | 
| Connection | 2.7 seconds | 2.8 seconds | 

The following chart displays the login times across the tests. A lower result represents a better experience.

![Logon time trends for two six-node clusters, one using Windows 10 and one using Windows 11](../images/login_times_total_logon_time_W10_v_W11.png "Login Times Total Logon Time W10 V W11")

The following tables show the details for application performance during the logon phase of the test. A lower result represents better performance.

_Table: Application Performance Windows 10 vs. Windows 11 Logon Phase: App Start Times_

| Application | Windows 10 | Windows 11 | 
| --- | --- | --- | 
| Microsoft Outlook | 3.56 seconds | 3.92 seconds | 
| Microsoft Word | 0.73 seconds | 0.74 seconds |  
| Microsoft Excel | 0.99 seconds | 1.09 seconds |
| Microsoft PowerPoint | 0.93 seconds | 0.98 seconds |

_Table: Application Performance Windows 10 vs. Windows 11 Logon Phase: Specific Action Times_

| Application (Action) | Windows 10 | Windows 11 | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | 1.21 seconds | 1.06 seconds | 
| Microsoft Word (Open Doc) | 0.84 seconds | 0.90 seconds | 
| Microsoft Excel (Save File) | 0.35 seconds | 0.34 seconds | 

### Windows 10 vs. Windows 11 Steady State

The following tables show the details for application performance during the steady state of the test. A lower result represents better performance.

_Table: Application Performance Windows 10 vs. Windows 11 Steady State Phase: App Start Times_

| Application | Windows 10 | Windows 11 | 
| --- | --- | --- | 
| Microsoft Word | 0.75 seconds | 0.76 seconds |
| Microsoft Excel | 0.78 seconds | 0.78 seconds |
| Microsoft PowerPoint | 0.74 seconds | 0.75 seconds |

_Table: Application Performance Windows 10 vs. Windows 11 Steady State Phase: Specific Action Times_

| Application (Action) | Windows 10 | Windows 11 | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | 1.17 seconds | 1.01 seconds | 
| Microsoft Word (Open Doc) | 0.87 seconds | 0.91 seconds | 
| Microsoft Excel (Save File) | 0.34 seconds | 0.33 seconds | 