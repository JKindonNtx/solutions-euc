# Executive Summary

Because Nutanix AOS can withstand hardware failures and software glitches, it ensures that application availability and performance are never compromised.

![Overview of the Nutanix Hybrid Multicloud Software](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image01.png "Overview of the Nutanix Hybrid Multicloud Software")

In this tech note, we test and outline storage considerations for Citrix Profile Management (CPM) Containers deployed on Nutanix AHV. We consider dedicated storage options on Nutanix Files for storing user profile data.

<!--JK: Product name is now "Citrix Profile Management (CPM). I've updated -->
<!--JK: I think you will need to have table references per table  _Table: Description_  -->
<!--JK: There are some discrepancies here - we talk about using 2203 LTSR as the baseline, but the profile management features you are referencing don't exist in that version of CPM? The graphs show 2303 being used-->
<!--JK: When I look at the graphs, I am confused at what i am looking at, I think this will be solved with some captions/detais? for images. For example if you look at the ### Full Profile Caching vs No Caching section and graphs, the first two graphs show some nice data, but I think they need some context/commentary on what it's displaying  -->
<!--JK: Large Profile Impact Section. With caching On, there is logon times of 14.7 seconds (ugly graph in green) then with no cache it jumps to 27.8 seconds in a blue graph! Something very wrong there I think. Even replicate user stores didn't present like that-->
<!--JK: After just going through this exercise with RAS, I think we need to add more data tables and reduce images. The graphs are nice where they make sense, but data in the tables with differences helps with concise consumption of the info I think-->

# Introduction

## Audience

This tech note is part of the Nutanix Solutions Library. We wrote it for individuals responsible for designing, building, managing, and supporting Citrix Profile Management on Nutanix infrastructures. Readers should be familiar with Nutanix AOS, Prism, AHV, and Files along with CPM components.

## Purpose

This document covers the following subject areas:

- Overview of the Nutanix Files solution.
- Overview of the Citrix Profile Management solution.
- Nutanix Files baseline testing.
- Citrix Profile Management Container testing.
- Considerations for Citrix Profile Management on Nutanix.

Traditionally, Storage Latency, Performance <!--JK: How accurate is this? Traditionally UPM File based solutions are resilient to latency and performance challenges -> Containers are what cause the problems. See below as an option maybe--> and Profile Size has been a focal point for Citrix Profile Management deployments with a preference for small, highly tuned profiles and performant storage. We wanted to understand if Nutanix Files could provide an alternative approach and greater resilience when deploying Citrix Profile Management Container technology running on Nutanix software.

<!--JK: See what you think about the below for context setting
Traditionally in CPM deployments, when dealing with file-based profile configurations, a preference for smaller, tuned profiles exists to ensure user logon times are not impacted. In this scenario, Citrix typically recommends profile streaming is used. Primarily, IO occurs on the local endpoint where the user resides. (There are exceptions to this rule, however this is the recommended and most common configuration). With the introduction of CPM Container technology, the default considerations change to instead focus on backend Storage Latency and IO capability due to change in read and write patterns, where all reads and writes by default occur on the backend repository (within the Container which is mounted to the machine hosting the user session). We wanted to understand if Nutanix Files could provide a robust, performant and resilient solution to host CPM Containers. We also wanted to understand the impact of specific settings within the CPM product which can alter the default IO location. -->

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

[Citrix Profile Management](https://docs.citrix.com/en-us/profile-management/current-release.html) is intended as a profile solution for Citrix DaaS <!--JK: Limiting to DaaS?--> Virtual Servers and Desktops as well as Physical Endpoints <!--Relevance of physical endpoints in the context of this document?-->. The best way of choosing the right set of policy selections to suit your profile deployment is to answer the questions on [decide on a configuration](https://docs.citrix.com/en-us/profile-management/current-release/plan/configuration.html) article.

## Citrix Profile Management Components

Citrix Profile Management consists of several key concepts and components outlined below: <!--JK: We are referencing current-release documentation but only testing on LTSR components? Should we include a note around this and why?-->

[Citrix Client Side Components](https://docs.citrix.com/en-us/profile-management/current-release/install-and-set-up/install.html)
: Citrix Profile Management client side software is an optional component of the VDA installer. <!--JK: I would remove this part: You can install it alongside the VDA or as a separate component.-->

[User Profile Store](https://docs.citrix.com/en-us/profile-management/current-release/install-and-set-up/create-user-store.html)
: A central file share to store the user profiles.<!--JK: Only when dealing with containers. I would remove this part: This needs to have a low latency connection to the users VDA's as well as be highly performant.-->

[User Profile Policy](https://docs.citrix.com/en-us/profile-management/current-release/policies/settings.html)
: Microsoft Group Policy, Citrix Policy or ini file settings to control the behavior of Citrix Profile Management. <!--JK: or Citrix Workspace Environment Management-->

## Citrix Profile Management Test Environment

For our validation and testing, we utilized the 2203 LTSR CU2 release of Citrix Profile Management, and we deployed all components on-premises on Nutanix AHV. <!--JK: Placeholder comment - we only did 2203?-->

| Component | Product Version | Operating System | Quantity | CPU/Memory |
| --- | --- | --- | --- | --- |
| Citrix Delivery Controllers | 2203 LTSR CU2 | Windows Server 2022 | 2 | 4vCPU/8GiB |
| Microsoft Active Directory | Functional Level 2016 | Windows Server 2016 | 2 | 4vCPU/8GiB | <!--JK: relevance of Domain Controller spec? -->
| User Profile Store | Nutanix Files 4.3.0 | Nutanix AHV | 3 File Server VMs (FSVMs) | 4vCPU/12GiB | <!--JK: Added Nutanix stuff to give it context. Then found you have this already below - any need to duplicate it here?-->

## Infrastructure Configuration

## Nutanix Config

| Component | Setting |
| --- | --- |
| Platform | Nutanix AHV |
| AOS Version | 6.5.3.5 |
| AHV Version | 20220304.420 |
| Test Nodes | 8 |
| CPU Speed | 2.8 Ghz |
| Sockets per node | 2 |
| Cores per node | 48 |

## User Profile Store Config

We deployed Nutanix Files to support the User Profile repository. We tested a single File Server configuration based an All-Flash.

The following configuration was used for Files:

| Component | Setting |
| --- | --- |
| Platform | Nutanix AHV |
| Version | 4.3.0 |
| FSVM count | 3 |
| Size | 4vCPU/12GiB |
| Distributed share | Enabled |
| Storage Container: Compression | Disabled |
| Storage Container: Access Based Enumeration | Enabled |
| Storage Container: Encryption | Enabled |
| Storage Container: Continuous Availability | Enabled |

## Worker VM Config

| Component | Setting |
| --- | --- |
| Platform | Windows 10 |
| Version | 22H2-19045.2364 |
| Number of vCPUs | 1 |
| Cores per vCPU | 2 |
| Memory | 4 GiB |
| Provisioning Method | MCS |
| VDA Version | 2203.0.2000.2076 |

## Testing Config

| Component | Setting |
| --- | --- |
| Software | Login Enterprise |
| Version | 5.1.2 |
| Number of VMs | 1000 |
| Number of Sessions | 1000 |
| Session Config | ICA |

## Citrix Image Build

We built a fresh gold image on Nutanix AHV with the following components installed:

- Windows 10 Enterprise 22H2 
- Nutanix VirtIO Drivers 1.2.1
- Microsoft Edge Web Browser (Chromium)
- Microsoft Office 2019 Professional Plus
- Adobe Acrobat Reader DC
- Citrix Virtual Delivery Agent 2203 CU2 including the CPM components <!--JK: Seems minor, but given the context, I would include the CPM component here-->
- Citrix Optimizer used for optimization

The image build was automated, and a snapshot was taken to be used with Machine Creation Services provisioning.

# Testing Logic

## Login Enterprise

We used Login Enterprise 5.1.2 to perform multiple 1000 concurrent session tests against the environment. EUX 2023 was enabled for the tests.

We utilized the following personas:

- [Knowledge Worker 2022](https://support.loginvsi.com/hc/en-us/articles/6949191203740-Knowledge-Worker-Out-of-the-box)

<!--JK: 
Each test was run twice, and the user profiles were deleted prior to starting the test. The reasoning behind this was to measure the "new user profile creation" time on run 1 and "existing user profile" on run 2. JK: this sentence doesn't make sense - we say we delete prior to each test, but then we say we are running two tests, one to measure new, and one to measure existing"

First we ran testing on different configurations of Nutanix Files to obtain the best configuration for the file server, then moving on we tested various configurations for Citrix Profile Management. During the creation of this Technote we focussed on the container technology that Citrix offer as part of its profile management solution. -->

<!--JK: See if the below maybe makessense??-->

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
| Profile Container | Enabled with * to include |

<!--JK: Added a note below-->
<note>
Profile Streaming configurations only apply to CPM containers when using the "Enable local caching for profile containers" setting.
</note>

# Test Results

## Nutanix Files Configuration Tests

The purpose of these tests was to determine the best configuration for Nutanix Files. The following configurations were tested.

- Distributed Share with Access Based Enumeration, Continuous Availability and Encryption Off
- Distributed Share with Access Based Enumeration On
- Distributed Share with Continuous Availability On
- Distributed Share with Encryption On
- Distributed Share with Access Based Enumeration, Continuous Availability and Encryption On

<!--JK: The above bullets don't show a status for each setting - I tried putting into a small table below instead - see what you think? Else will need to update the bullets above to include On/Off for each setting-->
<!--JK: Wondering to help understand the images below, should we add a reference to the test name in the table? See Below -->

| Share Type | ABE | CA | Encryption | Graph Test Name Reference |
| --- | --- | --- | --- | --- |
| Distributed | Off | Off | Off | Windows_10_Profile_Citrix_UPM_-_All_Off |
| Distributed | On | On | On | Windows_10_Profile_Citrix_UPM_-_All_On |
| Distributed | On | Off | Off | Windows_10_Profile_Citrix_UPM_-_ABE_On |
| Distributed | Off | On | Off | Windows_10_Profile_Citrix_UPM_-_CA_On |
| Distributed | Off | Off | On | Windows_10_Profile_Citrix_UPM_-_Encrypt_On |

<!--JK: Added an example table below, wondering if this would make sense to include? Also, Would be great to have steady state data breakout?-->
_Table: Baseline Testing Cluster CPU Usage_

| Test | Result (Average) | Difference |
| --- | --- | --- |
| Windows_10_Profile_Citrix_UPM_-_All_Off | 50.4 % | Baseline Value |
| Windows_10_Profile_Citrix_UPM_-_All_On | 51.0 % | 1.19% higher |
| Windows_10_Profile_Citrix_UPM_-_CA_On | 50.6 % | 0.39 % higher  | 
| Windows_10_Profile_Citrix_UPM_-_ABE_On | 50.8 % | 0.79 % higher |
| Windows_10_Profile_Citrix_UPM_-_Encrypt_On | 50.5 % | 0.20 % higher |

![Cluster CPU Usage](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image02.png "Cluster CPU Usage")

<!--JK: Added an example table below, wondering if this would make sense to include?-->
_Table: Baseline Testing Cluster IOPS Usage_

| Test | Controller IOPS (Average) | Difference |
| --- | --- | --- |
| Windows_10_Profile_Citrix_UPM_-_All_Off | 19,772 | Baseline Value |
| Windows_10_Profile_Citrix_UPM_-_All_On | 20,306 | 2.69 % higher |
| Windows_10_Profile_Citrix_UPM_-_CA_On | 20,256 | 2.44 % higher | 
| Windows_10_Profile_Citrix_UPM_-_ABE_On | 20,377 | 3.06 % higher |
| Windows_10_Profile_Citrix_UPM_-_Encrypt_On | 20,276 | 2.54 % higher |

![Cluster IOPS Usage](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image03.png "Cluster IOPS Usage")

<!--JK: Added an example table below, wondering if this would make sense to include?-->
_Table: Baseline Testing Logon Time_

| Test | Result (Average) | Difference |
| --- | --- | --- |
| Windows_10_Profile_Citrix_UPM_-_All_Off | 8.88 seconds | Baseline Value |
| Windows_10_Profile_Citrix_UPM_-_All_On | 9.75 seconds | 9.79 % higher |
| Windows_10_Profile_Citrix_UPM_-_CA_On | 8.95 seconds | 0.79 %  higher | 
| Windows_10_Profile_Citrix_UPM_-_ABE_On | 8.95 seconds | 0.79 % higher |
| Windows_10_Profile_Citrix_UPM_-_Encrypt_On | 9.56 seconds | 7.66 % higher |

<!--JK: These graphs are ugly? Some show Total Login Time in the description but Average Login in the graphs-->
![Total Login Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image04.png "Total Login Time")

<!--JK: Added an example table below, wondering if this would make sense to include?-->
_Table: Baseline Testing Microsoft Edge Logon_

| Test | Result (Average) | Difference |
| --- | --- | --- |
| Windows_10_Profile_Citrix_UPM_-_All_Off | 99.0 ms | Baseline Value |
| Windows_10_Profile_Citrix_UPM_-_All_On | 98.9 ms | 0.10 % lower |
| Windows_10_Profile_Citrix_UPM_-_CA_On |  98.1 ms | 0.92 % lower  | 
| Windows_10_Profile_Citrix_UPM_-_ABE_On | 97.2 ms | 1.85 % lower |
| Windows_10_Profile_Citrix_UPM_-_Encrypt_On | 98.8 ms | 0.20 % lower |

![Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image05.png "Edge Logon")

The graphs above show minimal difference in performance when enabling the 3 additional features on a Nutanix File Share. It is our recommendation that you enable all 3 options when creating a User Profile share as well as ensuring the share is distributed. <!--JK: with ABE and encryption, why do we recommend this for Containers. ABE I thought was more for file based situations where users traverse a file share - in a container world, they don't have any visibility into that share anyway? Is it warranted to say we recommend it? Or should we say that customers can use all options without expected performance impact?-->

<!--JK: These are share settings rather than Container - if this is a recommendation table, you will need to caption it I think?-->
| Component | Setting |
| --- | --- |
| Storage Container: Access Based Enumeration | Enabled |
| Storage Container: Encryption | Enabled |
| Storage Container: Continuous Availability | Enabled |

## Citrix Profile Management Configuration Tests

### Full Profile Caching vs No Caching

<!--JK: can we rename these headings to align with the setting terms> Eg. Local Profile Profile Containers Enabled vs Disabled-->

The following graphs show the impact on Nutanix Files when enabling the `Enable local caching for profile containers` setting. 

With the policy set to **Enabled**, each local profile serves as a local cache of its Citrix Profile Management profile container. If profile streaming is in use, locally cached files are created on demand. Otherwise, they are created during user logons. This behavior represents a key change in IO impact, where there is now both local (the instance hosting the user session), and remote (Nutanix Files) IO operations.

For more information about this setting please read the following [link](https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/policies/reference/profile-management/profile-container-policy-settings.html) <!--JK: Tis one 100% warrants a note around the IO shift and why we are testing it. See if you are OK with the above that I injected-->

![Caching Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image06.png "Caching Cluster CPU")

![Caching Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image07.png "Caching Cluster IOPS")

<!--JK: These graphs are ugly?-->
![Caching Login Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image08.png "Caching Login Time")

![Caching Login Profile Load](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image09.png "Caching Login Profile Load")

![Caching Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image10.png "Caching Files IOPS")

![Caching Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image11.png "Caching Files Throughput")

### Large Profile Load Impact

For this test we artificially bloated the profile at logon for all 1000 users. We wanted to test the performance of Nutanix Files under heavy load, mirroring a login storm with a large amount of data being <!--JK: maybe "injected" rather than "moved around"--> moved around during the login phase. We tested this scenario with `local caching` **Enabled** then with `local caching` **Disabled**.

The following dataset was copied directly into the user profile container at login:

| Component | Size |
| --- | --- |
| Citrix DaaS Installer ISO File | 2.84 GiB |
| 1000 small Files and 16 Folders | 5.46 MB |

#### Local Caching for Profile Containers Enabled

![Large Profile - Caching On - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image12.png "Large Profile - Caching On - Cluster CPU")

![Large Profile - Caching On - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image13.png "Large Profile - Caching On - Cluster IOPS")

![Large Profile - Caching On - Logon Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image14.png "Large Profile - Caching On - Logon Time")

![Large Profile - Caching On - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image15.png "Large Profile - Caching On - Files IOPS")

![Large Profile - Caching On - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image16.png "Large Profile - Caching On - Files Throughput")

![Large Profile - Caching On - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image17.png "Large Profile - Caching On - Files Latency")

![Large Profile - Caching On - Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image18.png "Large Profile - Caching On - Edge Logon")

![Large Profile - Caching On - Word Start](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image19.png "Large Profile - Caching On - Word Start")

#### Local Caching for Profile Containers Disabled

![Large Profile - Caching Off - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image20.png "Large Profile - Caching Off - Cluster CPU")

![Large Profile - Caching Off - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image21.png "Large Profile - Caching Off - Cluster IOPS")

<!--JK: Is it logon or login time? Image descriptions differ throughout the doc -->
![Large Profile - Caching Off - Logon Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image22.png "Large Profile - Caching Off - Logon Time")

![Large Profile - Caching Off - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image23.png "Large Profile - Caching Off - Files IOPS")

![Large Profile - Caching Off - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image24.png "Large Profile - Caching Off - Files Throughput")

![Large Profile - Caching Off - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image25.png "Large Profile - Caching Off - Files Latency")

![Large Profile - Caching Off - Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image26.png "Large Profile - Caching Off - Edge Logon")

![Large Profile - Caching Off - Word Start](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image27.png "Large Profile - Caching Off - Word Start")

### Replicate User Stores - Separate Files Cluster

<!--JK: I think there is a typo somewhere in this document....This setting didn't exist for containers with the 2203 version of CPM, it was released in 2209?-->

For this test we enabled the setting: `Replicate User Stores` at logoff. 

With the `Replicate user stores` policy, you can replicate the user store to multiple paths on each user logon and logoff. Doing so provides profile redundancy and guarantees a high level of availability for user profiles. This means that IO considerations exist for multiple backend storage locations. 

More information on this setting can be found [here](https://docs.citrix.com/en-us/profile-management/current-release/configure/replicate-user-stores.html). <!--JK: Tis one 100% warrants a note around why we are testing it. See if you are OK with the above that I injected-->

#### Local Caching for Profile Containers Enabled

![Replicate Profile - Caching On - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image28.png "Replicate Profile - Caching On - Cluster CPU")

![Replicate Profile - Caching On - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image29.png "Replicate Profile - Caching On - Cluster IOPS")

![Replicate Profile - Caching On - Logon Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image30.png "Replicate Profile - Caching On - Logon Time")

![Replicate Profile - Caching On - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image31.png "Replicate Profile - Caching On - Files IOPS")

![Replicate Profile - Caching On - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image32.png "Replicate Profile - Caching On - Files Throughput")

![Replicate Profile - Caching On - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image33.png "Replicate Profile - Caching On - Files Latency")

![Replicate Profile - Caching On - Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image34.png "Replicate Profile - Caching On - Edge Logon")

![Replicate Profile - Caching On - Word Start](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image35.png "Replicate Profile - Caching On - Word Start")

#### Local Caching for Profile Containers Disabled

![Replicate Profile - Caching Off - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image36.png "Replicate Profile - Caching Off - Cluster CPU")

![Replicate Profile - Caching Off - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image37.png "Replicate Profile - Caching Off - Cluster IOPS")

![Replicate Profile - Caching Off - Logon Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image38.png "Replicate Profile - Caching Off - Logon Time")

![Replicate Profile - Caching Off - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image39.png "Replicate Profile - Caching Off - Files IOPS")

![Replicate Profile - Caching Off - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image40.png "Replicate Profile - Caching Off - Files Throughput")

![Replicate Profile - Caching Off - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image41.png "Replicate Profile - Caching Off - Files Latency")

![Replicate Profile - Caching Off - Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image42.png "Replicate Profile - Caching Off - Edge Logon")

![Replicate Profile - Caching Off - Word Start](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image43.png "Replicate Profile - Caching Off - Word Start")

### VHD Compression

<!--JK: I think there is a typo somewhere in this document....This setting didn't exist for containers with the 2203 version of CPM, it was released in 2303?-->

<!--JK: It's compaction in the Citrix world, not compression-->

This test was to determine the impact on Nutanix Files during the logoff phase where the option to `Enable VHD compression` was **enabled**. During the login phase we stripped the profile of the below data to allow for the creation of white space in the profile for compression. <!--JK: Anyway to make these graphs more concise and focused on the logoff phase impact? Maybe just the graphs that actually show impact?-->

| Component | Size |
| --- | --- |
| Citrix DaaS Installer ISO File | 2.84 GiB |
| 1000 small Files and 16 Folders | 5.46 MB |

#### Local Caching for Profile Containers Enabled

![VHD Compression - Caching On - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image49.png "VHD Compression - Caching On - Cluster CPU")

![VHD Compression - Caching On - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image50.png "VHD Compression - Caching On - Cluster IOPS")

![VHD Compression - Caching On - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image51.png "VHD Compression - Caching On - Files IOPS")

![VHD Compression - Caching On - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image52.png "VHD Compression - Caching On - Files Throughput")

![VHD Compression - Caching On - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image53.png "VHD Compression - Caching On - Files Latency")

#### Local Caching for Profile Containers Disabled

![VHD Compression - Caching Off - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image44.png "VHD Compression - Caching Off - Cluster CPU")

![VHD Compression - Caching Off - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image45.png "VHD Compression - Caching Off - Cluster IOPS")

![VHD Compression - Caching Off - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image46.png "VHD Compression - Caching Off - Files IOPS")

![VHD Compression - Caching Off - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image47.png "VHD Compression - Caching Off - Files Throughput")

![VHD Compression - Caching Off - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image48.png "VHD Compression - Caching Off - Files Latency")

# Conclusion

The following sections identify learnings and summary points.

## Nutanix Infrastructure

- All Flash, as expected, performed well when dealing with the requirements for Citrix Profile Management Containers.
- Based on our findings, at scale, all-flash deployments are most suited to Citrix Profile Management deployments. <!--JK: are these two points the same thing? This one and above?-->
- Distributed shares level out the load that the Nutanix File Server VMs have to process. As such, Nutanix recommends using Distributed Shares when storing Citrix Profile Management Containers on Nutanix Files.

## Citrix Profile Management Containers

- When sizing for a Citrix CPM deployment it is critical to consider the option for enabling or disabling caching. <!--JK: local caching rather than "caching" - what "option" are we talking about here? Do we mean impacts?-->
  - When caching is enabled we saw the CPU and IPOS load increase on the cluster that your VDAs will be running on regardless of where the user profile store is located. This needs to be considered when sizing the cluster for your VDAs.
  - When caching was disabled we saw the CPU and IOPS load move to the dedicated Files Cluster thus reducing the contention on the cluster with the VDAs present. <!--JK: I think this should be reversed in the summary because it's a non-default behaviour? So more of a "When we enable local caching, we saw a reduction on Files, and an increase on the VDAs? Thoughts?-->
- When configuring the User Profile Store on Nutanix Files, Nutanix recommends turning on the following 3 options as the impact is minimal for the additional features you will gain. <!--JK: I am still hung up on these recommendations - see below point for an suggestion?-->
  - Access Based Enumeration.
  - Continuous Availability.
  - Encryption.
<!--JK- When configuring Nutanix File Shares, enabling Access Based Enumeration, Continuous Availability and Encryption had minimal performance impact. Nutanix recommends that you enable Continuous Availability for share resiliency-->
- Whilst the File Server VM sizing was good for the testing we were running, Nutanix recommends monitoring your File Server VMs and either scale up or scale out depending on the requirements. <!--JK: I removed the next bit, talks to a negative: and constraints of your business.-->
- Heavy workloads and logon storms will directly impact scale considerations.
- When loading a profile container at logon we saw an increase in the IOPS and Nutanix Files throughput however the application launch times during the test were still performing at an acceptable level. <!--JK: an increase in comparison to what though? This statement isn't really telling me anything? Maybe reword it so just suggest that Nutanix Files handles the IO profile of containers with all test scenarios well?-->
- When enabling profile replication or VHDX compression we saw an increase in throughput and latency at logoff that should be considered when sizing for Citrix CPM. <!--JK: Compaction :) Can i suggest renaming these to the actual setting names?-->


