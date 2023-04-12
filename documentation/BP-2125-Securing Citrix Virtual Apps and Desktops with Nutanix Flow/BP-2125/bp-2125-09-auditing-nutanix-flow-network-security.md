# Auditing Nutanix Flow Network Security

## Audit Logs

Logging is an important part of security infrastructure, and Flow provides audit logs. Audit logs track changes to security policy configuration and VM category mappings and show when a policy was changed or applied and who changed it. To see your audit logs, click the Prism Central menu button, navigate to the Activity menu, then click Audits. Audit logs are enabled by default and capture all changes made in Prism Central related to Flow.

## Configure Logging

Logging is an important part of security infrastructure, and Flow provides two types of logs: audit logs and policy hit logs. Audit logs track changes to security policy configuration and VM category mappings and show when a policy was changed or applied and who changed it. Policy hit logs track network flows and whether they were allowed or denied by a specific policy. Use them to determine if specific traffic is present on the network and what effect a security policy has on traffic.

Audit logs are enabled by default and capture all changes made in Prism Central related to Flow. You must enable policy hit logs per policy if you want them; they’re disabled by default. Policy hit logs may generate a large amount of data. To analyze the data from policy hit logs, use an external remote syslog server or SIEM (Security Information and Event Management) system to collect these events.

Audit logs are sent from Prism Central to the remote syslog server, but you can also see them in Prism Central. Policy hit logs are sent directly from each AHV host to the syslog server but generate too much data to consume inside Prism. That’s why you must perform analysis on the external appliance for policy hit logs. Ensure that the remote syslog server or SIEM expects traffic from both Prism Central and each individual AHV host. Configure a remote syslog server in Prism Central by selecting the gear icon for Settings and clicking Syslog Server. 

Add the server address and select the desired port and protocol and click Next.

![Syslog Server](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image43.png "Syslog Server")

Then select the data sources you wish to send and click Save

![Syslog Server Rules](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image44.png "Syslog Server Rules")