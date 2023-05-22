# Test Validation

Below you will find the detail and results of the performance testing completed for Citrix Virtual Apps and Desktops for the Windows Desktop Operating System on vSphere. Each test scenario was run a minimum of 3 times to ensure accuracy.

## Test Objectives
The overall objective was to determine the session capacity we could host on Nutanix using a Windows 10, version 22H2 image and running the Login Enterprise tests with Citrix Virtual Apps and Desktops. We tested with the Login Enterprise knowledge worker profiles.

Our specific objectives were to:

- Determine the time to provision 1,380 desktops on six nodes.
- Determine the maximum number of sessions we can host on this system.
- Determine the maximum number of sessions we can host on this system with the Power Worker workload.
- Determine the maximum number of sessions we can host in a steady-state situation with the CPU usage below its maximum of 80 percent.
- Show the linear scalability of the Nutanix platform.
- Determine the impact of adding Nutanix Files to the Nutanix cluster and using it to store the user’s FSLogix Profile Container.
- Show the differences between MCS and PVS on the Nutanix platform.

## Considerations for Test Results

- We used Citrix MCS to deploy the Windows 10 desktops to validate linear scalability and FSLogix.
- We used Windows 10, version 22H2 to test the infrastructure with Login Enterprise.
- We didn’t enable the Side-Channel-Aware scheduler in VMware vSphere ESXi, and the mitigation for CVE-2018-12207 is disabled by default on ESXi. Enabling these mitigations on the hypervisor affects the performance of VDI- and RDSH-based workloads.
- We tested using a single, full-HD screen as the client and limited the frames per second (FPS) to 16. Using multiple screens or other screen resolution settings affects the results.

## Boot Storm Simulation

The following section will show the performance details during a boot storm simulation test.

### Machine Creation Services - 8 Nodes

Test Run Detail: 8 nodes with 1120 VMs (140 VMs per node)

| Hosting Connection Setting | Detail | 
| --- | --- |
| Simultaneous Actions (Absolute) | 100 |
| Simultaneous Actions (Percentage) | 40 % |
| Max New Actions per Minute (Absolute) | 50 |

![MCS 8 Node Boot Time](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image06.png "MCS 8 Node Boot Time")

![MCS 8 Node CPU Usage](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image07.png "MCS 8 Node CPU Usage")

![MCS 8 Node IOPS](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image08.png "MCS 8 Node IOPS")

### Provisioning Services - 8 Nodes

Test Run Detail: 8 nodes with 1120 VMs (140 VMs per node)

| Hosting Connection Setting | Detail | 
| --- | --- |
| Simultaneous Actions (Absolute) | 100 |
| Simultaneous Actions (Percentage) | 40 % |
| Max New Actions per Minute (Absolute) | 50 |

![PVS 8 Node Boot Time](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image09.png "PVS 8 Node Boot Time")

![PVS 8 Node CPU Usage](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image10.png "PVS 8 Node CPU Usage")

![PVS 8 Node IOPS](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image11.png "PVS 8 Node IOPS")

### Boot Storm Comparison

Below you can see the comparison between MCS and PVS with regard to the boot storm simulation test.

![8 Node Boot Time](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image12.png "8 Node Boot Time")

![8 Node CPU Usage](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image13.png "8 Node CPU Usage")

![8 Node IOPS](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image14.png "8 Node IOPS")

## Linear scalability

The following graphs will show the linear scalability detail for the test runs. The tests were performed with 1, 2, 4, 6 and 8 nodes to ensure accuracy.

### EUX Scores

The following 2 charts detail the EUX Scores during the entire test

![EUX Score](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image15.png "EUX Score")

![EUX Score Bar Chart](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image16.png "EUX Score Bar Chart")

### Steady State Scores

The following 2 chart details the EUX Score during the steady state

![EUX Score Steady State](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image17.png "EUX Score Steady State")

![EUX Score Steady State Bar Chart](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image18.png "EUX Score Steady State Bar Chart")

### Logon Time Scores

The following graphs will show the linear scalability detail for login performance over the test runs. The tests were performed with 1, 2, 4, 6 and 8 nodes to ensure accuracy.

![Logon Performance Bar Chart](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image19.png "Logon Performance Bar Chart")

![Logon Performance Total Time](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image20.png "Logon Performance Total Time")

### Application Performance

The following table shows the linear scalability detail for application performance over the test runs. The tests were performed with 1, 2, 4, 6 and 8 nodes to ensure accuracy.

| Application Name (Start Time - Seconds) | 1 Node | 2 Node | 4 Node | 6 Node | 8 Node | 
| --- | --- | --- | --- | --- | --- |
| Outlook | 4.45 | 4.60 | 4.82 | 4.95 | 5.18 |
| Word | 1.10 | 1.10 | 1.10 | 1.14 | 1.15 |
| Excel | 1.54 | 1.61 | 1.68 | 1.73 | 1.77 |
| Powerpoint | 1.39 | 1.43 | 1.47 | 1.52 | 1.54 |

| Application Name (Action - Seconds) | 1 Node | 2 Node | 4 Node | 6 Node | 8 Node | 
| --- | --- | --- | --- | --- | --- |
| Microsoft Edge (Logon) | 0.19 | 0.19 | 0.19 | 0.20 | 0.20 |
| Microsoft Word (Open Doc) | 1.26 | 1.27 | 1.29 | 1.33 | 1.34 |
| Microsoft Excel (Save File) | 0.64 | 0.63 | 0.62 | 0.62 | 0.61 |
  
## MCS vs PVS

Test Run Detail: 8 nodes with 1120 VMs (140 VMs per node) for both MCS and PVS.

| Hosting Connection Setting | Detail | 
| --- | --- |
| Simultaneous Actions (Absolute) | 100 |
| Simultaneous Actions (Percentage) | 40 % |
| Max New Actions per Minute (Absolute) | 50 |

![MCS vs PVS EUX Base](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image21.png "MCS vs PVS EUX Base")

![MCS vs PVS EUX Score](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image22.png "MCS vs PVS EUX Score")

![MCS vs PVS EUX Score Line Graph](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image23.png "MCS vs PVS EUX Score Line Graph")

![MCS vs PVS EUX Steady State](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image24.png "MCS vs PVS EUX Steady State")

![MCS vs PVS Cluster CPU](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image25.png "MCS vs PVS Cluster CPU")

![MCS vs PVS IOPS](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image26.png "MCS vs PVS IOPS")

![MCS vs PVS Logon Time](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image27.png "MCS vs PVS Logon Time")

| Application Name (Start Time - Seconds) | MCS | PVS | 
| --- | --- | --- | 
| Outlook | 5.18 | 3.18 | 
| Word | 1.15 | 0.80 | 
| Excel | 1.77 | 1.38 |
| Powerpoint | 1.54 | 1.10 | 

| Application Name (Action - Seconds) | MCS | PVS | 
| --- | --- | --- | 
| Microsoft Edge (Logon) | 0.20 | 0.10 |
| Microsoft Word (Open Doc) | 1.30 | 1.00 | 
| Microsoft Excel (Save File) | 0.61 | 0.44 | 

![Disk AppData](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image28.png "Disk AppData")

![Disk MyDocs](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image29.png "Disk MyDocs")

## FSLogix (Nutanix Files co-located) vs FSLogix (Nutanix Files dedicated)

Test Run Detail: 8 nodes with 1120 VMs (140 VMs per node) FSLogix Profile exists on file server already (not first login).

| Hosting Connection Setting | Detail | 
| --- | --- |
| Simultaneous Actions (Absolute) | 100 |
| Simultaneous Actions (Percentage) | 40 % |
| Max New Actions per Minute (Absolute) | 50 |

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

For this test, users had an existing profile stored in an FSLogix container, and we hosted Nutanix Files on the same Nutanix cluster as the desktops. Because this setup affects the overall CPU usage of the cluster nodes, we decreased the number of sessions to 1,000.

![Nutanix Files Co Located IOPS](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image37.png "Nutanix Files Co Located IOPS")

![Nutanix Files Co Located Latency](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image38.png "Nutanix Files Co Located Latency")

![Nutanix Files Co Located Throughput](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image39.png "Nutanix Files Co Located Throughput")

### Nutanix Files Hosted on the Infrastructure Cluster (dedicated)
In this scenario, we also used FSLogix Profile Containers for the user profiles and stored them on a Nutanix Files share. This time, we hosted Nutanix Files on the infrastructure cluster. This setup doesn’t affect the overall CPU usage of the cluster nodes hosting the virtual desktops.

![Nutanix Files Dedicated IOPS](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image40.png "Nutanix Files Dedicated IOPS")

![Nutanix Files Dedicated Latency](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image41.png "Nutanix Files Dedicated Latency")

![Nutanix Files Dedicated Throughput](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image42.png "Nutanix Files Dedicated Throughput")

### FSLogix Performance Comparison

![FSLogix Cluster CPU](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image30.png "FSLogix Cluster CPU")

![FSLogix Cluster IOPS](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image31.png "FSLogix Cluster IOPS")

![FSLogix Login Time](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image32.png "FSLogix Login Time")

![FSLogix Profile Load](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image33.png "FSLogix Profile Load")

![FSLogix EUX Steady State](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image34.png "FSLogix EUX Steady State")

![FSLogix AppData](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image35.png "FSLogix AppData")

![FSLogix MyDocs](../images/RA-2022-Citrix_Virtual_Apps_and_Desktops_Windows_Desktops_on_vSphere_image36.png "FSLogix MyDocs")
