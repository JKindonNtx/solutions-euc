# Appendix

## References

- [Communication Ports Used by Citrix Technologies](https://docs.citrix.com/en-us/tech-zone/build/tech-papers/citrix-communication-ports.html)
- [Prism Central Guide: Nutanix Flow](https://portal.nutanix.com/page/documents/details?targetId=Prism-Central-Guide-Prism-vpc_2022_4:mul-flow-networking-pc-c.html)
- [Prism Central Guide: Security Policies Summary](https://portal.nutanix.com/page/documents/details?targetId=Prism-Central-Guide-Prism-vpc_2022_4:mul-security-policies-flow-pc-t.html)
- [Prism Central Guide: Categories Summary](https://portal.nutanix.com/page/documents/details?targetId=Prism-Central-Guide-Prism-vpc_2022_4:ssp-ssp-categories-manage-pc-c.html)
- [Nutanix Bible](https://www.nutanixbible.com)
- [Nutanix.com](https://www.nutanix.com/products/cloud-platform)

## Nutanix Flow Design and Pre-deployment Checklist

Use the following checklist before implementing a Flow design for Citrix. Flow offers native visualization and monitoring to confirm connectivity requirements of applications, as well as simplified policy management. However, there is no substitute for collecting requirements from the application and business owners and getting buy-in and approval.

Contact and invite the following key stakeholders:

- Security team.
- Network team.
- Citrix team.
- Application teams.
- Virtualization and server teams.

Collect the following from the Citrix team:

- Architecture diagram of Citrix infrastructure with IP addresses.
- Number and size of desktop pools.
- Whether pools are dedicated to a specific use case or shared between different groups.
- Whether a single desktop VM hosts a single user or if desktops are shared with multiple users at once.
- Where users connect from and if there is a gateway or load balancer used.
- The applications and file storage used by desktops, such as NAS shares, app layering, and profiles.

Collect the following information with input from all teams:

- List of applications that run in a virtual environment.
- List of applications that run in a physical environment.
- List of applications that have a split of physical and virtual environments.
- Identify all virtual applications that are going to run on Nutanix AHV.
- For each application, identify the owner of the application.
- For each virtual application on AHV, collect as much of the following as possible:
  - Connectivity diagram.
  - List of open ports and protocols.
  - List of inbound and outbound connections.
  - External Internet access requirements.
  - Special connectivity or security requirements such as isolation, load balancing, multicast, and high availability protocols.
  - Identify groups of applications that have similar connectivity requirements.
  - Identify groups of applications that must be totally isolated from each other.

<note>
    The process of microsegmentation is an iterative one in that every time a change is made to the environment that may effect communications the security policy and definitions need to be checked and validated.
</note>
