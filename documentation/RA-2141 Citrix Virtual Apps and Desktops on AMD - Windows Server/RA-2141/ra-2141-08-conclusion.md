# Conclusion

The Citrix Virtual Apps and Desktops and Nutanix solution provides a single high-density platform for virtual desktop delivery. This modular, linearly scaling approach lets you grow Citrix Virtual Apps and Desktops deployments easily. Localized and distributed caching and integrated disaster recovery enable quick deployments and simplify day-to-day operations. Robust self-healing and multistorage controllers deliver high availability in the face of failure or rolling upgrades.

On Nutanix, available host CPU resources drive Citrix Virtual Apps and Desktops user density, rather than any I/O or resource bottlenecks for virtual desktops. Login Enterprise test results showed densities at 180 sessions per node for virtual workloads running the Login Enterprise knowledge worker workload. Nutanix offers a pay-as-you grow model that works like public cloud.

Our results show that if you use MCS-published or Provisioning-streamed servers to linearly scale the Citrix Virtual Apps and Desktops on Nutanix solution, the system maintains the same average response times regardless of how many nodes you have. 

The results from the tests performed show:

-  The tested session host specification provided a consistent user experience across all tests.

-  `TBD for Server Tests` CPU configurations with Windows 11 are critical. A 3 vCPU instance performed better than a 2 vCPU instance. Windows 10 with 2 vCPUs still showed lower application response times than Windows 11 with 3 vCPU. 
-  `TBD for Server Tests` The overall cluster metrics were not impacted by using a 3 vCPU spec configuration with Windows 11 vs a 2 vCPU configuration with Windows 10.
-  `TBD for Server Tests` Both PVS and MCS configurations performed similarly though logon times were slightly higher with PVS.
-  `TBD for Server Tests` Application start times were generally better with MCS than PVS. This is logical due to data being streamed on first access with PVS. Subsequent launches will be launched from local cache.