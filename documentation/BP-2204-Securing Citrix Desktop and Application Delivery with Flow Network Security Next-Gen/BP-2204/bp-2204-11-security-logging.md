# Security Logging
<!--JK: I reworded slightly
Having access to security logging and history is crucial to be able to investigate the root cause of an attack or breach.
-->
To investigate or perform root cause analysis on an attack or breach, logging is critical. Using Prism Central, you can configure syslog monitoring to forward system logs (API Audit, Audit, Security Policy Hit logs, and Flow Service Logs) of the registered clusters to an external syslog server. 

Prism Central enables you to configure multiple remote syslog servers. Additionally, you can configure separate log modules to be sent to each of the syslog servers.

<note>
The Prism Central method of syslog monitoring configuration propagates the configuration to the Prism Element clusters. If you do not want the configuration to be propagated to the clusters, you must use Nutanix command-line interface (nCLI) for syslog monitoring configuration.
</note>

For further information about configuring security logging please read the [Nutanix Prism Central Admin Guide](https://portal.nutanix.com/page/documents/details?targetId=Prism-Central-Admin-Center-Guide-vpc_2024_1:mul-syslog-server-configure-pc-t.html).