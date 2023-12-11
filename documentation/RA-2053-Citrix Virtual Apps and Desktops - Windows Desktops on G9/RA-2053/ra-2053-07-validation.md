# Citrix Virtual Apps and Desktops on Nutanix Test Validation

This section provides the details and results of our Citrix Virtual Apps and Desktops performance tests on XXXX with Nutanix AHV. We ran each test scenario at least 3 times to ensure accuracy.

## Test Objectives

Our objective was to determine the session capacity we could host on Nutanix using a Windows VDA image and running the Login Enterprise tests with Citrix Virtual Apps and Desktops. We tested with the Login Enterprise Knowledge Worker profile.

We had the following specific objectives:

- Determine the maximum number of sessions we can host on this system with the Login Enterprise Knowledge Worker workload while maintaining a good EUX Score.
- Show the linear scalability of the Nutanix platform.
- Show the differences between MCS and Citrix Provisioning on the Nutanix platform.

## Considerations for Test Results

- We used Citrix MCS and PVS to deploy the Windows Server VMs to validate linear scalability.
- We used XXXX to test the infrastructure with Login Enterprise.
- We tested using a single, full-HD screen as the client and limited the frames per second to 16. Using multiple screens or other screen resolution settings affects the results.

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

The following graphs show the linear scalability of the test runs. We performed the tests with 1, 2, 4, 6, and 8 nodes with XXXX VMs per node. The results show good EUX Scores in all scenarios.

### EUX Scores

The following charts show the EUX Scores during the tests.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

### Steady State Scores

The following charts detail the EUX Score during the steady state.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

### Logon Time Scores

The following graphs show the linear scalability of logon times over the test runs. A lower result represents better performance.

<!-- Currently, we put images here without explanatory text. Would love to do something else. -->

### Application Performance

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
| Microsoft Edge (Logon) | [#] | [#] | [#] | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | [#] | [#] | [#] |
| Microsoft Excel (Save File) | [#] | [#] | [#] | [#] | [#] |

## Power Consumption

During the 8-node test, we monitored one node's power usage. The following chart shows this host's power usage over the test duration.

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

The next chart shows the power usage during the steady state of the test.

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

On average, the host used [#] Watts (W) during the steady state. The [#]-node cluster used [#] W on average during the steady state with [#] active users.

## MCS vs. Citrix Provisioning

In this section, we compare the results of a Login Enterprise test on 8 nodes, using MCS and Citrix Provisioning as the deployment methods.

### EUX Scores

The following chart shows the EUX Base scores from the tests. A higher score indicates a better end-user experience.

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

The following charts detail the EUX Scores during the tests.

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

### Steady State Scores

The following chart details the EUX Scores during the steady state.

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

### Logon Time Scores

The following graph shows the linear scalability of logon time performance over the test runs.

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

### Application Performance

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
| Microsoft Edge (Logon) | [#] | [#] |
| Microsoft Word (Open Doc) | [#] | [#] | 
| Microsoft Excel (Save File) | [#] | [#] | 

The following graphs show Login Enterprise EUX–specific measurements, where a higher score is better.

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

### CPU Usage

The next chart compares the cluster CPU usage during the test.

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

### Cluster Controller IOPS

The next chart shows the difference in the cluster controller IOPS.

![IMAGE CAPTION](../images/imageX.png "IMAGE CAPTION")

## Nutanix G8 vs G9 Nodes

The following section describes the difference between the Nutanix G8 and a Nutanix G9 hardware.
