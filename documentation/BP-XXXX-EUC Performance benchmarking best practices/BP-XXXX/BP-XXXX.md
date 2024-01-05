# Executive Summary

This document describes the performance benchmarking EUC best practices.

# Introduction
At Nutanix we run benchmark tests with EUC workloads for a number of reasons. First of all, we have to make sure that there is no regression with an EUC workload when you upgrade the Nutanix Cloud Infrastructure (NCI) to a newer version. We also run run EUC performance benchmark tests to show the performance (impact) in various publications, like reference architectures, Nutanix Validated Designs, Technotes, and various online publications. And finally, we run these tests to validate the performance on different hardware platforms, with different CPU, memory and storage configurations. This helps the finetune the Nutanix Sizer tool.
In this document, we describe the best practices of running EUC performance benchmark tests. An important aspect of running performance benchmark tests is to get consistent results. Once you are able to get consistent results, you are able to define a baseline. And when you have defined your baseline, you can add a change to the infrastructure, run the same test, and then determine the impact of that change.

## Audience

This tech note is part of the Nutanix Solutions Library and provides an overview of the recommendations for running EUC performance benchmark tests. 

## Purpose

This document covers the following subject areas:

- Why run performance benchmark tests for EUC?
- Benchmark tools
- Benchmark metrics
- Setup your environment for consistent benchmark testing
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
- Benchmark Examples
  - not optimized
  - wait time
  - With or without security agents/virus protection?
  -



## Document Version History

| **Version Number** | **Published** | **Notes** |
| :---: | ------ | --------- |
| 1.0 | January 2024 | Original publication. |

# Wy run performance benchmark tests for EUC?
You would run EUC benchmark tests to see the impact of new versions of AOS, AHV, Windows OS versions, possible other software releases like Citrix VDA, Microsoft Office.

At Nutanix, we also run performance tests and use the results for publications like reference architecture documents and Nutanix Validated Design documents. Or Technotes or other online publications.
Run performance tests on new hardware platform releases, with newer CPU types, faster memory configurations or storage configurations.
To educate customers and our field teams, that use this for sizing new EUC infrastructures.

# Benchmark tools
There a various benchmark solutions that you can use to simulate a EUC workload. Keep the following guidelines in mind when selecting a EUC benchmark solution:
- The tool must be able to simulate user behaviour, like logging in to the virtual machines, start applications, and open, edit and save documents with various applications. This is called a workload.
- It is nice to be able to use applications in the simulated workload that are used by the users in production, but it is more important to be able to have a repeatable workload that will have a consistent outcome.
- The benchmark tool must be able to collect various metrics that can be used to compare multiple tests. 

# EUC Benchmark metrics
When you benchmark with an EUC workload, you probably want to know how many session you can host on the infrastructure. This is hard to achieve with a benchmark tool, as it is very difficult to simulate the real user workload of a production environment. The best way to determine the density of an infrastructure is to let users actually work on the infrastructure and then gradually add more users. Then you will need to keep an eye on certain resource usage metrics and user experience metrics to determine if the infrastructure reached it's maximum capacity.
With the Nutanix Cloud Platform, you can start small and scale linearly by adding nodes to the cluster. But before you start D2 types of metrics: resource usage metrics and user experience metrics

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

