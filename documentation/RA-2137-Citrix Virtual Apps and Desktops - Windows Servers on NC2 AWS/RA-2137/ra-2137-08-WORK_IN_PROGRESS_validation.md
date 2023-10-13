# Test Validation

Below you will find the detail and results of the performance testing completed for Citrix Virtual Apps and Desktops for the Windows Server Operating System on NC2 in AWS. Each test scenario was run a minimum of 3 times to ensure accuracy.

## Test Objectives
The overall objective was to determine the session capacity we could host on Nutanix Cloud Clusters using a Windows Server, version 21H2 image and running the Login Enterprise tests with Citrix Virtual Apps and Desktops. We tested with the Login Enterprise knowledge worker profile.

Our specific objectives were to:

- Determine the maximum number of sessions we can host on this system with the Login Enterprise Knowledge worker workload while maintaining a good EUX score.
- Determine the maximum number of users we can host in a steady-state situation with the CPU usage at its maximum of 85 percent.
- Show the linear scalability of the Nutanix platform.
- Show the differences between MCS and PVS on the Nutanix platform.


## Considerations for Test Results

- We used Citrix MCS to deploy the Windows Server VMs to validate linear scalability.
- We used Windows Server 2022, version 21H2 to test the infrastructure with Login Enterprise.
- We hosted 20 VMs per node with 10 users per VM.
- We tested using a single, full-HD screen as the client and limited the frames per second (FPS) to 16. Using multiple screens or other screen resolution settings affects the results.

## Linear scalability

The following graphs will show the linear scalability detail for the test runs. The tests were performed with 1, 2, 4, 6 and 8 nodes with 10 VMs per node and 135 sessions per node. The results show good EUX scores in all scenarios.

### EUX Scores

The following two charts detail the EUX Scores during the entire tests:

![EUX Score](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image06.png "EUX Score")

![EUX Score Bar Chart](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image07.png "EUX Score Bar Chart")

### Steady State Scores

The following two chart details the EUX Score during the steady state:

![EUX Score Steady State](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image08.png "EUX Score Steady State")

![EUX Score Steady State Bar Chart](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image09.png "EUX Score Steady State Bar Chart")

### Logon Time Scores

The following graphs will show the linear scalability detail for logon performance over the test runs. A lower result is better:

![Logon Performance Bar Chart](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image10.png "Logon Performance Bar Chart")

![Logon Performance Total Time](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image11.png "Logon Performance Total Time")

### Application Performance

The following table shows the linear scalability detail for application performance over the test runs. A lower result is better.

| Application Name (Start Time) - Seconds | 1 Node | 2 Node | 4 Node | 6 Node | 8 Node | 
| --- | --- | --- | --- | --- | --- |
| Outlook | 1.95 | 1.98 | 2.03 | 2.02 | 2.05 |
| Word | 0.87 | 0.86 | 0.87 | 0.86 | 0.89 |
| Excel | 0.79 | 0.80 | 0.81 | 0.81 | 0.83 |
| Powerpoint | 0.77 | 0.78 | 0.78 | 0.78 | 0.80 |

| Application Name (Action) - Seconds | 1 Node | 2 Node | 4 Node | 6 Node | 8 Node | 
| --- | --- | --- | --- | --- | --- |
| Microsoft Edge (Logon) | 0.05 | 0.05 | 0.05 | 0.05 | 0.05 |
| Microsoft Word (Open Doc) | 0.95 | 0.96 | 0.95 | 0.96 | 0.96 |
| Microsoft Excel (Save File) | 0.42 | 0.41 | 0.42 | 0.41 | 0.42 |

## MCS vs PVS

In this section we compare the results of a Login Enterprise test on 8 nodes, using MCS and PVS as the deployment method. 
Test Run Detail: 8 nodes with 80 VMs (135 sessions per node) for both MCS and PVS.

### EUX Scores
The following chart details the EUX Base score of the test (a higher score is better):

![MCS vs PVS EUX Base](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image14.png "MCS vs PVS EUX Base")

The following two charts detail the EUX Scores during the entire test:

![MCS vs PVS EUX Score](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image15.png "MCS vs PVS EUX Score")

![MCS vs PVS EUX Score Line Graph](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image16.png "MCS vs PVS EUX Score Line Graph")

### Steady State Scores

The following chart details the EUX Score during the steady state:

![MCS vs PVS EUX Steady State](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image17.png "MCS vs PVS EUX Steady State")

The next chart compares the cluster CPU usage during the test:

### Logon Time Scores

The following graphs will show the linear scalability detail for login performance over the test runs.

![MCS vs PVS Logon Time](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image18.png "MCS vs PVS Logon Time")

### Application Performance
The following table shows the linear scalability detail for application performance.

| Application Name (Start Time - Seconds) | MCS | PVS | 
| --- | --- | --- | 
| Outlook | 2.03 | 1.97 | 
| Word | 0.83 | 0.82 | 
| Excel | 0.80 | 0.75 |
| Powerpoint | 0.77 | 0.73 | 

| Application Name (Action - Seconds) | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Edge (Logon) | 0.05 | 0.05 |
| Microsoft Word (Open Doc) | 0.92 | 0.90 | 
| Microsoft Excel (Save File) | 0.40 | 0.41 | 

The following graphs are Login Enterprise EUX specific measurements. A higher score is better:

![Disk AppData](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image19.png "Disk AppData")

![Disk MyDocs](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image20.png "Disk MyDocs")

### CPU usage

![MCS vs PVS Cluster CPU](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image21.png "MCS vs PVS Cluster CPU")

### Cluster controller IOPS
The next chart shows the difference in Cluster Controller IOPS:

![MCS vs PVS IOPS](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image22.png "MCS vs PVS IOPS")

### Network Bandwidth

The next chart shows the network (bandwidth) usage by the AWS VPN during the test.