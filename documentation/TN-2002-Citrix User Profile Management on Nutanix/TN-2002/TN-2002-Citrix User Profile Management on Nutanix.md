# Executive Summary

Because Nutanix AOS can withstand hardware failures and software glitches, it ensures that application availability and performance are never compromised.

![Overview of the Nutanix Hybrid Multicloud Software](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image01.png "Overview of the Nutanix Hybrid Multicloud Software")

In this tech note, we test and outline storage considerations for Citrix User Profile Management (specifically container technology) deployed on Nutanix AHV. We consider dedicated storage options on Nutanix Files or storing user profile data. 

# Introduction

## Audience

This tech note is part of the Nutanix Solutions Library. We wrote it for individuals responsible for designing, building, managing, and supporting Citrix User Profile Management on Nutanix infrastructures. Readers should be familiar with Nutanix AOS, Prism, AHV, and Files along with Citrix User Profile Management components.

## Purpose

This document covers the following subject areas:

- Overview of the Nutanix Files solution.
- Overview of the Citrix User Profile Management solution.
- Nutanix Files baseline testing.
- Citrix User Profile Management Container testing.
- Considerations for Citrix User Profile Management on Nutanix.

Traditionally, Storage Latency, Performance and Profile Size has been a focal point for Citrix User Profile Management deployments with a preference for small, highly tuned profiles and performant storage. We wanted to understand if Nutanix Files could provide an alternative approach and greater resilience when deploying Citrix User Profile Management Container technology running on Nutanix software.

## Document Version History

| **Version Number** | **Published** | **Notes** |
| :---: | --- | --- |
| 1.0 | October 2023 | Original publication. |

# Nutanix Files

Nutanix Files is a software-defined, scale-out file storage solution that provides a repository for unstructured data, such as home directories, user profiles, departmental shares, application logs, backups, and archives. Flexible and responsive to workload requirements, Files is a fully integrated, core component of Nutanix.

You can deploy Nutanix Files on an existing or standalone cluster. Unlike standalone NAS appliances, Files consolidates VM and file storage, eliminating the need to create an infrastructure silo. Administrators can manage Files with Nutanix Prism, just like VM services, which unifies and simplifies management. Integration with Active Directory enables support for quotas and access-based enumeration (ABE), as well as self-service restores with the Windows Previous Versions feature. Nutanix Files also supports native remote replication and file server cloning, which lets you back up Files off-site and run antivirus scans and machine learning without affecting production.

Nutanix Files can run on a dedicated cluster or be co-located on a cluster running user VMs. Nutanix supports Files with both ESXi and AHV. Files includes native high availability and uses AOS storage for intracluster data resiliency. AOS storage also provides data efficiency techniques such as erasure coding (EC-X).

Nutanix Files includes File Analytics, which gives you a variety of useful insights into your data, including full audit trails, anomaly detection, ransomware detection and intelligence, data age analytics, and custom reporting. You can also leverage Nutanix Data Lens to provide deeper insights and more robust ransomware protection for your Nutanix Files environment. Data Lens provides analytics and ransomware defense at scale for Nutanix Unified Storage.

# Citrix User Profile Management

[Citrix User Profile Management](https://docs.citrix.com/en-us/profile-management/current-release.html) is intended as a profile solution for Citrix DaaS Virtual Servers and Desktops as well as Physical Endpoints. The best way of choosing the right set of policy selections to suit your profile deployment is to answer the questions on [decide on a configuration](https://docs.citrix.com/en-us/profile-management/current-release/plan/configuration.html) article.

## Citrix User Profile Management Components

Citrix User Profile Management consists of several key concepts and components outlined below:

[Citrix Client Side Components](https://docs.citrix.com/en-us/profile-management/current-release/install-and-set-up/install.html)
: Citrix User Profile Management client side software is an optional component of the VDA installer. You can install it alongside the VDA or as a separate component.

[User Profile Store](https://docs.citrix.com/en-us/profile-management/current-release/install-and-set-up/create-user-store.html)
: A central file share to store the user profiles. This needs to have a low latency connection to the user VDA's as well as be highly performant.

[User Profile Policy](https://docs.citrix.com/en-us/profile-management/current-release/policies/settings.html)
: Microsoft Group Policy, Citrix Policy or ini file settings to control the behavior of Citrix User Profile Management.

## Citrix User Profile Management Test Environment

For our validation and testing, we utilized the 2203 CU2 of Citrix User Profile Management, and we deployed all components on-premises on Nutanix AHV. 

| Component | Product Version | Operating System | Quantity | CPU/Memory |
| --- | --- | --- | --- | --- |
| Citrix Delivery Controllers | 2203 LTSR CU2 | Windows Server 2022 | 2 | 4vCPU/8GiB |
| Microsoft Active Directory | Functional Level 2016 | Windows Server 2016 | 2 | 4vCPU/8GiB |
| User Profile Store | 4.3.0 | Nutanix AHV | 3 | 4vCPU/12GiB |

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
- Citrix Virtual Delivery Agent 2203 CU2
- Citrix Optimizer used for optimization

The image build was automated, and a snapshot was taken to be used with Machine Creation Services provisioning.

# Testing Logic

## Login Enterprise

We used Login Enterprise 5.1.2 to perform multiple 1000 concurrent session tests against the environment. EUX 2023 was enabled for the tests.

We utilized the following personas:
- [Knowledge Worker 2022](https://support.loginvsi.com/hc/en-us/articles/6949191203740-Knowledge-Worker-Out-of-the-box)

Each test was run twice, and the user profiles were deleted prior to starting the test. The reasoning behind this was to measure the "new user profile creation" on run 1 and "existing user profile" on run 2.

First we ran testing on different configurations of Nutanix Files to obtain the best configuration for the file server, then moving on we tested various configurations for Citrix User Profile Management. During the creation of this Technote we focussed on the container technology that Citrix offer as part of its profile management solution.

## Citrix User Profile Base Settings

The following options were enabled as part of the Citrix User Profile Management Group Policy base configuration.

| Setting | State | 
| --- | --- |
| Active Write Back | Disabled | 
| Active Write Back Registry | Disabled |
| Enable Profile Management | Enabled |
| Path to User Store | Nutanix Files SMB Share |
| Processed Groups | Domain Users |
| Profile Streaming | Enabled |
| Profile Container | Enabled with * to include |

# Test Results

## Nutanix Files Configuration Tests

The purpose of these tests was to determine the best configuration for Nutanix Files. The following configurations were tested.

- Distributed Share with Access Based Enumeration, Continuous Availability and Encryption Off
- Distributed Share with Access Based Enumeration On
- Distributed Share with Continuous Availability On
- Distributed Share with Encryption On
- Distributed Share with Access Based Enumeration, Continuous Availability and Encryption On

![Cluster CPU Usage](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image02.png "Cluster CPU Usage")

![Cluster IOPS Usage](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image03.png "Cluster IOPS Usage")

![Total Login Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image04.png "Total Login Time")

![Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image05.png "Edge Logon")

As you can see from the above there is minimal difference in performance when enabling the 3 additional features within Nutanix Files. Therefore, it is our recommendation that you enable all 3 options when creating a User Profile share as well as ensuring the share is distributed.

| Component | Setting |
| --- | --- |
| Storage Container: Access Based Enumeration | Enabled |
| Storage Container: Encryption | Enabled |
| Storage Container: Continuous Availability | Enabled |

## Citrix User Profile Management Configuration Tests

### Full Profile Caching vs No Caching

The following graphs show the impact on Nutanix Files of enabling the ```Enable local caching for profile containers```, for more information about this setting please read the following [link](https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/policies/reference/profile-management/profile-container-policy-settings.html)

![Caching Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image06.png "Caching Cluster CPU")

![Caching Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image07.png "Caching Cluster IOPS")

![Caching Login Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image08.png "Caching Login Time")

![Caching Login Profile Load](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image09.png "Caching Login Profile Load")

![Caching Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image10.png "Caching Files IOPS")

![Caching Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image11.png "Caching Files Throughput")

### Large Profile Load Impact

For this test we artificially loaded the profile at logon for all 1000 users. We wanted to test the performance of Nutanix Files under heavy load, mirroring a login storm with a large amount of data being moved around during the login phase. We tested this scenario with caching turned on then with caching turned off.

The following dataset was copied directly into the user profile container at login

| Component | Size |
| --- | --- |
| Citrix DaaS Installer ISO File | 2.84 GiB |
| 1000 small Files and 16 Folders | 5.46 MB |

#### Caching On

![Large Profile - Caching On - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image12.png "Large Profile - Caching On - Cluster CPU")

![Large Profile - Caching On - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image13.png "Large Profile - Caching On - Cluster IOPS")

![Large Profile - Caching On - Logon Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image14.png "Large Profile - Caching On - Logon Time")

![Large Profile - Caching On - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image15.png "Large Profile - Caching On - Files IOPS")

![Large Profile - Caching On - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image16.png "Large Profile - Caching On - Files Throughput")

![Large Profile - Caching On - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image17.png "Large Profile - Caching On - Files Latency")

![Large Profile - Caching On - Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image18.png "Large Profile - Caching On - Edge Logon")

![Large Profile - Caching On - Word Start](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image19.png "Large Profile - Caching On - Word Start")

#### Caching Of

![Large Profile - Caching Off - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image20.png "Large Profile - Caching Off - Cluster CPU")

![Large Profile - Caching Off - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image21.png "Large Profile - Caching Off - Cluster IOPS")

![Large Profile - Caching Off - Logon Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image22.png "Large Profile - Caching Off - Logon Time")

![Large Profile - Caching Off - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image23.png "Large Profile - Caching Off - Files IOPS")

![Large Profile - Caching Off - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image24.png "Large Profile - Caching Off - Files Throughput")

![Large Profile - Caching Off - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image25.png "Large Profile - Caching Off - Files Latency")

![Large Profile - Caching Off - Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image26.png "Large Profile - Caching Off - Edge Logon")

![Large Profile - Caching Off - Word Start](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image27.png "Large Profile - Caching Off - Word Start")

### Replicate User Stores - Separate Files Cluster

For this test we set the option to `Replicate User Stores` at logoff. More information on this setting can be found [here](https://docs.citrix.com/en-us/profile-management/current-release/configure/replicate-user-stores.html).

#### Caching On

![Replicate Profile - Caching On - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image28.png "Replicate Profile - Caching On - Cluster CPU")

![Replicate Profile - Caching On - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image29.png "Replicate Profile - Caching On - Cluster IOPS")

![Replicate Profile - Caching On - Logon Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image30.png "Replicate Profile - Caching On - Logon Time")

![Replicate Profile - Caching On - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image31.png "Replicate Profile - Caching On - Files IOPS")

![Replicate Profile - Caching On - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image32.png "Replicate Profile - Caching On - Files Throughput")

![Replicate Profile - Caching On - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image33.png "Replicate Profile - Caching On - Files Latency")

![Replicate Profile - Caching On - Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image34.png "Replicate Profile - Caching On - Edge Logon")

![Replicate Profile - Caching On - Word Start](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image35.png "Replicate Profile - Caching On - Word Start")

#### Caching Off

![Replicate Profile - Caching Off - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image36.png "Replicate Profile - Caching Off - Cluster CPU")

![Replicate Profile - Caching Off - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image37.png "Replicate Profile - Caching Off - Cluster IOPS")

![Replicate Profile - Caching Off - Logon Time](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image38.png "Replicate Profile - Caching Off - Logon Time")

![Replicate Profile - Caching Off - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image39.png "Replicate Profile - Caching Off - Files IOPS")

![Replicate Profile - Caching Off - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image40.png "Replicate Profile - Caching Off - Files Throughput")

![Replicate Profile - Caching Off - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image41.png "Replicate Profile - Caching Off - Files Latency")

![Replicate Profile - Caching Off - Edge Logon](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image42.png "Replicate Profile - Caching Off - Edge Logon")

![Replicate Profile - Caching Off - Word Start](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image43.png "Replicate Profile - Caching Off - Word Start")

### VHD Compression

This test was to determine the impact on Nutanix Files during the logoff phase where the option to `Enable VHD compression` was turned on. During the login phase we stripped the profile of the below data to allow for the creation of white space in the profile for compression.

| Component | Size |
| --- | --- |
| Citrix DaaS Installer ISO File | 2.84 GiB |
| 1000 small Files and 16 Folders | 5.46 MB |

#### Caching On

![VHD Compression - Caching On - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image49.png "VHD Compression - Caching On - Cluster CPU")

![VHD Compression - Caching On - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image50.png "VHD Compression - Caching On - Cluster IOPS")

![VHD Compression - Caching On - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image51.png "VHD Compression - Caching On - Files IOPS")

![VHD Compression - Caching On - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image52.png "VHD Compression - Caching On - Files Throughput")

![VHD Compression - Caching On - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image53.png "VHD Compression - Caching On - Files Latency")

#### Caching Off

![VHD Compression - Caching Off - Cluster CPU](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image44.png "VHD Compression - Caching Off - Cluster CPU")

![VHD Compression - Caching Off - Cluster IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image45.png "VHD Compression - Caching Off - Cluster IOPS")

![VHD Compression - Caching Off - Files IOPS](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image46.png "VHD Compression - Caching Off - Files IOPS")

![VHD Compression - Caching Off - Files Throughput](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image47.png "VHD Compression - Caching Off - Files Throughput")

![VHD Compression - Caching Off - Files Latency](../images/TN-2002-Citrix%20User%20Profile%20Management%20on%20Nutanix_image48.png "VHD Compression - Caching Off - Files Latency")


# Conclusion

The following sections identify learnings and summary points.

## Nutanix Infrastructure

- All Flash, as expected, performed well when dealing with the requirements for Citrix User Profile Management Containers.
- Based on our findings, at scale, all-flash deployments are most suited to Citrix User Profile Management deployments.
- Distributed shares level out the load that the Nutanix File Server VMs have to process. As such, Nutanix recommends using Distributed Shares when storing Citrix User Profile Management Containers on Nutanix Files.

## Citrix User Profile Management Containers

- When sizing for a Citrix UPM deployment it is critical to consider the option for enabling or disabling caching.
  - When caching is enabled we saw the CPU and IPOS load increase on the cluster that your VDAs will be running on regardless of where the user profile store is located. This needs to be considered when sizing the cluster for your VDAs.
  - When caching was disabled we saw the CPU and IOPS load move to the dedicated Files Cluster thus reducing the contention on the cluster with the VDAs present.
- When configuring the User Profile store on Nutanix Files Nutanix recommends turning on the following 3 options as the impact is minimal for the additional features you will gain.
  - Access Based Enumeration.
  - Continuous Availability.
  - Encryption.
- Whilst the File Server VM sizing was good for the testing we were running, Nutanix recommends monitoring your File Server VMs and either scale up or scale out depending on the requirements and constraints of your business.
- Heavy workloads and logon storms will directly impact scale considerations.
- When loading a profile container at logon we saw an increase in the IOPS and Nutanix Files throughput however the application launch times during the test were still performing at an acceptable level.
- When enabling profile replication or VHDX compression we saw an increase in throughput and latency at logoff that should be considered when sizing for Citrix UPM.


