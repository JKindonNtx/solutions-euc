# Executive Summary

This document describes the End User Computing performance benchmarking best practices. Where possible we have recommended tools and guides that we deem fit for purpose however these tools will differ in various enterprise deployments. 

# Introduction

At Nutanix, we run benchmark tests with End User Computing (EUC) workloads for a number of reasons. First, we have to make sure that there is no regression with an EUC workload when you upgrade the Nutanix Cloud Infrastructure (NCI) to a newer version. We also run EUC performance benchmark tests to show the performance (impact) in various publications, like reference architectures, Nutanix Validated Designs, Technotes, and different online publications. And finally, we run these tests to validate the performance on different hardware platforms, with different CPU, memory and storage configurations. This helps us fine tune the Nutanix Sizer tool.

In this document, we describe the best practices for running EUC performance benchmark tests. An important aspect of running performance benchmark tests is to get consistent results. Once you are able to get consistent results, you are able to define a baseline, and when you have defined your baseline, you can change the infrastructure, run the same test, and then determine the impact of that change.

## Audience

This technote is part of the Nutanix Solutions Library and provides an overview of the recommendations for running EUC performance benchmark tests. 

## Purpose

This document covers the following subject areas:

- Why run performance benchmark tests for EUC? - DB - base done
- Benchmark tools - DB - base done
- Benchmark metrics - DB - base done
- Setup your environment for consistent benchmark testing
  - Master images - DB - base done
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
| :--- | :--- | :--- |
| Workload Generation | Simulate user workloads on the endpoints being tested | Login Enterprise / Automai / LoadGen |
| Image Deployment | Operating System and Application Deployment | MDT / Ansible / PowerShell |
| Automation | Automation of the Test Execution | PowerShell / Api |
| Data Collection | Ability to collect additional test data | PowerShell / Api |
| Storage | Central repository to store test data | InfluxDB / SQL |
| Reporting | Central reporting console for the test data | Grafana / Custom Web page |

The key point here when defining and designing your environment for testing is that you have a repeatable and automated process. Having the test bed defined **exactly the same** for every test run is critical to ensure accurate results.

# EUC Benchmark Metrics

When benchmarking an EUC workload the key outcome desired is to know the baseline of your platform along with the performance difference after deploying changes to the environment. This is not easy to achieve with a benchmark tool, as it is very difficult to simulate the real user workload of a production environment, however, what is relevant here is having the knowledge to accurately report on software and hardware changes and how this will impact your user experience. 

The best way to determine the user density of a platform is to let users actually work on the system and then gradually add more users. This however is a risky approach as you may overload the environment and cause a negative user experience without knowing where the issue lies.

With the Nutanix Cloud Platform, you can start small and scale linearly by adding nodes to the cluster. But before you start baselining the platform it's important to understand the types of metrics you will be monitoring to measure system and user experience.

## Resource Usage Metrics

The following metrics relate to the system performance directly and need to be kept under certain thresholds in order for the platform to function as expected.

### Host Metrics

The below are typical metrics required from the Nutanix host to ensure it is performing correctly.

| **Metric** | **Description** | 
| :--- | :--- |
| CPU usage | The CPU usage during the test run | 
| Memory usage | The memory usage during the test run | 
| Storage controller IO | The Read, Write IO During the test run | 
| Storage controller latency | The Storage Controller Latency during the test run | 

### Virtual Machine Metrics

The below are typical metrics required from the Virtual Machine to ensure it is performing correctly.

| **Metric** | **Description** | 
| :--- | :--- |
| CPU usage | The CPU usage during the test run | 
| CPU ready time | The CPU ready time during the test run | 
| Memory usage | The memory usage during the test run | 
| Display protocol CPU usage | The Display Protocol CPU usage During the test run | 
| Display protocol Frames per Second | The FPS during the test run | 

## User Experience metrics

The below are typical metrics required to measure the user experience during the benchmark.

### Login Time Metrics

The below are typical metrics required to measure the login times.

| **Metric** | **Description** | 
| :--- | :--- |
| Total login time | The total login time during the test run | 
| Profile load time | The time taken to load the user profile during the test run | 
| Connection time | The time to connect to the resource during the test run | 
| GPO load time | The time to process the Group Policies assigned During the test run | 


### Application Performance Metrics

The below are typical metrics required to measure application performance during a test

| **Metric** | **Description** | 
| :--- | :--- |
| Application start times | The time taken to open up various applications during the test run | 
| Application open file times | The time taken to open a file during the test run | 
| Apllication save file times | The time to save a file during the test run | 

# Setup your environment for consistent EUC benchmark testing

## Master Image

The master image is one of the most important first steps you will undertake when setting up your environment to run EUC benchmark tests, after all, it is this image that will be the basis for all of your tests. Having a repeatable, consistent process here is paramount.

Consider the steps that are normally undertaken to build an EUC Master Image:

- Define the Virtual Machine SPecs
- Install the Operating System
- Install Additional Software
- Optimize the Image
- Snapshot the image

If this was only being done once, then a manual approach may be sufficient, however as you will be testing various hardware, software and configuration changes even if it was a single person manually building the image every time there is too much to remember and something will be done differently. Whilst that not seem a huge problem, a single config difference can have a massive impact on the test and therefore the numbers you are seeing as a result of the test run.

Key things to consider when building a master image are:

- Automate, automate, automate. Ensure everything is a repeatable task
- Run the same optimizations across all tests
- Dont forget application optimizations, these can make a big difference in performance
- Ensure all your testing team are using the same deployment method for building master images
- Consider the use of containers to standardize on image deployment methods


  - Reboot before testing
  - Launchers
    - Display protocol
    - Screen resolution
    - Offloading to client
  - Logon window

## Persistent vs Non-Persistent - Run 1 vs Run 2 data - DB

Unless testing a profile solution where the profiles are saved to a file share of some type then the difference between testing persistent and non-persistent workloads needs to be catered for in the reporting of the benchmark test.

First a brief explanation of what both technologies are.

### Persistent 

A persistent workload is one that retains all the user settings at logoff. Therefore any changes the user makes to an application configuration or environment setting is retained and the next time they log in those changes "persist"

### Non-Persistent

A non-persistent workload is one that will not retain any settings at logoff unless specifically catered for by an external profile solution. I this case any changes that the user makes during their session will be disguarded at logoff and the next time they log in they will be treated as a new user on the platform.

Looking at the above definitions its important to note that if you are testing with persistent workloads and doing multiple runs of the same test you will see differences in the login and user experience metrics from the second run onwards. This is because when the user logs in for the first time their profile is created and set up, this takes a little more time that just loading the profile. From run 2 onwards the profile already exists as the workload is persistent and will therefore reflect this in the metrics being pulled back from the platform resulting in faster logins.

Compare this to a non-persistent workload where the user profile is created as a "new user" every login and will therefore have a more stable user experience metric base but may not show the fastest login times available.

With regard to performance benchmarking as we are looking at getting the most consistent experience possible to show the differences between configuration changes it is recommended to use non-persistent workloads when validating.

## Local vs Roaming vs Containerized Profiles

The profile type will have an impact on the test data and additional considerations need to be put in place when testing for this. Details of this can be seen below.

### Local Profiles

 - No profile retention unless testing a persistent workload
 - All IO runs from the Workload Cluster
 - CPU Load will be run from the Workload Cluster
 - No reason to worry about profile size

### Roaming Profiles

### Containerized Profiles

  - BIOS settings / C-states
  - Optimizations

# Benchmark examples



<note>

</note>



# Performance Testing With Login VSI

