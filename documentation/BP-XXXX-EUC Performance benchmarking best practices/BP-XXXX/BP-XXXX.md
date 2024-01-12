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
- Application save file times

A good user experience is not only defined by how fast a logon is or how fast an application starts, a consistent user experience is even more important. For example, when a user is used to a logon time of 30 seconds every day, but all of a sudden the logon time is 60 seconds, this user will start complaining about a slow system. While other users might have a logon time of 60 seconds every day, and be fine with it because it's always like this. If the logon time is inconsistent all the time, one day 25 seconds, the other day 50 seconds, and the next day 10 seconds, the user will get used to an inconsistent logon time, but is probably not happy about it. In an EUC Benchmark test, you want to see consistent logon times and consistent application times. If the average logon time for the first 10 users is 20 seconds, then you want to see a similar logon time for the last 10 users.
In the user experience metrics, there are two ways to look at the results. If you want to know at what point it's not realistic to add more users to the system, you look at the difference in the numbers between the first users and the last users. If the logon time for the first 10 users is on average 20 seconds, you will see that these logon times start to increase gradually during the time more users are logged on to the system. At a certain point, the load on the system could come at a point where the logon time increases progressively. Just before that point is the point where you should not logon more users. 
Once you know how many sessions you should logon to the system without going over that tipping point, you could compare the average numbers as well. Let's say you run a benchmark test on a system and the average logon time is 20 seconds. You then install a security patch on the system and run the test again. Now the average logon time is 25 seconds. You now know the impact of that security patch on the logon times. When you plan to add nodes with a different CPU type to an EUC environment, logons and application starts could be different and users may notice when logging on to the old system one day, and logging on to the new system the other day. This can also be the case when using cloud infrastructure, where users could be on different CPU models at various moments in time. A consistent user experience is not guaranteed in such environments.

# Setup the infrastructure for EUC benchmark testing
In this chapter we discuss the considerations for setting up the infrastructure to perform a benchmark test.

## Reboot before testing
Before you start a benchmark test, you should consider if you need to reboot components or not. For some components, it's important to start clean, with fresh memory and empty caches. This is especially important for the target machines, as it could cause big variations in test results. You could argue that a reboot is important for the hypervisor as well, but in our experience, the impact is negligible, especially when you don't use memory sharing technologies on hypervisor level (like ballooning).
You can also reboot the client VMs (launchers) before each test. However, in some cases this can result in slower login times for the first user starting a session from that client. This can affect the average login scores.

## Clients (Launchers)
You can start a workload simulation direct on the (console of) a target VM. If you want to simulate the use of a display protocol as well, which has an impact on the resource usage as well, you should use clients that connect using a display protocol from the broker being used. These clients can be physical or virtual and start one or more sessions (depending on the benchmark tool). It's important to configure these clients always with the same specifications. Think about screen resolution, display protocol settings and offloading settings like video and audio.

## Logon window
The Logon Window is the time to login all the sessions. Another definition that is used is Logon rate, which defines the number of logons per second or minute. The logon phase during a benchmark test is often the most resource intensive phase. If the logon window is too short, you will most likely run into CPU contention on the system. In our tests, we always use a logon window of 48 minutes, no matter how many sessions we configure. The thought behind this is, if we configure more sessions to logon, the node or cluster should be able to handle more sessions as well. If a node is capable of logging on 100 sessions on 1 node in 48 minutes, a 4 node cluster of the same type should be able to logon 400 sessions in 48 minutes.

  - Persistent vs non-persistent
  - Local vs roaming vs containerized profiles


 ## BIOS settings
Modern CPUs utilized a technology called "C-States" to manage the amount of power that individual processor cores are utilizing.  When a core is idle, the server's BIOS will reduce its clock rate, power draw, or both in an effort to make the system more energy efficient.  In most cases, this is the desired condition as it can significantly reduce power consumption. The unused power may be used by other CPU cores to increase their frequency (GHz), allowing instructions executing on active CPU cores to complete faster.
For EUC workloads, this is not a desired behavior. As described earlier, a consistent user experience is very important. When these kind of "power throttling" technologies are enabled, user can experience inconsistent performance. Therefor, it's best to disable c-states to make sure the processors are always running at the same speed. In most servers, setting the BIOS to "High Performance" will also disable processor c-states.
<note>
Do not change Power Management Configuration settings in the BIOS. Nutanix does not support custom power management configurations, and changing the power management settings in the BIOS can cause unpredictable behavior. The Nutanix BIOS contains optimized power management settings by default.
</note>

  - Optimizations

# Benchmark examples



<note>

</note>



# Performance Testing With Login VSI



# References

https://portal.nutanix.com/page/documents/details?targetId=Release-Notes-BMC-BIOS:Nutanix%20BMC%20and%20BIOS%20Overview