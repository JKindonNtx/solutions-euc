# Executive Summary

This document describes the End User Computing (EUC) performance benchmarking best practices. Where possible we have recommended tools and guides that we see as being fit for purpose however these tools will differ in various enterprise deployments. 

# Introduction

At Nutanix, we run benchmark tests with EUC workloads for a number of reasons. 

First, we have to make sure that there is no regression with an EUC workload when you upgrade the Nutanix Cloud Infrastructure (NCI) to a newer version. 

We also run EUC performance benchmark tests to show the performance impact in various publications, like reference architectures, Nutanix Validated Designs, Technotes, and different online publications. 

And finally, we run these tests to validate the performance on different hardware platforms, with different CPU, memory and storage configurations. This helps us fine tune the Nutanix Sizer tool.

In this document, we describe the best practices for running EUC performance benchmark tests. 

An important aspect of running performance benchmark tests is to get consistent results. Once you are able to get consistent results, you are able to define a baseline, once done you can change the infrastructure or configuration, run the same test, and then determine the impact of that change.

## Audience

This technote is part of the Nutanix Solutions Library and provides an overview of the recommendations for running EUC performance benchmark tests. 

## Purpose

This document covers the following subject areas:

- Why Run Performance Benchmark Tests for EUC?
- Benchmarking Tools
- Consistency
- Benchmarking Metrics
- Setting Up Your Environment for Consistent Benchmark Testing
  - Master Images
  - Reboot Before Testing
  - Clients (Launchers)
  - Logon Window
  - BIOS Settings / C-States
  - Persistent vs Non-Persistent
  - Local vs File vs Container Profiles
  - Optimizations
- Benchmark Examples
  - Non Optimized
  - Wait Time
  - With vs Without Security Agents or Virus Protection
- Conclusion

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

- Publications like Reference Architecture documents, Nutanix Validated Design documents, Technotes or other online publications.
- Baseline new hardware platform releases, with newer CPU types, faster memory or storage configurations.
- To educate customers and our field teams, that use this information for sizing new EUC infrastructures.

# Benchmarking Tools

There a various benchmarking solutions that you can use to simulate an EUC workload. Keep the following guidelines in mind when selecting an EUC benchmarking solution:

- The tool must be able to simulate user behavior, like logging in to the virtual machines, starting applications, and opening, editing and saving documents with various applications. This is called a workload.
- It is preferable to be able to use applications in the simulated workload that are used by the user base in production, but it is more important to be able to have a repeatable workload that will have a consistent outcome.
- The benchmarking tool must be able to collect various metrics that can be used to compare multiple tests. 
- If the benchmarking tool does not provide the data you require be sure to investigate gathering this information using other tools available to you.
- A central reporting tool and being able to compare results is critical. Without this capability you will not have the ability to compare results against one another.

Benchmarking tools can be broken into various categories, and it is important to define the tool set that you are going to use prior to designing and implementing your solution. This is critical to ensure consistency across the platform, that in turn is crucial for good results from the tests. 

Below are some examples of those categories and software vendors that provide solutions in those areas:

| **Category** | **Description** | **Examples** |
| :--- | :--- | :--- |
| Workload Generation | Simulate user workloads on the endpoints being tested | Login Enterprise / Automai / LoadGen |
| Image Deployment | Operating System and Application deployment | MDT / Ansible / PowerShell |
| Automation | Automation of the Test Execution | PowerShell / Api / Containers |
| Data Collection | Ability to collect additional test data | PowerShell / Api / Telegraf |
| Storage | Central repository to store test data | InfluxDB / SQL / File Shares |
| Reporting | Central reporting console for the test data | Grafana / Custom Web page |

The key point here when defining and designing your environment for testing is that you have a repeatable and automated process. Having the test bed defined **exactly the same** for every test run is critical to ensure accurate results.

# Consistency

A good user experience is not only defined by how fast a logon is or how fast an application starts, a consistent user experience is even more important. 

For example, when a user is used to a logon time of 30 seconds every day, then the logon time increases 60 seconds, this user will start complaining about a slow system. While other users might have a logon time of 60 seconds every day, and be fine with it because it's always like this. 

If the logon time is inconsistent all the time, one day 25 seconds, the next day 50 seconds, and then back to 10 seconds, the user will get used to an inconsistent logon time, but is more than likely not happy about it. 

In an EUC Benchmark test, you want to see consistent logon times and consistent application times. If the average logon time for the first 10 users is 20 seconds, then you want to see a similar logon time for the last 10 users.

In the user experience metrics, there are two ways to look at the results. 

If you want to know at what point it's not realistic to add more users to the system, you look at the difference in the numbers between the first and last users. If the logon time for the first 10 users is on average 20 seconds, you will see that these logon times start to increase gradually while more users are logged on to the system. At a certain point, the load on the system will reach a point where the logon time increases progressively. Just before that point is the point where you should not load more users. 

Once you know how many sessions you should logon to the system without going over that tipping point, you could compare the average numbers as well. 

Let's say you run a benchmark test on a system and the average logon time is 20 seconds. You then install a security patch on the system and run the test again. Now the average logon time is 25 seconds. You now know the impact of that security patch on the logon times. 

When you plan to add nodes with a different CPU type to an EUC environment, logons and application starts could be different and users may notice when logging on to the old system one day, and logging on to the new system the next day. 

This can also be the case when using cloud infrastructure, where users could be on different CPU models at various moments in time. A consistent user experience is not guaranteed in such environments.

The key point here being that **consistency**, and your users will get used to and appreciate a stable, consistent user experience.

# Benchmarking Metrics

When benchmarking an EUC workload the key outcome desired is to know the baseline of your platform along with the performance difference after deploying changes to the environment. 

This is not easy to achieve with a benchmarking tool, as it is very difficult to simulate the real user workload of a production environment, however, what is relevant here is having the knowledge to accurately report on software and hardware changes and how this will impact your user experience. 

The best way to determine the user density of a platform is to let users actually work on the system and then gradually add more users. This however, is a risky approach, as you may overload the environment and cause a negative user experience without knowing where the issue lies.

With the Nutanix Cloud Platform, you can start small and scale linearly by adding nodes to the cluster. But before you start base lining the platform it's important to understand the types of metrics you will be monitoring to measure system and user experience.

## Resource Usage Metrics

The following metrics relate to the system performance directly and need to be kept under certain thresholds in order for the platform to perform as expected.

### Host Metrics

The below are typical metrics required from the Nutanix host to ensure it is performing correctly.

| **Metric** | **Description** | **Good Result** |
| :--- | :--- | :--- |
| CPU usage | The CPU usage | X |
| Memory usage | The memory usage |  X |
| Storage controller IO | The read, write IO  |  X |
| Storage controller latency | The Storage Controller Latency |  X |

### Virtual Machine Metrics

The below are typical metrics required from the Virtual Machine to ensure it is performing correctly.

| **Metric** | **Description** | **Good Result** |
| :--- | :--- | :--- |
| CPU usage | The CPU usage  | X |
| CPU ready time | The CPU ready time | X |
| Memory usage | The memory usage  | X |
| Display protocol CPU usage | The Display Protocol CPU usage  | X |
| Display protocol Frames per Second | The Frames per second | X |

## User Experience metrics

The below are typical metrics required to measure the user experience during the test.

### Login Time Metrics

The below are typical metrics required to measure the login times.

| **Metric** | **Description** | **Good Result** |
| :--- | :--- | :--- |
| Total login time | The total login time | < 30 secs |
| Profile load time | The time taken to load the user profile  | X |
| Connection time | The time to connect to the resource | X |
| GPO load time | The time to process the Group Policies assigned | X |


### Application Performance Metrics

The below are typical metrics required to measure application performance during a test

| **Metric** | **Description** | **Good Result** |
| :--- | :--- | :--- |
| Application start times | The time taken to open up various applications  | X |
| Application open file times | The time taken to open a file | X |
| Application save file times | The time to save a file | X |

# Setting Up Your Environment for Consistent Benchmark Testing

In this chapter we discuss the considerations for setting up the infrastructure to perform a benchmark test.

## Master Image

The master image is one of the most important first steps you will undertake when setting up your environment to run EUC benchmark tests, after all, it is this image that will be the basis for all of your user activity. Having a repeatable, consistent process here is paramount.

Consider the steps that are normally undertaken to build an EUC Master Image:

- Define the Virtual Machine Specifications.
- Install the Operating System.
- Install Additional Software.
- Optimize the Image.
- Snapshot the image.

If this was only being done once, then a manual approach may be sufficient, however as you will be testing various hardware, software and configuration changes even if it was a single person manually building the image every time there is too much to remember and something will be done differently. Whilst that not seem a huge problem, a single config difference can have a massive impact on the test and therefore the numbers you are seeing as a result of the test run.

Key things to consider when building a master image are:

- Automate, automate, automate. Ensure everything is a repeatable task.
- Run the same optimizations across all tests.
- Don't forget application optimizations, these can make a big difference in performance.
- Ensure all your testing team are using the same deployment method for building master images.
- Consider the use of containers to standardize on image deployment methods.

## Reboot Before Testing

Before you start a benchmark test, you should consider if you need to reboot components or not. For some components, it's important to start clean, with fresh memory and empty caches. This is especially important for the target machines, as it could cause big variations in test results. Another consideration here is to tune the hypervisor connection from your chosen broker to allow for mass actions to take place (such as reboot) within a given time frame. Please refer to your broker documentation to read the current best practice guidelines.

You could argue that a reboot is important for the hypervisor as well, but in our experience, the impact is negligible, especially when you don't use memory sharing technologies on hypervisor level (like ballooning).

You can also reboot the client VMs (launchers) before each test. However, in some cases this can result in slower login times for the first user starting a session from that client. This can affect the average login scores and is something to be mindful of.

## Clients (Launchers)

You can start a workload simulation direct on the console of a target VM, however, if you want to simulate the use of a display protocol as well (which has an impact on the resource usage as well) you should use clients that connect using a display protocol from the chosen broker being used. 

These clients can be physical or virtual and start one or more sessions (depending on the benchmark tool). 

It's important to configure these clients with the same specifications, think about screen resolution, display protocol settings and offload settings like video and audio.

## Logon Window

The Logon Window is the time to login all the sessions defined withing the test parameters. Another definition that is used is Logon rate, which defines the number of logons per second or minute. 

The logon phase during a benchmark test is often the most resource intensive phase. If the logon window is too short, you will most likely run into CPU contention on the system. 

In our tests, we always use a logon window of 48 minutes, no matter how many sessions we configure. 

The thought behind this is, if we configure more sessions to logon, the node or cluster should be able to handle more sessions as well. If a node is capable of logging on 100 sessions on 1 node in 48 minutes, a 4 node cluster of the same type should be able to log on 400 sessions in 48 minutes.

## BIOS settings

Modern CPUs utilize a technology called "C-States" to manage the amount of power that individual processor cores are utilizing.  When a core is idle, the server's BIOS will reduce its clock rate, power draw, or both in an effort to make the system more energy efficient.  In most cases, this is the desired condition as it can significantly reduce power consumption. The unused power may be used by other CPU cores to increase their frequency (GHz), allowing instructions executing on active CPU cores to complete faster.

For EUC workloads, this is not a desired behavior. As described earlier, a consistent user experience is very important. When this kind of "power throttling" technologies are enabled, users can experience inconsistent performance. Therefore, it's best to disable c-states to make sure the processors are always running at the same speed. 

In most servers, setting the BIOS to "High Performance" will also disable processor c-states.

<note>
Do not change Power Management Configuration settings in the BIOS for Nutanix NX hardware. Nutanix does not support custom power management configurations, and changing the power management settings in the BIOS can cause unpredictable behavior. The Nutanix BIOS contains optimized power management settings by default.
</note>

## Persistent vs Non-Persistent

Unless testing a profile solution where the profiles are saved to a file share then the difference between testing persistent and non-persistent workloads needs to be catered for in the reporting of the benchmark test.

First a brief explanation of what both technologies are.

### Persistent 

A persistent workload is one that retains all the user settings at logoff. Therefore, any changes the user makes to an application configuration or environment setting are retained and the next time they log in those changes "persist"

### Non-Persistent

A non-persistent workload is one that will not retain any settings at logoff unless specifically catered for by an external profile solution. In this case any changes that the user makes during their session will be discarded at logoff and the next time they log in they will be treated as a new user on the platform.

Looking at the above definitions It's important to note that if you are testing with persistent workloads and doing multiple runs of the same test you will see differences in the login and user experience metrics from the second run onwards. This is because when the user logs in for the first time their profile is created and set up, this takes a little more time than just loading the profile. From run 2 onwards the profile already exists as the workload is persistent and will therefore reflect this in the metrics being pulled back from the platform resulting in faster logins.

Compare this to a non-persistent workload where the user profile is created as a "new user" every login and will therefore have a more stable user experience metric base but may not show the fastest login times available.

With regard to performance benchmarking as we are looking at getting the most consistent experience possible to show the differences between configuration changes it is recommended to use non-persistent workloads when validating baseline platform metrics.

## Local vs Roaming vs Containerized Profiles

The profile type will have an impact on the test data and additional considerations need to be put in place when testing for this. Details of this can be seen below.

### Local Profiles

 - No profile retention unless testing a persistent workload.
 - All IO on the Workload Cluster.
 - CPU Load on the Workload Cluster.
 - No reason to worry about profile size.

### File Based Profiles

 - Profile retention using external file share.
 - IO on Workload Cluster higher during logon.
 - CPU Load on the Workload Cluster.
 - Profile size needs to be managed via exclusions.
 - File server performance considerations.
  
### Container Based Profiles

 - Profile retention using external file share.
 - IO split between Workload and File Server Cluster dependent on configuration.
 - CPU Load split between Workload and File Server Cluster dependent on configuration.
 - Profile size less relevant.
 - File server performance considerations.
  
## Optimization

Operating System optimizations have a huge impact on system performance when dealing with EUC workloads. 

The Problem: "**Windows is full of bloat!**"

Windows can be deployed on thousands of different devices to perform thousands of different tasks. Bloat makes sense here as Microsoft need to cover all the bases to make it work for the consumer across many scenarios. However, in an EUC deployment, many functions of Windows do not make sense. 

Some of these are:

- Windows Updates.
- The XBox Application.
- Wi-Fi Services.

These are just a few examples of the many settings that can be safely disabled on a Windows Server or Windows Desktop operating system before benchmarking the platform. All these services, processes or applications use up precious CPU cycles or memory, therefore decreasing the performance and number of users we can fit onto the platform.

Optimizing an image is a balancing act. We should be looking to disable everything that will not be required to get the best performance, but not be so aggressive that they render the virtual desktop useless. Some of the options available are:

| **Vendor** | **Tool** | 
| :--- | :--- | 
| Citrix | Citrix Optimizer Tool | 
| VMware | Windows OS Optimization Tool  |
| Microsoft | (Windows) Virtual Desktop Optimization Tool | 

# Benchmark examples

## Not Optimized

## Wait Time

## With or Without Security Agents or Virus Protection?

# Conclusion
consistenct
optimize
workload need to represent prod
able to compare results directly
data retention
compare boot storm - logon phase and steady state

# References

https://portal.nutanix.com/page/documents/details?targetId=Release-Notes-BMC-BIOS:Nutanix%20BMC%20and%20BIOS%20Overview