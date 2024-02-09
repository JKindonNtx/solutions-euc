# Citrix Desktop as a Service on Nutanix Test Validation

This section provides the details and results of our Citrix DaaS performance tests on Nutanix NX-3155-G9 nodes with Nutanix AHV. We ran each test scenario at least 3 times to ensure accuracy.

## Test Objectives

Our objective was to determine the session capacity we could host on Nutanix using a Windows VDA image and running the Login Enterprise tests with Citrix DaaS. We tested with the Login Enterprise Knowledge Worker profile.

We had the following specific objectives:

- Determine the maximum number of sessions we can host on this system with the Login Enterprise Knowledge Worker workload while maintaining a good user experience.
- Show the linear scalability of the Nutanix platform.
- Show the differences between MCS and Citrix Provisioning on the Nutanix platform.
- Show the comparison between G8 and G9 Nutanix node types.

## Considerations for Test Results

- We used Citrix MCS and PVS to deploy the Windows VMs to validate linear scalability.
- We tested using a single, full-HD screen with the default Citrix frames per second configuration. Using multiple screens or other screen resolution settings affects the results.

## Boot Storm Simulation

The following section provides the performance details of the boot storm simulation test.

_Table: Hosting Connection Settings_ 

| Setting | Detail |
| --- | --- |
| Simultaneous Actions (Absolute) | 100 |
| Simultaneous Actions (Percentage) | 40 % |
| Max New Actions per Minute (Absolute) | 50 |

### Machine Creation Services - 8 Nodes

<!-- Boot Time / CPU Usage and IOPS -->

### Citrix Provisioning - 8 Nodes

<!-- Boot Time / CPU Usage and IOPS -->

### Boot Storm Comparison

<!-- Boot Time / CPU Usage and IOPS -->

## Linear Scalability

The following section shows the linear scalability of the test runs. We performed the tests with 1, 2, 4, 6, and 8 nodes with XXXX VMs per node. The results show good user experience in all scenarios.

### Logon Phase

The following charts detail the user experience during the logon phase.

#### Logon Time Scores

The following graphs show the linear scalability of logon times over the test runs. A lower result represents better performance.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

#### Application Performance

The following tables show the linear scalability of application performance over the test runs. A lower result represents better performance.

_Table: Application Performance: Logon Time (in Seconds)_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes | 
| --- | --- | --- | --- | --- | --- |
| Microsoft Outlook | [#] | [#] | [#] | [#] | [#] |
| Microsoft Word | [#] | [#] | [#] | [#] | [#] |
| Microsoft Excel | [#] | [#] | [#] | [#] | [#] |
| Microsoft PowerPoint | [#] | [#] | [#] | [#] | [#] |

_Table: Application Performance: Specific Action (in Seconds)_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | --- | --- | --- | --- | --- |
| Microsoft Edge (Page Load) | [#] | [#] | [#] | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | [#] | [#] | [#] |
| Microsoft Excel (Save File) | [#] | [#] | [#] | [#] | [#] |

#### System Performance

The following charts show the system performance during the tests.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

### Steady State Phase

The following charts detail the user experience during the steady state.

#### Application Performance

The following tables show the linear scalability of application performance over the test runs. A lower result represents better performance.

_Table: Application Performance: Logon Time (in Seconds)_

| Application Name | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes | 
| --- | --- | --- | --- | --- | --- |
| Microsoft Outlook | [#] | [#] | [#] | [#] | [#] |
| Microsoft Word | [#] | [#] | [#] | [#] | [#] |
| Microsoft Excel | [#] | [#] | [#] | [#] | [#] |
| Microsoft PowerPoint | [#] | [#] | [#] | [#] | [#] |

_Table: Application Performance: Specific Action (in Seconds)_

| Application Name (Action) | 1 Node | 2 Nodes | 4 Nodes | 6 Nodes | 8 Nodes |
| --- | --- | --- | --- | --- | --- |
| Microsoft Edge (Page Load) | [#] | [#] | [#] | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | [#] | [#] | [#] |
| Microsoft Excel (Save File) | [#] | [#] | [#] | [#] | [#] |

#### System Performance

The following charts show the system performance during the tests.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

## Power Consumption

During the 8-node test, we monitored one node's power usage. The following chart shows this host's power usage over the test duration.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

The next chart shows the power usage during the steady state of the test.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

On average, the host used [#] Watts (W) during the steady state. The [#]-node cluster used [#] W on average during the steady state with [#] active users.

## MCS vs. Citrix Provisioning

In this section, we compare the results of a Login Enterprise test on 8 nodes, using MCS and Citrix Provisioning as the deployment methods.

### Logon Phase

The following charts detail the user experience during the logon phase.

### Logon Time Scores

The following graph shows the linear scalability of logon time performance over the test runs.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

#### Application Performance

The following table shows the linear scalability detail for application performance.

_Table: MCS vs. Citrix Provisioning: Application Logon Time (in Seconds)_

| Application | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Outlook | [#] | [#] | 
| Microsoft Word | [#] | [#] | 
| Microsoft Excel | [#] | [#] |
| Microsoft PowerPoint | [#] | [#] | 

_Table: MCS vs. Citrix Provisioning: Specific Action (in Seconds)_

| Application (Action) | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | 
| Microsoft Excel (Save File) | [#] | [#] | 

#### System Performance

The following charts show the system performance during the tests.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

### Steady State Phase

The following charts detail the user experience during the steady state.

#### Application Performance

The following table shows the linear scalability detail for application performance.

_Table: MCS vs. Citrix Provisioning: Application Logon Time (in Seconds)_

| Application | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Outlook | [#] | [#] | 
| Microsoft Word | [#] | [#] | 
| Microsoft Excel | [#] | [#] |
| Microsoft PowerPoint | [#] | [#] | 

_Table: MCS vs. Citrix Provisioning: Specific Action (in Seconds)_

| Application (Action) | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | 
| Microsoft Excel (Save File) | [#] | [#] | 

#### System Performance

The following charts show the system performance during the tests.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

## Nutanix G8 vs G9 Nodes

The following section shows the difference between the Nutanix G8 and the Nutanix G9 hardware.

_Table: G8 vs. G9: Key Differences_

| Item | G8 | G9 | 
| --- | --- | --- | 
| Login Times | [#] | [#] |
| Number of users per node | [#] | [#] | 
| etc | [#] | [#] | 

## Windows 10 vs. Windows 11

In this section, we compare the results of a Login Enterprise test on 8 nodes, using Windows 10 vs Windows 11.

### Logon Phase

The following charts detail the user experience during the logon phase.

### Logon Time Scores

The following graph shows the linear scalability of logon time performance over the test runs.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

#### Application Performance

The following table shows the linear scalability detail for application performance.

_Table: MCS vs. Citrix Provisioning: Application Logon Time (in Seconds)_

| Application | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Outlook | [#] | [#] | 
| Microsoft Word | [#] | [#] | 
| Microsoft Excel | [#] | [#] |
| Microsoft PowerPoint | [#] | [#] | 

_Table: MCS vs. Citrix Provisioning: Specific Action (in Seconds)_

| Application (Action) | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | 
| Microsoft Excel (Save File) | [#] | [#] | 

#### System Performance

The following charts show the system performance during the tests.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

### Steady State Phase

The following charts detail the user experience during the steady state.

#### Application Performance

The following table shows the linear scalability detail for application performance.

_Table: MCS vs. Citrix Provisioning: Application Logon Time (in Seconds)_

| Application | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Outlook | [#] | [#] | 
| Microsoft Word | [#] | [#] | 
| Microsoft Excel | [#] | [#] |
| Microsoft PowerPoint | [#] | [#] | 

_Table: MCS vs. Citrix Provisioning: Specific Action (in Seconds)_

| Application (Action) | MCS | Citrix Provisioning | 
| --- | --- | --- | 
| Microsoft Edge (Page Load) | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | 
| Microsoft Excel (Save File) | [#] | [#] | 

#### System Performance

The following charts show the system performance during the tests.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->