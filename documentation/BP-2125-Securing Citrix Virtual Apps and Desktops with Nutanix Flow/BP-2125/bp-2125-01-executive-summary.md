# Executive Summary

Securing business-critical applications is a key requirement for organizations because agility depends on efficient and reliable IT infrastructure. Organizations with virtual desktop infrastructure (VDI) must secure their environments from malware, malicious users, and unprivileged access to critical enterprise applications. With [Flow Network Security](https://www.nutanix.com/products/flow), organizations can use microsegmentation to secure their Citrix Virtual Apps and Desktops environments running on Nutanix AHV. Flow Network Security microsegmentation with Citrix Virtual Apps and Desktops offers the following security benefits: 

Prevent lateral movement 
: Many modern attacks spread by compromising an internal asset and moving laterally through the internal network, causing an even larger compromise or eventually gaining access to critical assets. Flow Network Security microsegmentation prevents this lateral movement from one asset to another by securing all VM-to-VM access. In a Citrix Virtual Apps and Desktops environment protected by Flow Network Security, even if a VM is compromised, stateful layer 4 (L4—TCP, UDP, or ICMP) inspection-based policy enforcement prevents access to other VMs and stops the attack.

Secure inbound traffic to desktops and applications 
: You can secure the TCP/IP traffic connections coming into a VM using Flow Network Security inbound policies based on either incoming subnets or categories defined in Prism Central. This feature prevents any unauthorized network access to VMs. You can also protect any application VM running on AHV using Flow Network Security policies and an inbound safe list.

Secure outbound traffic from VMs 
: You can secure outbound TCP/IP traffic connections using Flow Network Security outbound policies based on either outbound subnets or categories defined in Prism Central. This feature prevents any unauthorized network access from VMs.
