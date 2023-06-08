# Test Validation

Below you will find the detail and results of the performance testing completed for Citrix Virtual Apps and Desktops for the Windows Server Operating System on vSphere. Each test scenario was run a minimum of 3 times to ensure accuracy.

## Test Objectives
The overall objective was to determine the session capacity we could host on Nutanix using a Windows Server, version 21H2 image and running the Login Enterprise tests with Citrix Virtual Apps and Desktops. We tested with the Login Enterprise knowledge worker profile.

Our specific objectives were to:

- Determine the maximum number of sessions we can host on this system with the Login Enterprise Knowledge worker workload while maintaining a good EUX score.
- Show the linear scalability of the Nutanix platform.
- Show the differences between MCS and PVS on the Nutanix platform.
- Determine the impact of adding Nutanix Files to the Nutanix cluster and using it to store the user’s FSLogix Profile Container.


## Considerations for Test Results

- We used Citrix MCS to deploy the Windows Server VMs to validate linear scalability and FSLogix.
- We used Windows Server, version 21H2 to test the infrastructure with Login Enterprise.
- We didn’t enable the Side-Channel-Aware scheduler in VMware vSphere ESXi, and the mitigation for CVE-2018-12207 is disabled by default on ESXi. Enabling these mitigations on the hypervisor affects the performance of VDI- and RDSH-based workloads.
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

## Power Consumption
During the 8 nodes test, we monitored the Power usage of one of the nodes. The following chart shows the power usage of this host:

![Power Usage Full Run](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image12.png "Power Usage Full Run")

The next chart shows the power usage during the steady state of the test:

![Power Usage Steady State](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image13.png "Power Usage Steady State")

On average, the host used 748 Watts during the steady state. The 8 nodes cluster used 5,984 Watts on average during the steady state with 1,080 active users.

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

## FSLogix (Nutanix Files co-located) vs FSLogix (Nutanix Files dedicated)

Test Run Detail: 8 nodes with 80 VMs (135 sessions per node), FSLogix Profile exists on file server already (not first logon).

| Nutanix Files Setting | Detail | 
| --- | --- |
| Version | 4.2.1.1 |
| Cluster size | 3 VMs |
| vCPUs per VM | 4 |
| Memory per VM | 12 GB |

| FSLogix Setting | Detail | 
| --- | --- |
| Version | 2.9.8440.42104 |
| Configuration | Profile & Office Container |

### Nutanix Files Hosted on the Desktops Cluster (co-located)
In this scenario, we configured the user’s profile to use an FSLogix Profile Container stored on a Nutanix Files share. One of the advantages of FSLogix is that you can store the user’s profile in a VHD or VHDX file. This file is stored on a network share (in our case a share hosted on Nutanix Files) and mounted at user logon. This method can improve logon times and provide advantages for disaster recovery scenarios.

For this test, users had an existing profile stored in an FSLogix container, and we hosted Nutanix Files on the same Nutanix cluster as the desktops.
The following charts show the storage performance of the Nutanix Files cluster during the test.

![Nutanix Files Co Located IOPS](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image23.png "Nutanix Files Co Located IOPS")

![Nutanix Files Co Located Latency](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image24.png "Nutanix Files Co Located Latency")

![Nutanix Files Co Located Throughput](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image25.png "Nutanix Files Co Located Throughput")

### Nutanix Files Hosted on the Infrastructure Cluster (dedicated)
In this scenario, we also used FSLogix Profile Containers for the user profiles and stored them on a Nutanix Files share. This time, we hosted Nutanix Files on the infrastructure cluster. This setup doesn’t affect the overall CPU usage of the cluster nodes hosting the virtual desktops.
The following charts show the storage performance of the Nutanix Files cluster during the test.

![Nutanix Files Dedicated IOPS](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image26.png "Nutanix Files Dedicated IOPS")

![Nutanix Files Dedicated Latency](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image27.png "Nutanix Files Dedicated Latency")

![Nutanix Files Dedicated Throughput](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image28.png "Nutanix Files Dedicated Throughput")

### Performance Comparison
In this section we compare the results of the Login Enterprise test where the FSLogix profiles are stored on a Nutanix Files cluster co-located with the desktops with the test where the FSLogix profiles are stored on the Nutanix Files cluster hosted on a dedicated cluster.

First, the EUX scores during the steady state:
![FSLogix EUX Steady State](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image29.png "FSLogix EUX Steady State")

The next two charts show the details of the logon:
![FSLogix Logon Time](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image30.png "FSLogix Logon Time")

![FSLogix Profile Load](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image31.png "FSLogix Profile Load")

The following graphs are Login Enterprise EUX specific measurements. A higher score is better:

![FSLogix AppData](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image32.png "FSLogix AppData")

![FSLogix MyDocs](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image33.png "FSLogix MyDocs")

The cluster CPU usage of the Desktop cluster:

![FSLogix Cluster CPU](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image34.png "FSLogix Cluster CPU")

The next chart shows the cluster controller IOPS:

![FSLogix Cluster IOPS](../images/RA-2003-Citrix_Virtual_Apps_and_Desktops_Windows_Servers_on_vSphere_image35.png "FSLogix Cluster IOPS")

