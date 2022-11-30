# Citrix Workspace Environment Management Performance Impact Analysis

## Executive Summary

This document describes the performance impact of various Citrix Workspace Environment Management (WEM) settings on the Windows Desktop and Windows Server Virtual Delivery Agents running on a Nutanix HCI Cluster. The document will cover the following areas of the WEM configuration:

- **CPU Management**. (default settings enabled with no exclusions defined)
- **Memory Management**.
- **Multi Session Optimization**. (for RDSH)

The following components have been excluded:

- **I/O Optimization**. This is unique to each environment and there is no defined 'default' configuration
- **Fast Logoff**. This is a non performance impacting feature which impacts only the user experience for logoff processes
- **Citrix Optimizer**. Citrix optimization is typically executed on a base image

We expect customer results to vary, however, these results should give an indication of the impacts.

## Introduction

### Audience

This tech note is part of the Nutanix Solutions Library. We wrote it for our sales force and engineering resources. Consumers of this document should be familiar with desktop virtualization and Nutanix at a high level. 

### Purpose

This document covers the following subject areas:

- Information about WEMs and VDI
- How to use Login VSI for performance testing
- Performance test results for the following scenarios:
  - Windows Desktop / Server CPU Management results
  - Windows Desktop / Server Memory Management results
  - Windows Server Multi Session Optimization results (RDSH workloads only)

### Document Version History

| Version Number | Published | Notes |
| ---- | ---- | ---- |
| v1.0.0 | ??? 2023 | Original Document Creation |

## WEM and Virtual Desktop Infrastructure

Workspace Environment Management (WEM) uses intelligent resource management to deliver enhanced performance, desktop logon, and application response times. It offers enhanced security and elevation controls along with user environment management capability based on a range of flexible filters and conditions. It is a software-only, driver-free solution. The version of WEM used for this performance analysis will be from the latest release of the Citrix product set as there is no Long Term Service Release (LTSR) for WEM.

> Note: The Citrix Cloud Workspace Environment Management Service will not be covered in this document, however the performance features are available for both on-premises and Service offerings. 

This document focuses on the performance features only for WEM. All other components of the solution will be left as default.

** INSERT IMAGE WITH WEM OVERVIEW **

## Performance Testing With Login VSI

### Login VSI Benchmark

Login VSI provides performance insights for virtualized desktop and server environments. Enterprise IT departments use Login VSI products in all phases of VDI operations management—from planning to deployment to change management—for more predictable performance, higher availability, and a more consistent user experience. 

The world’s leading virtualization vendors use the flagship product, Login VSI, to benchmark performance. With minimal configuration, Login VSI products work with VMware Horizon, Citrix Virtual Apps and Desktops, Microsoft Remote Desktop Services (Terminal Services), and any other Windows-based virtual desktop solution. You can find more information about Login VSI test workloads in the blog post Simulating VDI Users: Introduction to Login VSI Workloads. 

The following table includes all four workloads available on Login VSI 4.1.

#### Login VSI 4.1 Workloads

| Task Worker | Office Worker | Knowledge Worker | Power User |
| ---- | ---- | ---- | ----|
| Light | Medium | Medium | Heavy|
| 1 vCPU | 1 vCPU | 2 vCPU | 2-4 vCPU |
| 2-3 apps | 4-6 apps | 4-7 apps | 5-9 apps|
| No video | 240p video | 360p video | 720p video|

#### Login VSI 4.1 Workflows

| Workload Name	| Task Worker | Office Worker | Knowledge Worker | Power User |
| ----	| ---- | ---- | ---- | ---- |
| VSI version | 4.1 | 4.1 | 4.1 | 4.1 |
| Apps open | 2–7 | 5–8 | 5–9 | 8–12 |
| CPU usage | 70% | 82% | 100% | 119% |
| Disk reads | 79% | 90% | 100% | 133% |
| Disk writes | 77% | 101% | 100% | 123% |
| OPS | 6 | 8.1 | 8.5 | 10.8 |
| Memory | 1 GB | 1.5 GB | 1.5 GB | 2 GB |
| vCPU | 1 | 1 | 2 | 2+ |

### Interpreting Login VSI Results

Login VSI is a test benchmark used to simulate real-world user workloads on a desktop. These values represent the time it takes for an application or task to complete (launching Outlook, for example) and aren’t in addition to traditional desktop response times. These figures don’t refer to the round-trip time (RTT) for network I/O; rather, they refer to the total time to perform an action on the desktop. During the test, we turned on all VMs and started the workload on a new desktop until all sessions and workloads were active. The workload used a launch window of 2,880 seconds for all tests.

We quantified the evaluation using the following metrics:

- Minimum Response: The minimum application response time.
- Average Response: The average application response time.
- Maximum Response: The maximum application response time.
- VSI Baseline: The average application response time of the first 15 measurements.
- VSI Index Average: The average response time, dropping the highest and lowest two percent.
- VSImax: If reached, the maximum value of sessions launched before the VSI index average gets above the VSI baseline + 1,000 ms.
- CPU usage during steady state: When all the sessions are active and continue to use the applications. This state simulates the state of the users during the entire day, rather than just during the session startup period.

Keep track of these response times, but most importantly, make note of the average CPU usage of the hosts you used during the test. 

#### Login VSI Metric Values

| Metric | Value | Rationale |
| ---- | ---- | ---- |
| VSI Baseline | <799 ms | Very good |
| VSI Baseline | 800–1,200 ms | Good |
| VSI Baseline | >1,200 ms | Average/poor |
| CPU usage during steady state | <85% | Ideal CPU usage |

### Login VSI Graphs

Login VSI graphs show the values obtained during the launch for each session. The following figure shows an example graph of the test data. The y-axis is the response time in milliseconds, and the x-axis is the number of active sessions.

** INSERT IMAGE OF LOGIN VSI GRAPH **

## Performance Test Infrastructure

This section describes the infrastructure used during the tests.

#### Hardware

| Attribute	| G8 Specifications |
| ---- | ---- |
| Model | NX-3155G-G8 |
| Processor type | Intel Xeon Gold 6354 @ 3.0 GHz |
| CPU | 2 |
| Cores per CPU | 36 |
| Hyperthreading enabled | Yes |
| Logical processors | 72 |
| CPU capacity | 108 GHz |
| Available memory | 1.48 TB |
| Memory assigned to CVM | 36 GB |
| AOS version | 6.5.1.6 LTS |
| Disks | 6 x 1.55 TB SSD |

#### Windows 10 Image

| Attribute | Specification |
| ---- | ---- |
| CPU | 2 vCPU |
| Memory | 3 GB |
| Disk | 50 GB |
| Operating system | Windows 10 |
| Applications | Adobe Acrobat DC, Doro PDF 1.82, FreeMind, Internet Explorer 11, MS Office 2016 |
| VDA agent | Citrix VDA 2203 CU1 |
| WEM agent | Citrix WEM Agent 2209 |

#### Windows Server 2022 Image

| Attribute | Specification |
| ---- | ---- |
| CPU | 8 vCPU |
| Memory | 42 GB |
| Disk | 80 GB |
| Operating system | Windows Server 2022 |
| Applications | Adobe Acrobat DC, Doro PDF 1.82, FreeMind, Internet Explorer 11, MS Office 2016 |
| VDA agent | Citrix VDA 2203 CU1 |
| WEM agent | Citrix WEM Agent 2209 |

### Deployment Method

We used Citrix Virtual Desktops with MCS to deploy the desktops on the hosts and only used one host in each test. We used Citrix Studio and Director version 2203 CU1.

## Test Scenarios

The testing was performed under the following scenarios:

- CPU Management
- Memory Management
- Multi Session Optimization

Specifics around the settings enabled / disabled are:

### CPU Management

| Setting | Detail |
| ---- | ---- |
| Enable CPU Spike Protection | Enabled with "Auto Prevent CPU Spikes" (WEM calculates the appropriate core configuration) | 
| Enable Intelligent CPU Optimization | Enabled |
| Enable Intelligent I/O Optimization | Enabled | 

For more information on the CPU management settings please follow this [link.](https://docs.citrix.com/en-us/workspace-environment-management/current-release/user-interface-description/system-optimization/cpu-management.html)

### Memory Management

> Note: We expect this setting to impact the storage performance when tested at scale, results of this are further down in this document. 

| Setting | Detail |
| ---- | ---- |
| Optimize Memory Usage for Idle Processes | Enabled with "Idle Time" set to 15 | 
| Idle State Limit (percent) | Enabled and set to 1 |
| Enable Intelligent I/O Optimization | Enabled | 

For more information on the Memory management settings please follow this [link.](https://docs.citrix.com/en-us/workspace-environment-management/current-release/user-interface-description/system-optimization/memory-management.html)


### Multi Session Optimization

| Setting | Detail |
| ---- | ---- |
| Enable Multi-session Optimization | Enabled | 

For more information on the Multi Session Optimization settings please follow this [link.](https://docs.citrix.com/en-us/workspace-environment-management/current-release/user-interface-description/system-optimization/multi-session-optimization.html)

> Note: This optimization is for Remote Desktop Session Hosts ONLY and will only be tested on the Windows Server images deployed.

## Performance Test Results

This section describes the performance test results. The results indicate the impact of changes on the environment.

### CPU Management

** Show Findings with Login VSI Graph **

### Memory Management

** Show Findings with Login VSI Graph **

### Multi Session Optimization

** Show Findings with Login VSI Graph **

## Conclusion

Check the test results and provide feedback on findings