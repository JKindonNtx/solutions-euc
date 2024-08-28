# Flow Network Security System Logging

Using Prism Central, you can configure syslog monitoring to forward system logs (API Audit, Audit, Security Policy Hitlogs, and Flow Service Logs) of the registered clusters to an external syslog server. 

Prism Central enables you to configure multiple remote syslog servers. Additionally, you can configure separate log modules to be sent to each of the rsyslog servers.

Note: The Prism Central method of syslog monitoring configuration propagates the configuration to the Prism Element clusters. If you do not want the configuration to be propagated to the clusters, you must use Nutanix command-line interface (nCLI) for syslog monitoring configuration.