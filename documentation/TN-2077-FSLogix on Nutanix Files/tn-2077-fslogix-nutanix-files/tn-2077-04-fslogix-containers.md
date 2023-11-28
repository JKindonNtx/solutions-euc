# FSLogix Containers

FSLogix enhances and enables a consistent experience for Windows user profiles in virtual desktop computing environments. FSLogix can be a complex solution with various dependencies on other systems and infrastructure

## FSLogix Components

The FSLogix solution is made up of the following components as it relates to profile containers. 

FSLogix Apps
: FSLogix Apps installs two (2) Windows services and three mini-filter drivers that enable all FSLogix components

Storage Provider
: The service or resource providing container storage. Includes legacy physical storage and Azure based storage. Storage providers are limited by the types of storage FSLogix supports.

Container
: The virtual hard disk (VHD / VHDX) file, which contains all the data for the given type of container. This can be a Profile (A type of container that holds the data and settings for users signed into a Windows based system) or ODFC (A type of container that holds only data and settings for Microsoft 365 products. ODFC data includes, but isn't limited to Outlook, Teams, OneDrive (Personal or Business), and Sharepoint).

Differencing disk
: Refers to the intermediate VHD used to track changes to the base disk. Differencing disks are merged into base disks.

For a full list of FSLogix terminology, refer to the [Microsoft Documentation](https://learn.microsoft.com/en-us/fslogix/concepts-fslogix-terminology).

## FSLogix Test Environment

For our validation and testing, we utilized the [2.9.8612.60056](2.9.8612.60056) release of FSLogix Apps combined with the 2203 LTSR CU2 release of Citrix Virtual Apps and Desktops. We deployed all components on-premises on Nutanix AHV.

### Infrastructure Configuration

#### Nutanix Config

_Table: Nutanix Config_

| Component | Setting |
| --- | --- |
| Platform | Nutanix AHV |
| AOS Version | 6.5.3.5 |
| AHV Version | 20220304.420 |
| Test Nodes | 8 |
| CPU Speed | 2.8 Ghz |
| Sockets per node | 2 |
| Cores per node | 48 |

#### Worker VM Config

_Table: Worker VM Config_

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

_Table: Testing Config_

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
- Citrix Optimizer used for optimization
- FSLogix Apps 2.9.8612.60056

The image build was automated, and a snapshot was taken to be used with Machine Creation Services provisioning.
