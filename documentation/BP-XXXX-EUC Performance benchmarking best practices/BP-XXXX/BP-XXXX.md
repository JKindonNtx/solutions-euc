# Executive Summary

This document describes the End User Computing performance benchmarking best practices. Where possible we have recommended tools and guides that we deem fit for purpose however these tools will differ in various enterprise deployments. 

# Introduction

At Nutanix, we run benchmark tests with End User Computing (EUC) workloads for a number of reasons. First, we have to make sure that there is no regression with an EUC workload when you upgrade the Nutanix Cloud Infrastructure (NCI) to a newer version. We also run EUC performance benchmark tests to show the performance (impact) in various publications, like reference architectures, Nutanix Validated Designs, Technotes, and different online publications. And finally, we run these tests to validate the performance on different hardware platforms, with different CPU, memory and storage configurations. This helps us fine tune the Nutanix Sizer tool.

In this document, we describe the best practices for running EUC performance benchmark tests. An important aspect of running performance benchmark tests is to get consistent results. Once you are able to get consistent results, you are able to define a baseline, and when you have defined your baseline, you can change the infrastructure, run the same test, and then determine the impact of that change.

## Audience

This technote is part of the Nutanix Solutions Library and provides an overview of the recommendations for running EUC performance benchmark tests. 

## Purpose

This document covers the following subject areas:

- Why run performance benchmark tests for EUC? - DB
- Benchmark tools - DB
- Benchmark metrics - DB
- Setup your environment for consistent benchmark testing
  - Master images - DB
  - Reboot before testing - SH
  - Launchers - SH
    - Display protocol - SH
    - Screen resolution - SH
    - Offloading to client - SH
  - Logon window - SH
  - Persistent vs non-persistent - Run 1 vs Run 2 data - DB
  - Local vs roaming vs containerized profiles - DB
  - BIOS settings / C-states - SH
  - Optimizations - DB
- Benchmark Examples
  - not optimized
  - wait time
  - With or without security agents/virus protection?
  -

## Document Version History

| **Version Number** | **Published** | **Notes** |
| :---: | --- | --- |
| 1.0 | January 2024 | Original publication. |

# Why Run Performance Benchmark Tests for EUC?

The primary reason for running a performance benchmark test is to determine the baseline performance of the platform or to measure the impact of a change. Some examples of why you would run an EUC benchmark test are:

- Baseline the performance profile of the platform.
- Determine the impact of new software versions (AOS, AHV, Windows OS versions, Citrix VDA etc).
- Determine the impact of configuration changes (Group Policy, Profile configuration etc).

At Nutanix, we also run performance benchmark tests and use the results for:

- Publications like reference architecture documents, Nutanix Validated Design documents, Technotes or other online publications.
- Baseline new hardware platform releases, with newer CPU types, faster memory configurations or storage configurations.
- To educate customers and our field teams, that use this for sizing new EUC infrastructures.

# Benchmark Tools

There a various benchmark solutions that you can use to simulate an EUC workload. Keep the following guidelines in mind when selecting an EUC benchmark solution:

- The tool must be able to simulate user behavior, like logging in to the virtual machines, starting applications, and opening, editing and saving documents with various applications. This is called a workload.
- It is preferable to be able to use applications in the simulated workload that are used by the users in production, but it is more important to be able to have a repeatable workload that will have a consistent outcome.
- The benchmark tool must be able to collect various metrics that can be used to compare multiple tests. 
- If the benchmark tool does not provide the data you require be sure to investigate gethering this information using other tools available to you.
- A central reporting tool and being able to compare results is critical. Without this capability you will not have the ability to compare results against one another.

Benchmarking tools can be broken into various categories and it is important to define a toolset that you are going to use prior to designing and implementing your solution. This is critical to ensure consistency across the platform, that in turn is critical for good results from the tests. 

Below are some examples of those categories and some examples of software vendors that provide solutions in those areas:

| **Category** | **Description** | **Examples** |
| :---: | --- | --- |
| Workload Generation | Simulate user workloads on the endpoints being tested | Login Enterprise / Automai / LoadGen |
| Image Deployment | Operating System and Application Deployment | MDT / Ansible / PowerShell |
| Test Automation | Automation of the Test Execution | PowerShell / Api |
| Data Collection | Ability to collect additional test data | PowerShell / Api |
| Test Storage | Central repository to store test data | InfluxDB / SQL |
| Test Reporting | Central reporting console for the test data | Grafana / Custom Web page |

The key point here when defining and designing your environment for testing is that you have a repeatable and automated process. Having the test bed defined **exactly the same** for every test run is critical to ensure accurate results.

# EUC Benchmark Metrics

When benchmarking an EUC workload, you want to know how many sessions you can host on the infrastructure and how the platform performs with those sessions active and working. This is hard to achieve with a benchmark tool, as it is very difficult to simulate the real user workload of a production environment. 

The best way to determine the user density of a platform is to let users actually work on the system and then gradually add more users. Then you will need to keep an eye on certain resource usage metrics and user experience metrics to determine if the platform has reached it's maximum capacity.

With the Nutanix Cloud Platform, you can start small and scale linearly by adding nodes to the cluster. But before you start testing its important to understand the types of metrics you will be monitoring to measure experience.

## Resource usage metrics
Host:
- CPU usage
- Memory usage
- Storage controller IO
- Storage controller latency

VM:
- CPU usage
- CPU ready time
- Memory usage
- Display protocol CPU usage
- Display protocol Frames per Second

## User Experience metrics
Login times:
- Total login time
- Profile load time
- Connection time
- GPO load time

Application performance:
- Application start times
- Application open file times
- Apllication save file times


# Setup the infrastructure for EUC benchmark testing
  - Reboot before testing
  - Launchers
    - Display protocol
    - Screen resolution
    - Offloading to client
  - Logon window
  - Persistent vs non-persistent
  - Local vs roaming vs containerized profiles
  - BIOS settings / C-states
  - Optimizations

# Benchmark examples



<note>

</note>



# Performance Testing With Login VSI

