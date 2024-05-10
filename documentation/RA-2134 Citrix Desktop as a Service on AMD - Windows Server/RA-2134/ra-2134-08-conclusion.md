# Conclusion

The Citrix DaaS and Nutanix solution provides a single high-density platform for virtual desktop delivery. This modular, linearly scaling approach lets you grow Citrix DaaS deployments easily. Localized and distributed caching and integrated disaster recovery enable quick deployments and simplify day-to-day operations. Robust self-healing and multistorage controllers deliver high availability in the face of failure or rolling upgrades.

On Nutanix, available host CPU resources drive Citrix DaaS user density, rather than any I/O or resource bottlenecks for virtual desktops. Login Enterprise test results showed densities at 180 sessions per node for virtual workloads running the Login Enterprise knowledge worker workload. Nutanix offers a pay-as-you grow model that works like public cloud.

Our results show that if you use MCS-published or Provisioning-streamed servers to linearly scale the Citrix DaaS on Nutanix solution, the system maintains the same average response times regardless of how many nodes you have. 

The results from the tests performed show:

-  The tested session host specification provided a consistent user experience across all tests.
-  There was minimal cluster performance difference between MCS and PVS provisioning.
-  Both PVS and MCS configurations performed similarly though logon times were slightly higher with PVS.
-  Application start times were slightly better with PVS than MCS in these tests.
-  PVS has a higher write impact on the cluster hosting the workloads, whereas MCS has a higher read impact. This is expected due to the write heavy nature of the PVS filter driver.