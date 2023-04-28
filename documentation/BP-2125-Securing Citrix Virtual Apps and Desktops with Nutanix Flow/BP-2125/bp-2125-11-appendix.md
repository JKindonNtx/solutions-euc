# Appendix

## References

1. [Communication Ports Used by Citrix Technologies](https://docs.citrix.com/en-us/tech-zone/build/tech-papers/citrix-communication-ports.html)
2. [Flow Network Security Guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Guide:Nutanix-Flow-Guide)
3. [Prism Central Guide: Flow Virtual Networking](https://portal.nutanix.com/page/documents/details?targetId=Prism-Central-Guide-Prism:mul-flow-networking-pc-c.html)
4. [Prism Central Guide: Security Policies Summary](https://portal.nutanix.com/page/documents/details?targetId=Prism-Central-Guide-Prism:mul-security-policies-flow-pc-t.html)
5. [Prism Central Guide: Categories Summary](https://portal.nutanix.com/page/documents/details?targetId=Prism-Central-Guide-Prism:ssp-ssp-categories-manage-pc-c.html)
6. [Nutanix Bible](https://www.nutanixbible.com)
7. [Nutanix.com](https://www.nutanix.com/products/cloud-platform)

## Flow Network Security Design and Predeployment Checklist

Use the following checklist before implementing a Flow Network Security design for Citrix. Flow Network Security offers native visualization and monitoring to confirm application connectivity requirements and provide simplified policy management. However, there is no substitute for collecting requirements from the application and business owners and getting buy-in and approval.

Contact and invite the following key stakeholders:

- Security team
- Network team
- Citrix team
- Application teams
- Virtualization and server teams

Collect the following information from the Citrix team:

- Architecture diagram of Citrix infrastructure with IP addresses
- Number and size of desktop pools
- Whether pools are dedicated to a specific use case or shared between different groups
- Whether a single desktop VM hosts a single user or if desktops are shared with multiple users at once
- Where users connect and if the system uses a gateway or load balancer
- The applications and file storage used by desktops, such as NAS shares, app layering, and profiles

Collect the following information with input from all teams:

- List of applications that run in a virtual environment
- List of applications that run in a physical environment
- List of applications that run in both physical and virtual environments
- List of all virtual applications planned to run on Nutanix AHV

<note>
For each application, also identify the owner of the application.
</note>

For each virtual application planned to run on AHV, collect as much of the following information as possible:

- Connectivity diagram
- List of open ports and protocols
- List of inbound and outbound connections
- External internet access requirements
- Special connectivity or security requirements such as isolation, load balancing, multicast, or high availability protocols
- Groups of applications that have similar connectivity requirements
- Groups of applications that must be totally isolated from each other

<note>
Microsegmentation is an iterative process; every change made to the environment can affect communication, requiring you to check and validate the security policy and definitions.
</note>
