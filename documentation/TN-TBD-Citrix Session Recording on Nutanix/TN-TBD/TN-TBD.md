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

Traditionally, Storage has been a focal point for Citrix Session Recording deployments with a preference for locally attached storage on the Session Recording Servers. We wanted to understand why this was the case, and identify if Nutanix Files could provide an alternative approach to locally attached disks.

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

For our validation and testing, we built the following environment. We tested utilizing the Current Release (2210) of Session Recording and we deployed all components on premises on Nutanix AHV. With direct feedback from the product management team, LTSR testing was not performed due to a number of known issues.

| Component | Product Version | Operating System | Quantity | CPU/Memory |
| --- | --- | --- | --- | --- |
| Session Recording Database | Microsoft SQL Server 2016 | Windows Server 2016 | 1 | |
| Session Recording Server & Policy Console & Web Console | 2212 | Windows Server 2022 | 2 | 4vCPU/12GB |
| Session Recording Agent | 2212 | Windows 10 Enterprise 22H2 | 1500 | |
| Session Recording Player | 2212 | Windows Server 2022 | 2 | 2vCPU/8GB|
| Citrix NetScaler | NS13.1: Build 37.38 | Linux | 1 | |

### Session Recording Configuration with Local Storage

To mirror configurations known to be operating with the Nutanix AOS platform at scale, we configured the following settings to baseline:

| Component | Detail | Notes |
| --- | --- | --- |
| MSMQ Message Storage Size | 1048576 KB. Left in the default location  | This is the default Windows Setting for MSMQ Cache | 
| MSMQ Journal Storage Limit | 1048576 KB. Left in the default location | This by default is unlimited |
| A central Directory for Mount Points | C:\SessionRecordings | This is to reduce the requirement on Drive letters and simplify the topology |
| A folder per physical disk Mount | C:\SessionRecordings\SR1 -> Disk 1 | |
| A single share configured on the SR Server | \\\ServerName\SessionRecordings$ -> C:\SessionRecordings | This is to allow access for all SR servers to all shares | 
| Multiple Directories configured in the SR Server configuration | \\\ServerName\SessionRecordings\SR1\Recordings | Session Recording creates the Recordings Directory |

<note>
    MSMQ is extremely disk intensive. Distribution of messages to multiple disks directly impacts performance and queue data.
</note>

### Nutanix Files Configuration

We deployed Nutanix Files to support the Recording Storage Repository. The following configuration was used for Files:

<!--JK: Need to chat with Jarian around important items of note and how to structure them-->

| Component | Setting |
| --- | --- |
| Version | TBD |
| Platform | Nutanix AHV |
| File Server Size | | 
| File Server Configuration | |
| File Server Name | FS01 |
| Share Name | SessionRecording | 
| Distributed share | Enabled |
| Compression | |

Additionally, we deployed a single Active Directory Group containing both SR Servers. This Group was used to assign full control permissions to the *SessionRecording* Share.

<!--JK: Image Here - maybe also discuss permission sets-->

To ensure optimal use of Distributed Shares, we configured each Session Recording with its own Top Level Directory (TLD) on the *SessionRecording* Share.

| Server | TLD Path |
| --- | --- |
| SR01 | \\\NTXFS\SessionRecording\SR01\Recordings |
| SR02 | \\\NTXFS\SessionRecording\SR02\Recordings |

<note>
    Citrix Session Recording Servers create their own directory structure based on the configuration input into the Session Recording Server Properties. All Session Recording Servers should have access to all shares. Nutanix recommends leveraging an Active Directory Group containing the Session Recording Computer Accounts.
</note>

### Citrix NetScaler Configuration <!--JK: This whole section needs to be considered post testing -->

Citrix NetScaler was utilized for load balancing using the [guidance provided by Citrix](https://docs.citrix.com/en-us/session-recording/2203-ltsr/best-practices/configure-load-balancing-in-an-existing-deployment.html). We implemented the [TCP passthrough](https://docs.citrix.com/en-us/session-recording/2203-ltsr/best-practices/configure-load-balancing-in-an-existing-deployment.html#configure-load-balancing-through-tcp-passthrough) model for simplicity.

We made one significant change to the load balancing configuration. We chose *Round Robin* for our load balancing method type

<!--JK: do we see more risk or value by including LB configurations?? If we keep, then we need to make the data anonymous-->

```
enable ns feature LB

add server WS-SR01 10.57.64.34 -comment "Session Recording Server"
add server WS-SR02 10.57.64.35 -comment "Session Recording Server"

add service WS-SR01_80 WS-SR01 TCP 80 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport YES -sp OFF -cltTimeout 9000 -svrTimeout 9000 -CKA NO -TCPB NO -CMP NO
add service WS-SR02_80 WS-SR02 TCP 80 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport YES -sp OFF -cltTimeout 9000 -svrTimeout 9000 -CKA NO -TCPB NO -CMP NO

add service WS-SR01_443 WS-SR01 TCP 443 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport YES -sp OFF -cltTimeout 9000 -svrTimeout 9000 -CKA NO -TCPB NO -CMP NO
add service WS-SR02_443 WS-SR02 TCP 443 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport YES -sp OFF -cltTimeout 9000 -svrTimeout 9000 -CKA NO -TCPB NO -CMP NO

add service WS-SR01_1801 WS-SR01 TCP 1801 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport YES -sp OFF -cltTimeout 9000 -svrTimeout 9000 -CKA NO -TCPB NO -CMP NO
add service WS-SR02_1801 WS-SR02 TCP 1801 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport YES -sp OFF -cltTimeout 9000 -svrTimeout 9000 -CKA NO -TCPB NO -CMP NO

add lb vserver lbvs_sr_80 TCP 10.57.64.72 80 -persistenceType SOURCEIP -lbMethod ROUNDROBIN-cltTimeout 9000
bind lb vserver lbvs_sr_80 WS-SR01_80
bind lb vserver lbvs_sr_80 WS-SR02_80

add lb vserver lbvs_sr_443 TCP 10.57.64.72 443 -persistenceType SOURCEIP -lbMethod ROUNDROBIN-cltTimeout 9000
bind lb vserver lbvs_sr_443 WS-SR01_443
bind lb vserver lbvs_sr_443 WS-SR02_443

add lb vserver lbvs_sr_1801 TCP 10.57.64.72 1801 -persistenceType SOURCEIP -lbMethod ROUNDROBIN-cltTimeout 9000
bind lb vserver lbvs_sr_1801 WS-SR01_1801
bind lb vserver lbvs_sr_1801 WS-SR02_1801
```

### Citrix Session Recording Server Configuration

Each Session Recording Server was configured with the following settings:

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

-  MSMQ storage buffer was increased from the default 1Gb to 4Gb (Computer Management -> Services and Applications -> Message Queuing Properties) <!--JK: This needs to be killed -->

    ![MSMQ Storage Size](../images/TN-TBD-MSMQ-Storage-Size.png "MSMQ Storage Size")

- Windows Defender Antivirus was disabled during the testing. Citrix provide guidance on Antivirus configurations for [Session Recording Servers including MSMQ](https://docs.citrix.com/en-us/tech-zone/build/tech-papers/antivirus-best-practices.html#session-recording---server), the [Session Recording Agent](https://docs.citrix.com/en-us/tech-zone/build/tech-papers/antivirus-best-practices.html#session-recording---agent) and the [Session Recording Player](https://docs.citrix.com/en-us/tech-zone/build/tech-papers/antivirus-best-practices.html#session-recording---player).


### Citrix Image Build

We built a fresh gold image with the following relevant components installed:

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

The Session Recording Agent was deployed with default configurations. It is critical to understand that each Recording Agent must have a unique QMID else data will be lost when interacting with the SR servers. To ensure this was always unique, we sealed our base images with the Base Image Script Framework which executes the appropriate configurations to provide a unique QMID.

[VDAs can have the same QMId under certain conditions](https://docs.citrix.com/en-us/session-recording/current-release/install-upgrade-uninstall.html#step-8-complete-the-installation)

<!--JK: Need to note what was installed, and the importance of sealing for MSMQ ID-->

# Testing Logic

We used Login Enterprise to perform multiple 1500 concurrent session tests against the environment. <!--JK: Need to get some input from the team-->

We used the included *Record entire sessions (for everyone without notification)* Policy so that we could capture the entire session without interaction.
![Session Recording Policy](../images/TN-TBD-Session-Recording-Policy.png "Session Recording Policy")

    - need to capture that we retrieved sessions whilst they were being recording too

# Test Results

## Infrastructure Servers

    - Can we get some data for CPU/Mem Usage
    - SQL Data?

## Nutanix Files

    - Storage consumed
    - IO Consumed
    - Latency/Issues/Challenges
## 

# Conclusion

<--Text Here-->

# Appendix

## References

-  [URL1](https://whatever.com)
-  [URL2](https://whateverelse.com)