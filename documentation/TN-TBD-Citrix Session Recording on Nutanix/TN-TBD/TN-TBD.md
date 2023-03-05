# Executive Summary

Because Nutanix AOS can withstand hardware failures and software glitches, it ensures that application availability and performance are never compromised.

![Nutanix Hybrid Multicloud Software Overview](../images/overview-hybrid-multicloud-software.png "Nutanix Hybrid Multicloud Software Overview")

<--Text Here-->

# Introduction

## Audience

This tech note is part of the Nutanix Solutions Library. We wrote it for individuals responsible for designing, building, managing, and supporting Citrix Session Recording on Nutanix infrastructures. Readers should be familiar with Nutanix AOS, Prism, AHV, Files along with Citrix Session Recording components.

## Purpose

This document covers the following subject areas:

- Overview of the Nutanix solution.
- Overview of the Citrix Session Recording Solution.
- Considerations for Citrix Session Recording on Nutanix.

Traditionally, Storage has been a focal point for Citrix Session Recording deployments with a preference for locally attached storage on the Session Recording Servers. We wanted to understand if Nutanix Files could provide an alternative approach to locally attached disks, as well as understanding the optimal configuration both local and Files based configurations when deployed on Nutanix.

## Document Version History

| **Version Number** | **Published** | **Notes** |
| :---: | --- | --- |
| 1.0 | March 2023 | Original publication. |

# Nutanix Files

<!--JK: Need a description-->
# Citrix Session Recording

[Citrix Session Recording (SR)](https://docs.citrix.com/en-us/session-recording/current-release/) records, catalogs, and archives sessions for retrieval and playback.

Session Recording provides flexible policies to trigger recordings of application and desktop sessions automatically. Session Recording also supports dynamic session recording. Session Recording enables IT personnel to monitor and examine user activity, and so supports internal controls for regulatory compliance and security monitoring. Similarly, Session Recording also aids in technical support by speeding problem identification and time-to-resolution.

## Citrix Session Recording Components

SR consists of several key concepts and components outlined below:

[Session Recording database](https://docs.citrix.com/en-us/session-recording/current-release/system-requirements.html#session-recording-database)
: A component that manages the SQL Server database for storing recorded session data. When this component is installed, it creates a database named CitrixSessionRecording by default

[Session Recording server](https://docs.citrix.com/en-us/session-recording/current-release/system-requirements.html#session-recording-server)
: A Windows server that hosts: 
    - **The Broker**. An IIS 6.0+ hosted Web application that serves the following purposes:
      - Handling search queries and file download requests from the Session Recording player and web player.
      - Handling policy administration requests from the Session Recording policy console.
      - Evaluating recording policies for each Citrix Virtual Apps and Desktops or Citrix DaaS (formerly Citrix Virtual Apps and Desktops service) session.
    - **The Storage Manager**. A Windows service that manages the recorded session files received from each Session Recording-enabled VDA.
    - **Administrator Logging**. An optional subcomponent installed with the Session Recording server to log the administration activities. All the logging data is stored in a separate SQL Server database named CitrixSessionRecordingLogging by default. You can customize the database name.

[Session Recording Policy Console](https://docs.citrix.com/en-us/session-recording/current-release/system-requirements.html#session-recording-policy-console)
: A console used to create policies to specify which sessions are recorded.

[Session Recording agent](https://docs.citrix.com/en-us/session-recording/current-release/system-requirements.html#session-recording-agent)
: A component installed on each VDA for multi-session OS or single-session OS to enable recording. It is responsible for recording session data.

[Session Recording player](https://docs.citrix.com/en-us/session-recording/current-release/system-requirements.html#session-recording-player)
: A user interface that users access from a workstation to play recorded session files.

[Session Recording Storage Repository](https://docs.citrix.com/en-us/session-recording/current-release/get-started/scalability-considerations.html#storage)
: A location or set of locations used to store the session recording data files.

### Citrix Session Recording Test Environment

For our validation and testing we utilized the Current Release (2212) of Citrix Session Recording and we deployed all components on premises on Nutanix AHV.

| Component | Product Version | Operating System | Quantity | CPU/Memory |
| --- | --- | --- | --- | --- |
| Session Recording Database | Microsoft SQL Server 2016 | Windows Server 2016 | 1 | |
| Session Recording Server & Policy Console & Web Console | 2212 | Windows Server 2022 | 2 | 4vCPU/12GB | <!--JK: TBD -->
| Session Recording Agent | 2212 | Windows 10 Enterprise 22H2 | 1500 | |
| Session Recording Player | 2212 | Windows Server 2022 | 2 | 2vCPU/8GB|
| Citrix NetScaler | NS13.1: Build 37.38 | Linux | 1 | | <!--JK: TBD -->

<Note>
    Due to direct feedback from the Citrix product management team, Session Recording LTSR testing was not performed due to a number of known issues which were resolved in newer releases.
</Note>

### Citrix Session Recording Server Configuration

Each Session Recording Server was configured with the following settings to support load balancing:

-  Load Balancing was enabled by [setting the appropriate registry value](https://docs.citrix.com/en-us/session-recording/2203-ltsr/best-practices/configure-load-balancing-in-an-existing-deployment.html#step-2-configure-an-existing-session-recording-server-to-support-load-balancing)

    ```
    New-ItemProperty -Path "HKLM:\SOFTWARE\Citrix\SmartAuditor\Server" -Name "EnableLB" -Type DWORD -Value 1
    ```

-  MSMQ configurations were implemented to support load balancing as per [Citrix recommendations](https://support.citrix.com/article/CTX248554/session-recording-server-not-recording-sessions-while-using-the-cname-or-dns-alias). 

    ```
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters" -Name "IgnoreOSNameValidation" -Type DWORD -Value 1
    ```

-  We ran the *SrServerConfigurationSync.ps1* script to configure the *sr_lb_map.xml* file to support load balancing via the ADC

    ```
    & "C:\Program Files\Citrix\SessionRecording\Scripts\SrServerConfigurationSync.ps1" -Action AddRedirection -ADCHost <sessionrecording.testdomain.com>
    ```

<note>
    Note that we specifically configured both methods to support either TCP or HTTP/HTTPS configurations.
</note>

- Windows Defender Antivirus was disabled during the testing. Citrix provide guidance on Antivirus configurations for [Session Recording Servers including MSMQ](https://docs.citrix.com/en-us/tech-zone/build/tech-papers/antivirus-best-practices.html#session-recording---server), the [Session Recording Agent](https://docs.citrix.com/en-us/tech-zone/build/tech-papers/antivirus-best-practices.html#session-recording---agent) and the [Session Recording Player](https://docs.citrix.com/en-us/tech-zone/build/tech-papers/antivirus-best-practices.html#session-recording---player).

### Citrix Image Build

We built a fresh gold image on Nutanix AHV with the following components installed:

- Windows 10 Enterprise 22H2
- Nutanix VirtIO Drivers
- Microsoft Edge Web Browser (Chromium)
- Microsoft FSLogix Apps
- Microsoft Office 2016 Professional Plus
- VLC Media Player
- Adobe Acrobat Reader DC
- Citrix Virtual Delivery Agent 2203 CU2
- Citrix Session Recording Agent 2212 (CR)
- Citrix Workspace Environment Management Agent 2212 (CR)
- VMWare Optimizer used for optimization
- Base Image Script Framework used for Image Sealing

The image build was automated and a snapshot was output to be used with Machine Creation Services Provisioning. 

### Citrix Session Recording Agent Configuration

The Session Recording Agent was deployed with default configurations. It is critical to understand that each Recording Agent must have a unique QMID else data will be lost when interacting with the SR servers. To ensure this was always unique, we sealed our base images with the **Base Image Script Framework** which executes the appropriate configurations to provide a unique QMID.

[VDAs can have the same QMId under certain conditions](https://docs.citrix.com/en-us/session-recording/current-release/install-upgrade-uninstall.html#step-8-complete-the-installation)

### Session Recording Configuration with Local Storage

To mirror configurations known to be operating with the Nutanix AOS platform at scale, we configured the following settings to baseline:

| Component | Detail |
| --- | --- |
| MSMQ Message Storage Size | **1048576 KB**. Left in the default location. This is the default setting for the MSMQ Cache | 
| MSMQ Journal Storage Limit | **1048576 KB**. Left in the default location. This by default is **unlimited** |
| A central directory for Mount Points | **C:\SessionRecordings**. This is to reduce the requirement on drive letters and simplify the topology |
| A single root share configured on the SR Server | **C:\SessionRecordings** shared as **\\\ServerName\SessionRecordings$**. This is to allow access for all SR servers to all shares. |
| Active Directory Group Permissions | We deployed a single Active Directory Group containing all SR Servers. This Group was used to assign **full control** permissions to the **SessionRecording$** Share. |
| **A directory per physical disk mount** | A scale configuration unit per disk  
| Disk 1 | **C:\SessionRecordings\SR1** |
| Disk 2 | **C:\SessionRecordings\SR2** |
| Disk 3 | **C:\SessionRecordings\SR3** |
| Disk 4 | **C:\SessionRecordings\SR4** |
| Disk 5 | **C:\SessionRecordings\SR5** |
| **Multiple directories configured in the SR Server configuration** | The Session Recording Server creates the Recordings Directory |
| Share 1 | **\\\ServerName\SessionRecordings$\SR1\Recordings** |
| Share 2 | **\\\ServerName\SessionRecordings$\SR2\Recordings** |
| Share 3 | **\\\ServerName\SessionRecordings$\SR3\Recordings** |
| Share 4 | **\\\ServerName\SessionRecordings$\SR4\Recordings** |
| Share 5 | **\\\ServerName\SessionRecordings$\SR5\Recordings** |

<note>
    MSMQ is extremely disk intensive. Distribution of messages to multiple disks directly increases performance and the ability to empty queues.
</note>

### Session Recording Configuration with Nutanix Files

We deployed Nutanix Files to support the Recording Storage repository. We tested two File Server configurations, one based on Hybrid technology, the other using an All-Flash configuration.

The following configuration was used for Files based on Hybrid configurations:

<!--JK: Need to chat with Jarian around important items of note and how to structure them-->

| Component | Setting |
| --- | --- |
| Version | TBD |
| Platform | Nutanix AHV |
| File Server Size | | 
| File Server Configuration | |
| File Server Name | |
| Share Name | | 
| Distributed share | |
| Compression | |

The following configuration was used for Files based on All-Flash configurations:

| Component | Setting |
| --- | --- |
| Version | TBD |
| Platform | Nutanix AHV |
| File Server Size | | 
| File Server Configuration | |
| File Server Name |  |
| Share Name | | 
| Distributed share | Enabled |
| Compression | |

Additionally, we deployed a single Active Directory Group containing both SR Servers. This Group was used to assign full control permissions to the *SessionRecording* Share.

We tested two scenarios for Nutanix files, one using a Single Top Level Directory (TLD), the second using multiple TLDs to distribute load amongst File Server Virtual Machines (FSVM) when using multiple SR Servers <!--JK: is this effectively the same thing? Am i just confusing things here by splitting - should the model simply be "A TLD per SR Server"-->.

For the single TLD test, we configured the Session Recording Server with a single share:

| Server | TLD Path |
| --- | --- |
| WS-SR01 | \\\files\SessionRecording\WS-SR01\Recordings |

<!--JK: Image here? -->

For the distributed test, we configured each Session Recording with its own Top Level Directory (TLD):

| Server | TLD Path |
| --- | --- |
| WS-SR01 | TBD |
| WS-SR02 | \\\files\SessionRecording$\WS-SR02\Recordings |

<!--JK: Image here? -->

<!--JK: Not sure if there is any value in this model below?-->
- \\files\SessionRecording$\WS-SR01_1\Recordings
- \\files\SessionRecording$\WS-SR01_2\Recordings

<note>
    Citrix Session Recording Servers create their own directory structure based on the configuration input into the Session Recording Server Properties. All Session Recording Servers should have access to all shares. Nutanix recommends leveraging an Active Directory Group containing the Session Recording Computer Accounts.
</note>

#### Single TLD Results
 
 TBD
#### Multiple TLD Results

TBD

### Citrix NetScaler Configuration <!--JK: This whole section needs to be considered post testing -->

Citrix NetScaler was utilized for load balancing using the [guidance provided by Citrix](https://docs.citrix.com/en-us/session-recording/2203-ltsr/best-practices/configure-load-balancing-in-an-existing-deployment.html). We implemented the [TCP passthrough](https://docs.citrix.com/en-us/session-recording/2203-ltsr/best-practices/configure-load-balancing-in-an-existing-deployment.html#configure-load-balancing-through-tcp-passthrough) model for simplicity.

We made one significant change to the load balancing configuration. We chose *Round Robin* for our load balancing method type

<!--JK: do we see more risk or value by including LB configurations?? If we keep, then we need to make the data anonymous-->

# Testing Logic

We used Login Enterprise to perform multiple 1500 concurrent session tests against the environment. <!--JK: Need to get some input from the team-->

We used the ***Record entire sessions (for everyone without notification)*** Policy so that we could capture the entire session without interaction.
![Session Recording Policy](../images/TN-TBD-Session-Recording-Policy.png "Session Recording Policy")

During the testing we actively played back both finished recordings (completed) and live recordings (active) via both the traditional console and the web console.

# Test Results

    - When NetScaler is used with default configurations, data is lost and sessions will not "complete" their recordings -> this is tracked in the event logs for SR
    - When MSMQ thresholds are increases, there is significantly higher disk activity due to the way MSMQ stores and flushes data
    - Moving MSMQ queues to alternate drives had no positive impacts on performance
    - Distribution of data across multiple disks enhanced performance of queue flushing
    - The amount of data sent to the Session Recording Server is typically what will mandate scale out scenarios
      - A knowledge worker profile with intense web browser utilization overloaded the session recording servers ability to flush MSMQ at TBD
      - A task worker profile with Login Enterprise showed significantly better results on the SR server scalability
    - The "Active Session Recording" Counter shows unexpected results, typically resulting in duplicate figures compared to active ICA sessions
    - Delayed reboots will occur if VDA is still flushing data
  <!--JK:(Can we validate this one above?)-->

<!--JK: Need to put something here-->

## Infrastructure Servers

## Nutanix Files

    - Storage consumed
    - IO Consumed
    - Latency/Issues/Challenges
## 

# Conclusion

- Customer milage will vary based on the type of data being ingested
- Heavy workloads and boot storms will directly impact scale considerations
- Nutanix Files and local Storage configuration performed similarly
- All-Flash and Hybrid Configurations performed similarly
- MSMQ is the bottleneck for performance

# Appendix

## References

-  [URL1](https://whatever.com)
-  [URL2](https://whateverelse.com)