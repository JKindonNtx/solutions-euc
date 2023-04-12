# Executive Summary

Securing business critical applications is a key requirement for organizations, because agility depends on efficient and reliable IT infrastructure. Organizations with virtual desktop infrastructure (VDI) must secure VDI assets from malware, malicious users, and unprivileged access to critical enterprise applications. With Nutanix Flow Network Security, organizations can use microsegmentation to secure their Citrix Virtual Apps and Desktops (CVAD) environment running on Nutanix AHV. Nutanix Flow Network Security based microsegmentation in CVAD offers the following security benefits: 

## Prevent lateral movement
Many modern attacks spread by compromising an internal asset and spreading laterally through the internal network, causing an even larger compromise or eventually gaining access to critical assets. Flow-based microsegmentation prevents this lateral movement from one asset to another by securing all VM-to-VM access. In a VDI environment protected by Nutanix Flow, even if a VM is compromised, the L4 (TCP/UDP/ICMP) stateful, inspection-based policy enforcement prevents access to other VMs and stops the attack.  

## Allow inbound traffic to desktops and applications
You can secure the TCP/IP traffic connections coming into a VM using Flow 5-Tuple inbound policies based on either incoming subnets or defined Prism Central categories. This method prevents any unauthorized network access to VMs. You can also protect any application VM running on AHV using Flow security policies and an inbound safe list.

## Allow outbound traffic from desktops
You can secure the outbound TCP/IP traffic connections using Flow 5-Tuple outbound policies based on either outbound subnets or defined Prism Central categories. This method prevents any unauthorized network access from VMs.
