# Security Design Considerations

A secure Citrix Desktop and Application deployment is critical for protecting sensitive business data, and maintaining uninterrupted access to critical desktops and applications. 

Laying out requirements prior to implementing micro segmentation will provide a seamless implementation of security controls without interruption to business operations.

Typically Citrix Desktop and Application deployments can be broken down into individual components as described earlier in this guide. The most common (but not limited to) components for a Citrix Desktop and Application deployment are:

- Citrix Licensing
- Citrix StoreFront
- Citrix Director
- Citrix Delivery Controllers
- Citrix Cloud Connectors
- Citrix Federated Authentication
- Citrix Workspace Environment Management
- Citrix Session Recording
- Citrix Provisioning
- Citrix Virtual Desktop Agents
- Microsoft SQL Server

Other supporting service must also be considered when designing security such as (but not limited to):

- Microsoft Active Directory
- File Services
- Core Networking Services
- Printing

Each of these components or entities have unique requirements for inbound and outbound network traffic.

For Citrix Desktop and Application deployments required network port and protocol details can be found in the [Communication Ports Used by Citrix Technologies Guide](https://community.citrix.com/tech-zone/build/tech-papers/citrix-communication-ports). 

A good knowledge networking requirements is critical before attempting to implement network segmentation as a misconfiguration could severely effect the operational ability and stability of your deployment.

<note>
In a typical deployment windows firewall is commonly used to block inbound network traffic, however, little consideration is given to the outbound traffic. This is still a valid approach as a layered security posture is a desired approach in most situations.
</note>

Taking Citrix Licensing as an example, there are 3 elements required to properly design the security requirements for that component of the deployment.

![Image showing Citrix Licensing as a component with inbound and outbound networking requirements](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image03.png "Image showing Citrix Licensing as a component with inbound and outbound networking requirements")

| Element | Description | 
| :---: | --- | 
| Inbound | Networks, Services, Ports, and Protocols that require inbound communication to Citrix Licensing. Examples of this could be the Citrix Delivery Controllers and TCP Port 27000 | 
| Entity | The virtual machines servicing the element, in this case the Citrix Licensing server. | 
| Outbound | Networks, Services, Ports, and Protocols that require outbound communication from Citrix Licensing. An example could be access to the Domain Controllers for authentication. | 

Each component should be thoroughly documented prior to deploying microsegmentation to have the greatest chance of success when enforcing the security policy.

An non-exhaustive example of a Citrix Licensing security design tables are shown below.

_Table: Security Design Considerations: Citrix Licensing Inbound_

| Type | Detail | Protocol | Port | Description |
| --- | --- | --- | --- | --- |
| Network | Bastion Hosts | TCP | 8083 | Management of the license server from the bastion hosts |
| Category | Delivery Controllers | TCP | 27000 | Delivery Controller to License Server to validate licenses |
| Category | PVS Servers | TCP | 27000 | Citrix Provisioning to License Server to validate licenses |

_Table: Security Design Considerations: Citrix Licensing Outbound_

| Type | Detail | Protocol | Port | Description |
| --- | --- | --- | --- | --- |
| Category | Domain Controllers | TCP | 3269 | Global Catalog |
| Category | Domain Controllers | TCP | 3268 | Global Catalog |
| IP Address | DNS Servers | TCP | 53 | DNS |
