# Citrix Virtual Apps and Desktops on Nutanix Test Validation

This section provides the details and results of our Citrix Virtual Apps and Desktops performance tests on Nutanix NX-3155-G9 nodes with Nutanix AHV. We ran each test scenario at least 3 times to ensure accuracy.

## Test Objectives

Our objective was to determine the session capacity we could host on Nutanix using a Windows VDA image and running the Login Enterprise tests with Citrix Virtual Apps and Desktops. We tested with the Login Enterprise Knowledge Worker profile.

We had the following specific objectives:

- Determine the maximum number of sessions we can host on this system with the Login Enterprise Knowledge Worker workload while maintaining a good user experience.
- Show the linear scalability of the Nutanix platform.
- Show the differences between MCS and Citrix Provisioning on the Nutanix platform.
- Show the differences between Windows 10 and Windows 11 on the Nutanix platform.
- Show the comparison between G7, G8, and G9 Nutanix node types.

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

### 1040 Windows Desktops on 8 Nodes

_Table: Boot Storm Simulation: 8 Node Test_

| Measurement | Detail |
| --- | --- |
| Maximum CPU Usage | 25.9 % |
| Average CPU Usage | 18.1 % |
| Average Controller IOPS | 29.426 |
| Boot Time | 27.7 minutes |

## Linear Scalability

The following section shows the linear scalability of the test runs. We performed the tests with 1, 2, 4, 6, and 8 nodes with 130 VMs per node. The results show good user experience in all scenarios.

### Logon Phase

The following charts detail the user experience during the logon phase.

#### Logon Time Scores

The following table shows the linear scalability of logon times over the test runs. A lower result represents better performance.

_Table: Logon Performance: Logon Time (in Seconds)_

| Measurement | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes | 
| --- | --- | --- | --- | --- | --- |
| Average Logon Time | 6.5 seconds | [#] | 6.8 seconds | 6.6 seconds | 6.6 seconds |
| User Profile Load | 0.40 seconds | [#] | 0.42 seconds | 0.38 seconds | 0.38 seconds |
| Group Policies | 2.21 seconds | [#] | 2.27 seconds | 2.24 seconds | 2.25 seconds |
| Connection | 2.65 seconds | [#] | 2.81 seconds | 2.69 seconds | 2.70 seconds |
| Total Logon Time | 6.52 seconds | [#] | 6.76 seconds | 6.60 seconds | 6.63 seconds |

#### Application Performance

The following tables show the linear scalability of application performance over the test runs. A lower result represents better performance.

_Table: Application Performance: App Start (in Seconds)_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes | 
| --- | --- | --- | --- | --- | --- |
| Microsoft Outlook | 2.95 seconds | [#] | 3.24 seconds | 3.15 seconds | 3.17 seconds |
| Microsoft Word | 0.86 seconds | [#] | 0.90 seconds | 0.88 seconds | 0.89 seconds |
| Microsoft Excel | 1.02 seconds | [#] | 1.05 seconds | 1.01 seconds | 1.03 seconds |
| Microsoft PowerPoint | 0.95 seconds | [#] | 0.98 seconds | 0.93 seconds | 0.94 seconds |

_Table: Application Performance: Specific Action (in Seconds)_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | --- | --- | --- | --- | --- |
| Microsoft Edge (Page Load) | 1.36 seconds | [#] | 1.40 seconds | 1.39 seconds | 1.44 seconds |
| Microsoft Word (Open Doc) | 1.02 seconds | [#] | 0.96 seconds | 0.91 seconds | 0.92 seconds |
| Microsoft Excel (Save File) | 0.35 seconds | [#] | 0.35 seconds | 0.33 seconds | 0.33 seconds |

### Steady State Phase

The following charts detail the user experience during the steady state.

#### Application Performance

The following tables show the linear scalability of application performance over the test runs. A lower result represents better performance.

_Table: Application Performance: App Start (in Seconds)_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes | 
| --- | --- | --- | --- | --- | --- |
| Microsoft Word | 0.88 seconds | [#] | 0.93 seconds | 0.91 seconds | 0.92 seconds |
| Microsoft Excel | 0.88 seconds | [#] | 0.94 seconds | 0.90 seconds | 0.91 seconds |
| Microsoft PowerPoint | 0.81 seconds | [#] | 0.84 seconds | 0.82 seconds | 0.83 seconds |

_Table: Application Performance: Specific Action (in Seconds)_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | --- | --- | --- | --- | --- |
| Microsoft Edge (Page Load) | 1.40 seconds | [#] | 1.45 seconds | 1.45 seconds | 1.49 seconds |
| Microsoft Word (Open Doc) | 0.94 seconds | [#] | 0.99 seconds | 0.94 seconds | 0.96 seconds |
| Microsoft Excel (Save File) | 0.33 seconds | [#] | 0.34 seconds | 0.33 seconds | 0.33 seconds |

## Power Consumption

During the test, we monitored one node's power usage. The following chart shows this host's power usage over the test duration.

![This image shows an a chart with the power consumption used in watts during the full test for a single G9 node.](../images/RA-2053_image05.png "Power usage during the full test")

The next chart shows the power usage during the steady state of the test.

![This image shows an a chart with the power consumption used in watts during the steady state part of the test for a single G9 node.](../images/RA-2053_image06.png "Power usage during the steady state section of the test")

On average, the host used 685 Watts (W) during the steady state.

## MCS vs. Citrix Provisioning

In this section, we compare the results of a Login Enterprise test on 8 nodes, using MCS and Citrix Provisioning as the deployment methods.

### System Performance

The following charts show the system performance during the entire test.

![This image shows an a chart with the CPU usage in percent for the entire 8 node test.](../images/RA-2053_image07.png "CPU Usage 8 Node Chart")

![This image shows an a chart with the CPU ready time in percent for the entire 8 node test.](../images/RA-2053_image08.png "CPU Ready Time 8 Node Chart")

![This image shows an a chart with the Controller Read IOPS for the entire 8 node test.](../images/RA-2053_image09.png "Controller Read IOPS 8 Node Chart")

![This image shows an a chart with the Controller Write IOPS for the entire 8 node test.](../images/RA-2053_image10.png "Controller Write IOPS 8 Node Chart")

![This image shows an a chart with the Controller Latency for the entire 8 node test.](../images/RA-2053_image11.png "Controller Latency 8 Node Chart")

### Logon Phase

The following charts detail the user experience during the logon phase.

#### Logon Time Scores

The following graph shows the logon time performance over the test runs.

_Table: Logon Performance MCS vs PVS: Logon Time (in Seconds)_

| Measurement | MCS | Citrix Provisioning |
| --- | --- | --- | 
| Average Logon Time | 6.6 seconds | 7.7 seconds |
| User Profile Load | 0.40 seconds | 0.50 seconds | 
| Group Policies | 2.2 seconds | 2.3 seconds | 
| Connection | 2.7 seconds | 3 seconds | 
| Total Logon Time | 6.6 seconds | 7.7 seconds | 

#### Application Performance

The following table shows the detail for application performance.

_Table: MCS vs. Citrix Provisioning: App Start (in Seconds)_

| Application | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Outlook | 3.17 seconds | 3.95 seconds | 
| Microsoft Word | 0.89 seconds | 0.92 seconds | 
| Microsoft Excel | 1.03 seconds | 1.25 seconds |
| Microsoft PowerPoint | 0.94 seconds | 1.15 seconds | 

_Table: MCS vs. Citrix Provisioning: Specific Action (in Seconds)_

| Application (Action) | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Word (Open Doc) | 0.92 seconds | 1.09 seconds | 
| Microsoft Excel (Save File) | 0.33 seconds | 0.35 seconds | 

### Steady State Phase

The following charts detail the user experience during the steady state.

#### Application Performance

The following table shows the detail for application performance during steady state.

_Table: MCS vs. Citrix Provisioning: App Start (in Seconds)_

| Application | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Word | 0.92 seconds | 0.93 seconds | 
| Microsoft Excel | 0.91 seconds | 0.97 seconds |
| Microsoft PowerPoint | 0.83 seconds | 0.86 seconds | 

_Table: MCS vs. Citrix Provisioning: Specific Action (in Seconds)_

| Application (Action) | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | 1.49 seconds | 1.55 seconds |
| Microsoft Word (Open Doc) | 0.96 seconds | 1.00 seconds | 
| Microsoft Excel (Save File) | 0.33 seconds | 0.34 seconds | 

## Nutanix G7, G8 vs G9 Nodes

The following section shows the difference between the Nutanix G7, G8, and G9 hardware.

### System Performance

The following charts show the system performance during the tests.

CPU TOTAL
CPU READY

_Table: G8 vs. G8 vs. G9: Key Differences_

| Item | G7 | G8 | G9 | 
| --- | --- | --- | -- |
| Login Times | 8.7 seconds | 7.1 seconds | 6.5 seconds |
| Number of users per node | 70 | 120 | 130 |
| Word Start | 1.17 seconds | 0.90 seconds | 0.86 seconds |
| Excel Start | 1.28 seconds | 1.04 seconds | 0.98 seconds |
| PowerPoint Start | 1.16 seconds | 0.96 seconds | 0.87 seconds |
| Edge Page Load | 1.93 seconds | 1.54 seconds | 1.35 seconds |

## Windows 10 vs. Windows 11

In this section, we compare the results of a Login Enterprise test on 8 nodes, using Windows 10 vs Windows 11.

### System Performance

The following charts show the system performance during the tests.

CPU TOTAL
CPU READY
IOPS READ
IOPS WRITE
CONTROLLER IO LATENCY TOTAL

### Logon Phase

The following charts detail the user experience during the logon phase.

#### Logon Time Scores

The following table shows the logon time performance over the test runs.

_Table: Logon Performance Windows 10 vs Windows 11: Logon Time (in Seconds)_

| Measurement | Windows 10 | Windows 11 |
| --- | --- | --- |
| Average Logon Time | 6.5 seconds | [#] |
| User Profile Load | 0.40 seconds | [#] | 
| Group Policies | 2.21 seconds | [#] | 
| Connection | 2.65 seconds | [#] | 
| Total Logon Time | 6.52 seconds | [#] | 

#### Application Performance

The following table shows the linear scalability detail for application performance.

_Table: Windows 10 vs Windows 11: Application Logon Time (in Seconds)_

| Application | Windows 10 | Windows 11 | 
| --- | --- | --- | 
| Microsoft Outlook | [#] | [#] | 
| Microsoft Word | [#] | [#] | 
| Microsoft Excel | [#] | [#] |
| Microsoft PowerPoint | [#] | [#] | 

_Table: Windows 10 vs Windows 11: Specific Action (in Seconds)_

| Application (Action) | Windows 10 | Windows 11 | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | 
| Microsoft Excel (Save File) | [#] | [#] | 

### Steady State Phase

The following charts detail the user experience during the steady state.

#### Application Performance

The following table shows the detail for application performance.

_Table: Windows 10 vs Windows 11: Application Logon Time (in Seconds)_

| Application | Windows 10 | Windows 11 | 
| --- | --- | --- | 
| Microsoft Outlook | [#] | [#] | 
| Microsoft Word | [#] | [#] | 
| Microsoft Excel | [#] | [#] |
| Microsoft PowerPoint | [#] | [#] | 

_Table: Windows 10 vs Windows 11: Specific Action (in Seconds)_

| Application (Action) | Windows 10 | Windows 11 | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | 
| Microsoft Excel (Save File) | [#] | [#] | 
