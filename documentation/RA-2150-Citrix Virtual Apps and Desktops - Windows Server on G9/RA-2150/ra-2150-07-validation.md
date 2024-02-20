# Citrix Virtual Apps and Desktops on Nutanix Test Validation

This section provides the details and results of our Citrix Virtual Apps and Desktops performance tests on Nutanix NX-3155-G9 nodes with Nutanix AHV. We ran each test scenario at least 3 times to ensure accuracy.

## Test Objectives

Our objective was to determine the session capacity we could host on Nutanix using a Windows VDA image and running the Login Enterprise tests with Citrix Virtual Apps and Desktops. We tested with the Login Enterprise Knowledge Worker profile.

We had the following specific objectives:

- Determine the maximum number of sessions we can host on this system with the Login Enterprise Knowledge Worker workload while maintaining a good user experience.
- Show the linear scalability of the Nutanix platform.
- Show the Power Usage in Watts of the Nutanix platform.
- Show the differences between Machine Creation Services and Citrix Provisioning on the Nutanix platform.
- Show the differences between G7, G8, and G9 Nutanix node types.


## Considerations for Test Results

- We used Citrix MCS and PVS to deploy the Windows VMs to validate linear scalability.
- We tested using a single, full-HD screen with the default Citrix frames per second configuration. Using multiple screens or other screen resolution settings affects the results.

## Boot Storm Simulation

The following section provides the performance details of the boot storm simulation test.

_Table: Hosting Connection Settings_ 

| Setting | Detail |
| --- | --- |
| Simultaneous Actions (Absolute) | 100 |
| Simultaneous Actions (Percentage) | 20 % |
| Max New Actions per Minute (Absolute) | 50 |

### Booting 128 Windows Servers on 8 Nutanix G9 Nodes

_Table: Boot Storm Simulation: 8 Node MCS Test_

| Measurement | Detail |
| --- | --- |
| Maximum CPU Usage | 25.0 % |
| Average CPU Usage | 17.4 % |
| Average Controller IOPS | 26,087 |
| Boot Time | 3.4 minutes |

## Linear Scalability

The following section shows the linear scalability of the Nutanix platform. We performed the tests with 1, 2, 4, 6, and 8 nodes with 16 VMs and 155 users per node. The results display average timings and show good user experience in all scenarios.

### Logon Phase

The following charts detail the user experience during the logon phase of the test.

#### Logon Time Scores

The following shows the linear scalability of logon times over the test runs. A lower result represents better performance.

_Table: Logon Performance Linear Scale Logon Phase: Logon Time (in Seconds)_

| Measurement | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes | 
| --- | --- | --- | --- | --- | --- |
| Average Logon Time | 7.8 seconds | 7.9 seconds | 8.0 seconds | 8.0 seconds | 8.0 seconds |
| User Profile Load | 0.90 seconds | 0.90 seconds | 0.90 seconds | 0.90 seconds | 0.90 seconds |
| Group Policies | 1.40 seconds | 1.40 seconds | 1.40 seconds | 1.40 seconds | 1.40 seconds |
| Connection | 3.20 seconds | 3.30 seconds | 3.30 seconds | 3.30 seconds | 3.30 seconds |

#### Application Performance

The following shows the linear scalability of application performance over the test runs. A lower result represents better performance.

_Table: Application Performance Linear Scale Logon Phase: App Start (in Seconds)_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes | 
| --- | --- | --- | --- | --- | --- |
| Microsoft Outlook | 1.84 seconds | 1.92 seconds | 2.15 seconds | 1.98 seconds | 1.93 seconds |
| Microsoft Word | 0.83 seconds | 0.84 seconds | 0.90 seconds | 0.84 seconds | 0.85 seconds |
| Microsoft Excel | 0.72 seconds | 0.72 seconds | 0.78 seconds | 0.75 seconds | 0.75 seconds |
| Microsoft PowerPoint | 0.74 seconds | 0.75 seconds | 0.80 seconds | 0.76 seconds | 0.76 seconds |

_Table: Application Performance Linear Scale Logon Phase: Specific Action (in Seconds)_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | --- | --- | --- | --- | --- |
| Microsoft Edge (Page Load) | 1.20 seconds | 1.21 seconds | 1.28 seconds | 1.24 seconds | 1.25 seconds |
| Microsoft Word (Open Doc) | 0.70 seconds | 0.73 seconds | 0.76 seconds | 0.72 seconds | 0.73 seconds |
| Microsoft Excel (Save File) | 0.36 seconds | 0.33 seconds | 0.35 seconds | 0.33 seconds | 0.33 seconds |

### Steady State Phase

The following charts detail the user experience during the steady state phase of the test.

#### Application Performance

The following shows the linear scalability of application performance over the steady state phase of the test runs. A lower result represents better performance.

_Table: Application Performance Linear Scale Steady State Phase: App Start (in Seconds)_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes | 
| --- | --- | --- | --- | --- | --- |
| Microsoft Word | 0.98 seconds | 0.94 seconds | 1.07 seconds | 0.95 seconds | 0.97 seconds |
| Microsoft Excel | 0.80 seconds | 0.78 seconds | 0.92 seconds | 0.82 seconds | 0.83 seconds |
| Microsoft PowerPoint | 0.78 seconds | 0.77 seconds | 0.92 seconds | 0.80 seconds | 0.82 seconds |

_Table: Application Performance Linear Scale Steady State Phase: Specific Action (in Seconds)_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | --- | --- | --- | --- | --- |
| Microsoft Edge (Page Load) | 1.48 seconds | 1.40 seconds | 1.62 seconds | 1.45 seconds | 1.47 seconds |
| Microsoft Word (Open Doc) | 0.78 seconds | 0.79 seconds | 0.90 seconds | 0.79 seconds | 0.81 seconds |
| Microsoft Excel (Save File) | 0.34 seconds | 0.33 seconds | 0.36 seconds | 0.34 seconds | 0.34 seconds |

## Power Consumption

During the test, we monitored one node's power consumption to determine the power usage. The following chart shows the host's power usage over the test duration.

![This image shows an a chart with the power consumption used in watts during the full test for a single Nutanix G9 node.](../images/RA-2150_image05.png "Power Usage in Watts during the full test run")

The next chart shows the power usage during the steady state phase of the test.

![This image shows an a chart with the power consumption used in watts during the steady state part of the test for a single Nutanix G9 node.](../images/RA-2150_image06.png "Power Usage in Watts during the steady state phase of the test")

On average, the a single Nutanix host used 628 Watts (W) during the steady state.

## MCS vs. PVS

In this section, we compare the results of a Login Enterprise test on 8 nodes, using Machine Creation Services (MCS) and Citrix Provisioning (PVS) as the deployment methods.

### System Performance

The following charts show the overall system performance during the entire test run.

![This image shows an a chart with the CPU usage in percent for the entire 8 node test.](../images/RA-2150_image07.png "CPU Usage 8 Node Chart")

![This image shows an a chart with the CPU ready time in percent for the entire 8 node test.](../images/RA-2150_image08.png "CPU Ready Time 8 Node Chart")

![This image shows an a chart with the Controller Read IOPS for the entire 8 node test.](../images/RA-2150_image09.png "Controller Read IOPS 8 Node Chart")

![This image shows an a chart with the Controller Write IOPS for the entire 8 node test.](../images/RA-2150_image10.png "Controller Write IOPS 8 Node Chart")

![This image shows an a chart with the Controller Latency in ms for the entire 8 node test.](../images/RA-2150_image11.png "Controller Latency 8 Node Chart")

The average graph data above is summarized in the following table.

_Table: System Performance MCS vs. PVS: System Performance Summary_

| Measurement | MCS | PVS |
| --- | --- | --- | 
| CPU Usage | 57.2 % | 57.1 % |
| CPU Ready Time | 0.10 % | 0.21 % | 
| Controller Read IOPS | 12,047 | 7,455 | 
| Controller Write IOPS | 17,762 | 28,341 | 
| Controller Latency | 1.48 ms | 0.50 ms | 

### Logon Phase

The following charts detail the user experience during the logon phase.

#### Logon Time Scores

The following shows the logon times over the test runs. A lower result represents better performance.

_Table: Logon Performance MCS vs. PVS Logon Phase: Logon Time (in Seconds)_

| Measurement | MCS | PVS |
| --- | --- | --- | 
| Average Logon Time | 8.0 seconds | 8.2 seconds |
| User Profile Load | 0.90 seconds | 0.90 seconds | 
| Group Policies | 1.4 seconds | 1.4 seconds | 
| Connection | 3.3 seconds | 3.4 seconds | 

#### Application Performance

The following shows the detail for application performance. A lower result represents better performance.

_Table: Application Performance MCS vs. PVS Logon Phase: App Start (in Seconds)_

| Application | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Outlook | 1.92 seconds | 2.00 seconds | 
| Microsoft Word | 0.85 seconds | 0.87 seconds | 
| Microsoft Excel | 0.75 seconds | 0.76 seconds |
| Microsoft PowerPoint | 0.76 seconds | 0.78 seconds | 

_Table: Application Performance MCS vs. PVS Logon Phase: Specific Action (in Seconds)_

| Application (Action) | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Word (Open Doc) | 0.73 seconds | 0.74 seconds | 
| Microsoft Excel (Save File) | 0.33 seconds | 0.33 seconds | 

### Steady State Phase

The following charts detail the user experience during the steady state.

#### Application Performance

The following shows the detail for application performance during steady state. A lower result represents better performance.

_Table: Application Performance MCS vs. PVS Steady State Phase: App Start (in Seconds)_

| Application | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Word | 0.97 seconds | 1.01 seconds | 
| Microsoft Excel | 0.83 seconds | 0.86 seconds |
| Microsoft PowerPoint | 0.82 seconds | 0.84 seconds | 

_Table: Application Performance MCS vs. PVS Steady State Phase: Specific Action (in Seconds)_

| Application (Action) | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | 1.47 seconds | 1.53 seconds |
| Microsoft Word (Open Doc) | 0.81 seconds | 0.83 seconds | 
| Microsoft Excel (Save File) | 0.34 seconds | 0.34 seconds | 

## Nutanix G7, G8 vs G9 Nodes

To show the improved performance and density when you use a newer CPU generation, we tested with the Login Enterprise workload on three generations of Nutanix hardware: a G7, G8 and G9. The following table shows the specifications of these nodes:

_Table: G8 vs. G8 vs. G9: Specifications_

| Node | G7 | G8 | G9 |
| --- | --- | --- | --- |
| CPU | Intel Xeon Gold 5220 | Intel Xeon Gold 6342 | Intel Xeon Gold 6442Y |
| Generation | Cascade Lake | Ice Lake | Sapphire Rapids |
| Cores per CPU | 18 | 24 | 24 |
| Cores per node | 36 | 48 | 48 |
| MHz per core | 2200 | 2800 | 2600 |
| Storage config | Hybrid | All Flash SSD | All Flash NVMe |

 The following section shows the difference between the Nutanix G7, G8, and G9 hardware.

### System Performance

For these tests, we used the results of single-node tests. The goal of these tests was to get a CPU utilization of around 80% during steady state. 

The following table shows the number of users per node and the resulting CPU calculations:

_Table: G8 vs. G8 vs. G9: CPU results_

| Measurement | G7 | G8 | G9 | 
| --- | --- | --- | -- |
| Number of users per node | 85 | 140 | 155 |
| Number of users per node (%) | **100%** | **165%** | **182%** |
| MHz per session during steady state | 745 | 768 | 644 |
| MHz per session during steady state (%) | **100%** | **103%** | **86%** |
| Sessions per core | 2.36 | 2.92 | 3.23 |
| Sessions per core (%) | **100%** | **124%** | **136%** |
| vCPUs per core (including CVM) | 2.33 | 2.25 | 2.25 |
| vCPUs per core (including CVM) (%) | **100%** | **96%** | **96%** |

The following charts show the system performance during the tests.

![This image shows an a chart with the CPU Usage for G7, G8 and G9 hardware during a 1 node test.](../images/RA-2150_image17.png "G7, G8 and G9 CPU Usage Chart")

### Logon Phase

The following charts detail the user experience during the logon phase.

#### Logon Time Scores

The following shows the logon times over the test runs. A lower result represents better performance.

_Table: Application Performance G7 vs. G8 vs. G9 Logon Phase: Logon Time (in Seconds)_

| Measurement | G7 | G8 | G9 |
| --- | --- | --- | --- |
| Average Logon Time | 9.7 seconds | 8.5 seconds | 7.7 seconds | 
| User Profile Load | 1.2 seconds | 0.9 seconds | 0.9 seconds |
| Group Policies | 2.1 seconds | 1.6 seconds | 1.4 seconds |
| Connection | 3.8 seconds | 3.4 seconds | 3.2 seconds |

#### Application Performance

The following shows the detail for application performance. A lower result represents better performance.

_Table: Application Performance G7 vs. G8 vs. G9 Logon Phase: App Start (in Seconds)_

| Application | G7 | G8 | G9 |
| --- | --- | --- | --- |
| Microsoft Outlook | 2.41 seconds | 2.10 seconds | 1.82 seconds |
| Microsoft Word | 1.11 seconds | 0.92 seconds | 0.83 seconds |
| Microsoft Excel | 0.98 seconds | 0.82 seconds | 0.73 seconds |
| Microsoft PowerPoint | 0.97 seconds | 0.84 seconds | 0.74 seconds | 

_Table: Application Performance G7 vs. G8 vs. G9 Logon Phase: Specific Action (in Seconds)_

| Application (Action) | G7 | G8 | G9 |
| --- | --- | --- | --- |
| Microsoft Edge (Page Load) | 1.78 seconds | 1.42 seconds | 1.22 seconds |
| Microsoft Word (Open Doc) | 0.94 seconds | 0.81 seconds | 0.70 seconds | 
| Microsoft Excel (Save File) | 0.35 seconds | 0.34 seconds | 0.33 seconds |

The following graph is an example of the performance improvement of Outlook App Start on the different hardware platforms.

![This image shows a chart with the outlook start times for the G7, G8 and G9 Nutanix Hardware node types.](../images/RA-2150_image18.png "G7, G8 and G9 Outlook Start Chart")

### Steady State Phase

The following charts detail the user experience during the steady state.

#### Application Performance

The following shows the detail for application performance. A lower result represents better performance.

_Table: Application Performance G7 vs. G8 vs. G9 Steady State Phase: App Start (in Seconds)_

| Application | G7 | G8 | G9 |
| --- | --- | --- | --- |
| Microsoft Word | 1.21 seconds | 1.11 seconds | 0.94 seconds |
| Microsoft Excel | 1.08 seconds | 0.92 seconds | 0.79 seconds |
| Microsoft PowerPoint | 1.00 seconds | 0.93 seconds | 0.78 seconds |

_Table: Application Performance G7 vs. G8 vs. G9 Steady State Phase: Specific Action (in Seconds)_

| Application (Action) | G7 | G8 | G9 |
| --- | --- | --- | --- |
| Microsoft Edge (Page Load) | 2.10 seconds | 1.67 seconds | 1.43 seconds |
| Microsoft Word (Open Doc) | 1.01 seconds | 0.93 seconds | 0.79 seconds |
| Microsoft Excel (Save File) | 0.38 seconds | 0.35 seconds | 0.33 seconds |

The results of these tests show an improvement in performance and density when upgrading to a new generation of CPU.