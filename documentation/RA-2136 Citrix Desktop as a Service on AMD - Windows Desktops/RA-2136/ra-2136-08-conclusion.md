# Conclusion

The Citrix DaaS and Nutanix solution provides a single high-density platform for virtual desktop delivery. This modular, linearly scaling approach lets you grow Citrix DaaS deployments easily. Localized and distributed caching and integrated disaster recovery enable quick deployments and simplify day-to-day operations. Robust self-healing and multistorage controllers deliver high availability in the face of failure or rolling upgrades.

On Nutanix, available host CPU resources drive Citrix DaaS user density, rather than any I/O or resource bottlenecks for virtual desktops. Login Enterprise test results showed densities at 150 sessions per node for virtual workloads running the Login Enterprise knowledge worker workload. Nutanix offers a pay-as-you grow model that works like public cloud.

Our results show that if you use MCS-published or Provisioning-streamed servers to linearly scale the Citrix DaaS on Nutanix solution, the system maintains the same average response times regardless of how many nodes you have. 

The results from the tests performed show:

-  When comparing Windows 10 to Windows 11, Windows 11 has a higher CPU footprint during the boot phase.
-  When both Windows 10 and Windows 11 are optimized, the logon experience is similar.
-  Application response times are generally similar between  Windows 11 and Windows 10.
-  CPU configurations with Windows 11 are critical. A 3 vCPU instance performed better than a 2 vCPU instance.
-  The overall cluster metrics were not impacted by using a 3 vCPU spec configuration with Windows 11 vs a 2 vCPU configuration with Windows 10. There was a logical higher CPU ready time with a 3 vCPU configuration.
-  Both PVS and MCS configurations performed similarly though logon times were slightly higher with PVS.
-  Application start times were generally better with MCS than PVS. This is logical due to data being streamed on first access with PVS. Subsequent launches will be launched from local cache.
-  PVS has a higher write impact on the cluster hosting the workloads, whereas MCS has a higher read impact. This is expected due to the write heavy nature of the PVS filter driver.