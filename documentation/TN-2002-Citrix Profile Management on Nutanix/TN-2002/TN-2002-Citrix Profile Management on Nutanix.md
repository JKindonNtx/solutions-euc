# Executive Summary

In this tech note, we test and outline storage considerations for Citrix Profile Management (CPM) Containers deployed on Nutanix Cloud Infrastructure (NCI). We consider storage configuration options on Nutanix Files when storing profile containers and outline the performance testing findings across common CPM configurations.

<!--Because Nutanix AOS can withstand hardware failures and software glitches, it ensures that application availability and performance are never compromised.

![Overview of the Nutanix Hybrid Multicloud Software](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image01.png "Overview of the Nutanix Hybrid Multicloud Software")
-->
# Introduction

## Audience

This tech note is part of the Nutanix Solutions Library. We wrote it for individuals responsible for designing, building, managing, and supporting Citrix Profile Management on Nutanix infrastructures. Readers should be familiar with Nutanix AOS, Prism, AHV, and Nutanix Files along with CPM components.

## Purpose

This document covers the following subject areas:

- Overview of the Nutanix Files solution.
- Overview of the Citrix Profile Management solution.
- Nutanix Files baseline testing.
- Citrix Profile Management Container testing.
- Considerations for Citrix Profile Management on Nutanix.

Traditionally in CPM deployments, when dealing with file-based profile configurations, a preference for smaller, tuned profiles exists to ensure user logon times are not impacted. In this scenario, Citrix typically recommends profile streaming is used. Primarily, IO occurs on the local endpoint where the user resides (There are exceptions to this rule, however this is the recommended and most common configuration).

With the introduction of CPM Container technology, the default considerations change to instead focus on backend Storage Latency and IO capability due to a change in read and write patterns, where all reads and writes by default occur on the backend repository (within the Container which is mounted to the machine hosting the user session). 

We wanted to understand if Nutanix Files could provide a robust, performant and resilient solution to host CPM Containers. We also wanted to understand the impact of specific settings within the CPM product which can alter the default IO location.

## Document Version History

| **Version Number** | **Published** | **Notes** |
| :---: | --- | --- |
| 1.0 | October 2023 | Original publication. |

# Nutanix Files

Nutanix Files is a software-defined, scale-out file storage solution that provides a repository for unstructured data, such as home directories, user profiles, departmental shares, application logs, backups, and archives. Flexible and responsive to workload requirements, Files is a fully integrated, core component of Nutanix.

You can deploy Nutanix Files on an existing or standalone cluster. Unlike standalone NAS appliances, Files consolidates VM and file storage, eliminating the need to create an infrastructure silo. Administrators can manage Files with Nutanix Prism, just like VM services, which unifies and simplifies management. Integration with Active Directory enables support for quotas and access-based enumeration (ABE), as well as self-service restores with the Windows Previous Versions feature. Nutanix Files also supports native remote replication and file server cloning, which lets you back up Files off-site and run antivirus scans and machine learning without affecting production.

Nutanix Files can run on a dedicated cluster or be co-located on a cluster running user VMs. Nutanix supports Files with both ESXi and AHV. Files includes native high availability and uses AOS storage for intracluster data resiliency. AOS storage also provides data efficiency techniques such as erasure coding (EC-X).

Nutanix Files includes File Analytics, which gives you a variety of useful insights into your data, including full audit trails, anomaly detection, ransomware detection and intelligence, data age analytics, and custom reporting. You can also leverage Nutanix Data Lens to provide deeper insights and more robust ransomware protection for your Nutanix Files environment. Data Lens provides analytics and ransomware defense at scale for Nutanix Unified Storage.

# Citrix Profile Management

[Citrix Profile Management](https://docs.citrix.com/en-us/profile-management/current-release/) is intended as a profile solution for Citrix Virtual Apps and Desktops and Citrix DaaS Virtual Servers and Desktops. The best way of choosing the right set of policy selections to suit your profile deployment is to answer the questions on the [decide on a configuration](https://docs.citrix.com/en-us/profile-management/current-release/plan/configuration.html) article provided by Citrix.

During this testing, we used Citrix Profile Management version 2303. An important part worth noting is that when using the container technology of this release all writes are initially written to a differencing disk (RW.VHDX) in the same location as the full profile VHDX, then at logoff, the changes are written back to the main profile container. This differs from directly attaching to the main profile VHDX file and committing all writes there.

## Citrix Profile Management Components

Citrix Profile Management consists of several key concepts and components: 

[Citrix Client Side Components](https://docs.citrix.com/en-us/profile-management/current-release/install-and-set-up/install.html)
: Citrix Profile Management client side software is an optional component of the VDA installer.

[User Profile Store](https://docs.citrix.com/en-us/profile-management/current-release/install-and-set-up/create-user-store.html)
: A central file share to store the user profiles.

[User Profile Policy](https://docs.citrix.com/en-us/profile-management/current-release/policies/settings.html)
: Microsoft Group Policy, Citrix Policy, Citrix Workspace Environment Management or ini file settings to control the behavior of Citrix Profile Management. 

## Citrix Profile Management Test Environment

For our validation and testing, we utilized the 2303 release of Citrix Profile Management combined with the 2203 LTSR CU2 release of Citrix Virtual Apps and Desktops. We deployed all components on-premises on Nutanix AHV.

<!--JK: Added a quick reference note below-->
<note>
We chose to use the current release version of CPM due to the extra features that are available in this release stream.
</note>

### Infrastructure Configuration

#### Nutanix Config

| Component | Setting |
| --- | --- |
| Platform | Nutanix AHV |
| AOS Version | 6.5.3.5 |
| AHV Version | 20220304.420 |
| Test Nodes | 8 |
| CPU Speed | 2.8 Ghz |
| Sockets per node | 2 |
| Cores per node | 48 |

#### User Profile Store Config

We deployed Nutanix Files to support the User Profile repository. We tested a single File Server configuration deployed on an All-Flash cluster.

The following configuration was used for Nutanix Files:

<!--JK: Still got the below listed as Container Settings, they are share settings though-->

| Component | Setting |
| --- | --- |
| Platform | Nutanix AHV |
| Version | 4.3.0 |
| FSVM count | 3 |
| Size | 4vCPU/12GiB |
| Share Type | Distributed |

<!--JK: We can remove the below from here, we capture them below with justification after testing (need to change to Share settings anyway)
| Storage Container: Compression | Disabled |
| Storage Container: Access Based Enumeration | Enabled |
| Storage Container: Encryption | Enabled |
| Storage Container: Continuous Availability | Enabled |
-->
#### Worker VM Config

| Component | Setting |
| --- | --- |
| Platform | Windows 10 |
| Version | 22H2-19045.2364 |
| Number of vCPUs | 1 |
| Cores per vCPU | 2 |
| Memory | 4 GiB |
| Provisioning Method | MCS |
| VDA Version | 2203.0.2000.2076 |

#### Testing Config

| Component | Setting |
| --- | --- |
| Software | Login Enterprise |
| Version | 5.1.2 |
| Number of VMs | 1000 |
| Number of Sessions | 1000 |
| Session Config | ICA |

#### Citrix Image Build

We built a fresh gold image on Nutanix AHV with the following components installed:

- Windows 10 Enterprise 22H2 
- Nutanix VirtIO Drivers 1.2.1
- Microsoft Edge Web Browser (Chromium)
- Microsoft Office 2019 Professional Plus
- Adobe Acrobat Reader DC
- Citrix Virtual Delivery Agent 2203 CU2
- Citrix Profile Management 2303
- Citrix Optimizer used for optimization

The image build was automated, and a snapshot was taken to be used with Machine Creation Services provisioning.

# Testing Logic

## Login Enterprise

We used Login Enterprise 5.1.2 to perform multiple 1000 concurrent session tests against the environment.

We utilized the following personas:

- [Knowledge Worker 2022](https://support.loginvsi.com/hc/en-us/articles/6949191203740-Knowledge-Worker-Out-of-the-box)

Initially we baselined Nutanix Files with different configuration options to identify the best configuration for the file server. We then tested various configurations associated with CPM Containers.

When we changed a CPM configuration option, we ran a corresponding test twice. We wanted to measure the impact of "new user profile creation" on Run 1 and then "existing user profile" impacts on run 2 for each change. We deleted all user profile after the second run of each test.

## Citrix Profile Management Base Settings

The following options were enabled as part of the Citrix Profile Management Group Policy base configuration.

| Setting | State | 
| --- | --- |
| Active Write Back | Disabled | 
| Active Write Back Registry | Disabled |
| Enable Profile Management | Enabled |
| Path to User Store | Nutanix Files SMB Share |
| Processed Groups | Domain Users |
| Profile Streaming | Enabled |
| Profile Container | Enabled with * to include the entire profile within the container |

<note>
Profile Streaming configurations only apply to CPM containers when using the "Enable local caching for profile containers" setting.
</note>

# Test Results

## Nutanix Files Baseline Configuration Tests
<!--JHK: Added the term baseline to give context-->
The purpose of these tests was to determine the best baseline configuration for Nutanix Files. The following configurations were tested.

_Table: Baseline Testing Files Share Configuration_

| Share Type | ABE | CA | Encryption | Graph Test Name Reference |
| --- | --- | --- | --- | --- |
| Distributed | Off | Off | Off | Windows_10_Profile_Citrix_UPM_-_All_Off |
| Distributed | On | On | On | Windows_10_Profile_Citrix_UPM_-_All_On |
| Distributed | On | Off | Off | Windows_10_Profile_Citrix_UPM_-_ABE_On |
| Distributed | Off | On | Off | Windows_10_Profile_Citrix_UPM_-_CA_On |
| Distributed | Off | Off | On | Windows_10_Profile_Citrix_UPM_-_Encrypt_On |

The below table shows the breakdown of the Cluster CPU usage during the test.

_Table: Baseline Testing Cluster CPU Usage_

| Test | Result (Average) | Difference |
| --- | --- | --- |
| Windows_10_Profile_Citrix_UPM_-_All_Off | 50.4 % | Baseline Value |
| Windows_10_Profile_Citrix_UPM_-_All_On | 51.0 % | 1.19% higher |
| Windows_10_Profile_Citrix_UPM_-_CA_On | 50.6 % | 0.39 % higher  | 
| Windows_10_Profile_Citrix_UPM_-_ABE_On | 50.8 % | 0.79 % higher |
| Windows_10_Profile_Citrix_UPM_-_Encrypt_On | 50.5 % | 0.20 % higher |

The following table shows the Cluster IOPS breakdown during the test.

_Table: Baseline Testing Cluster IOPS Usage_

| Test | Controller IOPS (Average) | Difference |
| --- | --- | --- |
| Windows_10_Profile_Citrix_UPM_-_All_Off | 19,772 | Baseline Value |
| Windows_10_Profile_Citrix_UPM_-_All_On | 20,306 | 2.69 % higher |
| Windows_10_Profile_Citrix_UPM_-_CA_On | 20,256 | 2.44 % higher | 
| Windows_10_Profile_Citrix_UPM_-_ABE_On | 20,377 | 3.06 % higher |
| Windows_10_Profile_Citrix_UPM_-_Encrypt_On | 20,276 | 2.54 % higher |

This table shows the Login Time details from the test.

_Table: Baseline Testing Logon Time_

| Test | Result (Average) | Difference |
| --- | --- | --- |
| Windows_10_Profile_Citrix_UPM_-_All_Off | 8.88 seconds | Baseline Value |
| Windows_10_Profile_Citrix_UPM_-_All_On | 9.75 seconds | 9.79 % higher |
| Windows_10_Profile_Citrix_UPM_-_CA_On | 8.95 seconds | 0.79 %  higher | 
| Windows_10_Profile_Citrix_UPM_-_ABE_On | 8.95 seconds | 0.79 % higher |
| Windows_10_Profile_Citrix_UPM_-_Encrypt_On | 9.56 seconds | 7.66 % higher |

Finally, you can see the breakdown of the Microsoft Edge Logon process start during the test.

_Table: Baseline Testing Microsoft Edge Logon_

| Test | Result (Average) | Difference |
| --- | --- | --- |
| Windows_10_Profile_Citrix_UPM_-_All_Off | 99.0 ms | Baseline Value |
| Windows_10_Profile_Citrix_UPM_-_All_On | 98.9 ms | 0.10 % lower |
| Windows_10_Profile_Citrix_UPM_-_CA_On |  98.1 ms | 0.92 % lower  | 
| Windows_10_Profile_Citrix_UPM_-_ABE_On | 97.2 ms | 1.85 % lower |
| Windows_10_Profile_Citrix_UPM_-_Encrypt_On | 98.8 ms | 0.20 % lower |

The tables above show minimal difference in performance when enabling the 3 additional features on a Nutanix File Share. 

<!--JK: These are share settings not container - have updated. Also added context with a one liner, and then removed these settings further up the document-->
Our baseline configuration based on performance and resiliency are outlined below for CPM with Nutanix Files:

_Table: Nutanix Share Configuration Baseline Settings_

| Component | Setting |
| --- | --- |
| Access Based Enumeration | Disabled |
| Encryption | Disabled |
| Continuous Availability | Enabled |
| Compression | Disabled |

<!--JK: Do we need to add any context around why disabled compression?-->

<!--JK: updated wording in the note below-->

<note>
Access Based Enumeration and Encryption may be required in some environments. Our testing identifies minimal performance impacts when enabling these features. We recommend additional testing when enabling encryption to ensure there is no inter-operability validation issues with other software products in your environment.
</note>

## Citrix Profile Management Configuration Tests

### Local Caching for Profile Containers Enabled vs Disabled

The following results show the impact on Nutanix Files when enabling the `Enable local caching for profile containers` setting. 

With the policy set to **Enabled**, each local profile serves as a local cache of its Citrix Profile Management profile container. If profile streaming is in use, locally cached files are created on demand. Otherwise, they are created during user logons. This behavior represents a key change in IO impact, where there is now both local (the instance hosting the user session), and remote (Nutanix Files) IO operations.

For more information about this setting please read the following [link](https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/policies/reference/profile-management/profile-container-policy-settings.html) 

_Table: Test Run Information_

| Test | Local Caching | 
| --- | --- |
| Windows_10_UPM_Container_2303_Caching_Baseline | Enabled | 
| Windows_10_UPM_Container_2303_Caching_Off_Baseline | Disabled |

<!--JK: I think the problem here is that without a statement, I have no idea what these graphs are showing me - Files, VDA, Workers, both? Have added a line below, is it an accurate description?-->
The below graphs show the impact on the workload cluster hosting the VDAs with both `Enable local caching for profile containers` **Enabled** and **Disabled**:

![Caching Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image02.png "Caching Cluster CPU")

![Caching Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image03.png "Caching Cluster IOPS")

_Table: Local Caching for Profile Container Enabled vs Disabled Login Time_

| Test | Local Caching | Result (Average) | Difference |
| --- | --- | --- | --- |
| Windows_10_UPM_Container_2303_Caching_Baseline | Enabled | 11.9 secs | 16.67 % slower |
| Windows_10_UPM_Container_2303_Caching_Off_Baseline | Disabled | 10.2 secs | Baseline |

_Table: Local Caching for Profile Container Enabled vs Disabled User Profile Load_

| Test | Local Caching | Result (Average) | Difference |
| --- | --- | --- | --- |
| Windows_10_UPM_Container_2303_Caching_Baseline | Enabled | 206 ms | 33.77 % slower |
| Windows_10_UPM_Container_2303_Caching_Off_Baseline | Disabled | 154 ms | Baseline |

<!--JK: I think the problem here is that without a statement, I have no idea what these graphs are showing me - Files, VDA, Workers, both? Have added a line below, is it an accurate description?-->
The below graphs shows the Nutanix Files data with both `Enable local caching for profile containers` **Enabled** and **Disabled**:

![Caching Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image04.png "Caching Files IOPS")

![Caching Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image05.png "Caching Files Throughput")

### Large Profile Data Load Impact
<!--JK: mate I've altered the wording slighty here from "Large Profile Load" to "Large Profile Data Load". Reason being is that I think it adds more context to the story, as we all know "Large" profiles aren't an issue with containers - this is more about boot storm impacts with lots of change, so I think this maybe helps? I reworded the table references too-->

For this test we artificially bloated the profile at logon for all 1000 users. We wanted to test the performance of Nutanix Files under heavy load, mirroring a login storm with a large amount of data being injected into the container during the login phase. We tested this scenario with `Enable local caching for profile containers` **Enabled** then with `Enable local caching for profile containers` **Disabled**.

_Table: Test Run Information_

| Test | Local Caching | 
| --- | --- |
| Windows_10_UPM_Container_2303_Large_Profile | Enabled | 
| Windows_10_UPM_Container_2303_Profile_Load_No_Cache | Disabled |

The following dataset was copied directly into the user profile container at login:

_Table: Large Profile Data Load Dataset_

| Component | Size |
| --- | --- |
| Citrix DaaS Installer ISO File | 2.84 GiB |
| 1000 small Files and 16 Folders | 5.46 MB |

<!--JK: I think the problem here is that without a statement, I have no idea what these graphs are showing me - Files, VDA, Workers, both? Have added a line below, is it an accurate description?-->
The below graphs show the impact on the workload cluster hosting the VDAs with both `Enable local caching for profile containers` **Enabled** and **Disabled** when loading the profile data:

![Large Profile Data Load - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image06.png "Large Profile Data Load - Cluster CPU")

![Large Profile Data Load - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image07.png "Large Profile Data Load - Cluster IOPS")

_Table: Large Profile Data Load Login Time_

| Test | Local Caching | Result (Average) | Difference |
| --- | --- | --- | --- |
| Windows_10_UPM_Container_2303_Large_Profile | Enabled | 11.2 secs | Baseline |
| Windows_10_UPM_Container_2303_Profile_Load_No_Cache | Disabled | 27.8 secs | 148.21 % slower |

The data shows that the login time is lower when enabling the `Enable local caching for profile containers` setting. During this test we deliberately loaded the system copying the dataset outlined above. This lower logon time is an expected result given the change in behavior with `local caching for profile containers`. With `Enable local caching for profile containers` **Enabled**, the large dataset is cached on the VDA first, whereas with the setting **Disabled**, the writes occur directing into the Container. It is important to note that copying almost 3GiB of data at logon is not a normal scenario. In customer environments, it is unlikely the difference will be anywhere near as high.

<!--JK: I moved the below into a statement above and out of a note box, see if it makes more sense. I changed the statement to positive language (focus on the lower value) rather than negative (focusing on the higher)>
<note>
You will notice that the login time is higher when disabling caching and may jump to the conclusion that there is an issue with caching and containers regarding login times. During this test we diliberatiy overloaded the system copying circa 3 GiB of data for each user at login. The purpose of this was to stress test the Files Cluster directly to ensure that it could still provide a sub 30 second login even under intense load.
</note>
-->

<!--JK: I think the problem here is that without a statement, I have no idea what these graphs are showing me - Files, VDA, Workers, both? Have added a line below, is it an accurate description?-->
The below graphs shows the Nutanix Files data when loading the profile data with both `Enable local caching for profile containers` **Enabled** and **Disabled**:

![Large Profile Data Load - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image08.png "Large Profile Data Load - Files IOPS")

![Large Profile Data Load - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image09.png "Large Profile Data Load - Files Throughput")

![Large Profile Data Load - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image10.png "Large Profile Data Load - Files Latency")

<!--JK: reworded this note below - see what you think. Moved it out of a note format
<note>
The above graphs shows latency rising during the login phase and then dropping off slowly. This is due to the large file copy at login then during "steady state" the Files Cluster levels the latency out. It must be noted here that at no point during the test did any of the VDAs drop connection to the Files Cluster or the Citrix Desktop.
</note>
-->
The above graphs indicate latency rising during the login phase and then dropping off slowly. This is caused by the large data load occurring during the login phase. During steady state operations, the latency is reduced and levels out. There were no evident session impacting events throughout the testing.

<!--JK: Quick note - on the graphs: IOPS shows steady state info based on the above statement, Throughput also represents this, but the files latency graph doesn't show what we want to see. It shows constant UP, and then massive down. It should probably just show us the latency on (general) overall runs to find that pattern? I think this graph set is what we want but I can't get it to load any data for the Cache run under files. My thought would be to remove this graph as it's busy and doesn't reflect what we are saying - might make more sense in a table (I did an example one below for you if you want to keep it) http://10.57.64.119:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2023&var-Month=10&var-Month=09&var-Month=08&var-DocumentName=TN-2002&var-Comment=Windows_10_UPM_Container_2303_-_Large_Profile&var-Comment=Windows_10_UPM_Container_2303_-_Profile_Load_No_Cache&var-Testname=402106_8n_A6.5.3.5_AHV_1000V_1000U_KW&var-Testname=a0b657_8n_A6.5.3.5_AHV_1000V_1000U_KW&var-Run=402106_8n_A6.5.3.5_AHV_1000V_1000U_KW_Run2&var-Run=a0b657_8n_A6.5.3.5_AHV_1000V_1000U_KW_Run2&var-Naming=Comment

_Table: Large Profile Data Load Files latency_

| Test | Local Caching | Result (Average) | Difference |
| --- | --- | --- | --- |
| Windows_10_UPM_Container_2303_Large_Profile | Enabled | < 1ms | TBD |
| Windows_10_UPM_Container_2303_Large_Profile_No_Cache | Disabled | 24.3 ms | Baseline |
-->

_Table: Large Profile Data Load Microsoft Edge Logon_

| Test | Local Caching | Result (Average) | Difference |
| --- | --- | --- | --- |
| Windows_10_UPM_Container_2303_Large_Profile | Enabled | 99.3 ms | 7.82 % slower |
| Windows_10_UPM_Container_2303_Large_Profile_No_Cache | Disabled | 92.1 ms | Baseline |

_Table: Large Profile Data Load Microsoft Word Start_

| Test | Local Caching | Result (Average) | Difference |
| --- | --- | --- | --- |
| Windows_10_UPM_Container_2303_Large_Profile | Enabled | 861 ms | Baseline |
| Windows_10_UPM_Container_2303_Large_Profile_No_Cache | Disabled | 861 ms | Baseline |

### Replicate User Stores - Separate Files Cluster

For this test we enabled the setting: `Replicate User Stores` and configured multiple backend storage locations (Nutanix Files Clusters) for the tests.

With the `Replicate User Stores` policy, you can replicate the user store to multiple paths on each user logon and logoff. Doing so provides profile redundancy and guarantees a high level of availability for user profiles. This means that IO considerations exist for multiple backend storage locations. 

More information on this setting can be found [here](https://docs.citrix.com/en-us/profile-management/2303/configure/replicate-user-stores.html).

_Table: Test Run Information_

| Test | Local Caching | 
| --- | --- |
| Windows_10_UPM_Container_2303_Profile_Replicate | Enabled | 
| Windows_10_UPM_Container_2303_Profile_Replicate_No_Cache | Disabled |

<!--JK: I think the problem here is that without a statement, I have no idea what these graphs are showing me - Files, VDA, Workers, both? Have added a line below, is it an accurate description?-->
The below graphs show the impact on the workload cluster hosting the VDAs with the `Replicate User Stores` setting **Enabled**. The graphs show the results with `local caching for profile containers` **enabled** and **disabled**:

![Replicate Profile - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image11.png "Replicate Profile - Cluster CPU")

![Replicate Profile - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image12.png "Replicate Profile - Cluster IOPS")

_Table: Replicate User Stores Login Time_

| Test | Local Caching | Result (Average) | Difference |
| --- | --- | --- | --- |
| Windows_10_UPM_Container_2303_Profile_Replicate | Enabled | 16.6 secs | 1.84 % slower |
| Windows_10_UPM_Container_2303_Profile_Replicate_No_Cache | Disabled | 16.3 secs | Baseline |

<!--JK: I think the problem here is that without a statement, I have no idea what these graphs are showing me - Files, VDA, Workers, both? Have added a line below, is it an accurate description?-->
The below graphs shows the Nutanix Files data with the `Replicate User Stores` setting **Enabled**. The graphs show the results with `local caching for profile containers` **enabled** and **disabled**:

![Replicate Profile - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image13.png "Replicate Profile - Files IOPS")

![Replicate Profile - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image14.png "Replicate Profile - Files Throughput")

![Replicate Profile - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image15.png "Replicate Profile - Files Latency")

<!--JK reworded the below note, see what you think. Also moved out of a note box
<note>
Above you can see the latency rising for the non cached test at the end of the run. This is due to the "No Cache" differential profiles being replicated to the additional Files Cluster during logoff.
</note>
-->
In the above graph (latency), the data shows a rise at the end of the test run. This is expected given the differential disks are being replicated to the additional Files Cluster during logoff

_Table: Replicate User Stores Microsoft Edge Logon_

| Test | Local Caching | Result (Average) | Difference |
| --- | --- | --- | --- |
| Windows_10_UPM_Container_2303_Profile_Replicate | Enabled | 96.2 ms | 3.85 % slower |
| Windows_10_UPM_Container_2303_Profile_Replicate_No_Cache | Disabled | 92.5 ms | Baseline |

_Table: Replicate User Stores Microsoft Word Start_

| Test | Local Caching | Result (Average) | Difference |
| --- | --- | --- | --- |
| Windows_10_UPM_Container_2303_Profile_Replicate | Enabled | 845 ms | 10.32 % slower |
| Windows_10_UPM_Container_2303_Profile_Replicate_No_Cache | Disabled | 766 ms | Baseline |

### VHD Compaction

This test was to determine the impact on Nutanix Files during the logoff phase where the option to `Enable VHD Compaction` was **enabled**. VHD disk compaction is a process that reduces the size of a VHD file by removing empty space and combining the data within the file. You can read more about this feature [here](https://docs.citrix.com/en-us/profile-management/current-release/configure/vhd-disk-compaction.html#enable-and-configure-vhd-disk-compaction-settings).

_Table: Test Run Information_

| Test | Local Caching | 
| --- | --- |
| Windows_10_UPM_Container_2303_Strip_Profile_ISO_and_Random | Enabled | 
| Windows_10_UPM_Container_2303_Profile_Strip_No_Cache | Disabled |

During the login phase we stripped the profile of the below data to allow for the creation of white space in the profile for compaction. 

| Component | Size |
| --- | --- |
| Citrix DaaS Installer ISO File | 2.84 GiB |
| 1000 small Files and 16 Folders | 5.46 MB |

<!--JK: Compaction! lol not compression! I have replaced all references for you-->

<!--JK: I think the problem here is that without a statement, I have no idea what these graphs are showing me - Files, VDA, Workers, both? Have added a line below, is it an accurate description?-->
The below graphs show the impact on the workload cluster hosting the VDAs with the `Enable VHD Compaction` setting **Enabled**. The graphs show the results with `local caching for profile containers` **enabled** and **disabled**:

![VHD Compaction - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image16.png "VHD Compaction - Cluster CPU")

![VHD Compaction - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image17.png "VHD Compaction - Cluster IOPS")

<!--JK: I think the problem here is that without a statement, I have no idea what these graphs are showing me - Files, VDA, Workers, both? Have added a line below, is it an accurate description?-->
The below graphs shows the Nutanix Files data with the `Enable VHD Compaction` setting **Enabled**. The graphs show the results with `local caching for profile containers` **enabled** and **disabled**:

![VHD Compaction - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image18.png "VHD Compaction - Files IOPS")

![VHD Compaction - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image19.png "VHD Compaction - Files Throughput")

![VHD Compaction - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image20.png "VHD Compaction - Files Latency")

# Conclusion

The following sections identify learnings and summary points.

## Nutanix Infrastructure

- All Flash, as expected, performed well when dealing with the requirements for Citrix Profile Management Containers.
- Distributed shares level out the load that the Nutanix File Server VMs have to process. As such, Nutanix recommends using Distributed Shares when storing Citrix Profile Management Containers on Nutanix Files.
- In all test scenarios, Nutanix Files performed optimally and provided an excellent user experience. <!--JK: I added this? Is it a fair statement?-->

## Citrix Profile Management Containers

- When sizing for a Citrix CPM deployment it is critical to consider the impact of "Enabling" or "Disabling: `Local Profile Container Caching`.
  - With `Local Profile Container Caching` **Disabled** the CPU and IOPS impact exists primarily on the dedicated Files cluster.
  - With `Local Profile Container Caching` **Enabled** there is an increase in both CPU and IOPS on the VDA workload cluster and a reduction on the Files Cluster.
<!--JK: See if the above makes sense - less words
  - When caching was disabled we saw the CPU and IOPS load move to the dedicated Files Cluster thus reducing the contention on the cluster with the VDAs present.
  - When caching is enabled we saw the CPU and IPOS load increase on the cluster that your VDAs run on on regardless of where the user profile store is located. This needs to be considered when sizing the cluster for your VDAs.
-->
- When configuring Nutanix File Shares, enabling Access Based Enumeration, Continuous Availability and Encryption had minimal performance impact. Nutanix recommends that you enable Continuous Availability for share resiliency.
- Whilst the File Server VM sizing was good for the testing we were running, Nutanix recommends monitoring your File Server VMs and either scale up or scale out depending on the requirements.
<!--JK: Does the below point add any value in the context of real scenarios?
- When injecting data into a profile container at logon we saw the IOPS and Nutanix Files throughput increase however the application launch times during the test were still performant. 
-->
- When enabling `Replicate User Stores` or `VHD Compaction` we saw an increase in throughput and latency at logoff due the the nature of the tasks. The impact of these settings should be considered when sizing for Nutanix Files.


