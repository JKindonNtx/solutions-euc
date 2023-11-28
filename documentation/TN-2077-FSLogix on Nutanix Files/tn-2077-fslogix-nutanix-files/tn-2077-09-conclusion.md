# Conclusion

Nutanix Files has proven to be an excellent choice for hosting FSLogix workloads. Across all testing scenarios, Files showed its ability to perform consistently and support user workloads relying on FSLogix Container solutions, both in standard VHD deployments, and Cloud Cache based scenarios.

The testing identifies that FSLogix deployments can have impacts on both Nutanix Files, and on the Clusters hosting the workloads depending on the deployment architecture: 

-  For deployments using VHD locations, features such as FSLogix Compaction will have an impact on Nutanix Files during a logoff phase
-  For deployments using VHD locations and Mode 3 disks, there is impact on both Nutanix Files and the workload clusters. We identified higher workload cluster utilization with Mode 3 disks. We also identified slightly higher logon times, though the impact is not significant. We recommend Mode 0 disks are used unless there is a requirement for Mode 3 capability.
-  For deployments using VHD locations, we recommend `Continuous Availability` is **enabled** on the Nutanix Files shares as it provides enhanced resiliency for container workloads. The IO impact of `CA` is spread across the Cluster Controllers hosting the Nutanix Files deployment. This means the metrics from Nutanix Files itself will show a reduction in IO when measuring directly from Files.
- For Cloud Cache enabled deployments, we recommend `Continuous Availability` is **disabled** on the Nutanix Files Shares due to known interoperability issues with Cloud Cache and CA.
- For Cloud Cache enabled deployments, the IO operations are spread across both the Nutanix Files backend, and then workload clusters. Customers should be cognizant of impacts and sizing requirements before enabling Cloud Cache.

We tested FSLogix using only Profile Containers and not Office Containers. This decision was driven by two reasons:

1. Microsoft guidance suggests that customers use Profile Containers only from a simplicity standard.
2. Data that is typically moved to an Office Container is primarily focused on Microsoft 365 Cache Data (OneDrive, Microsoft Outlook OST, and other associated temporary or non critical data). Our testing environment does not use Microsoft 365 services, as such, the value in testing two container mounts vs a single container was deemed minimal.