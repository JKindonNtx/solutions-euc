# Security Design Considerations

A secure Citrix Desktop and Application deployment is critical for protecting sensitive business data, and maintaining uninterrupted access to critical desktops and applications. 

<!--JK: try the below as an alternative
Laying out requirements prior to implementing micro segmentation will provide a seamless implementation of security controls without interruption to business operations.
-->
Defining requirements before implementation of microsegementation <!--JK: microseg or security policies?--> helps to provide a seamless implementation of security controls without interruption to business operations.

<!--JK: have we already said this?-->
Typically Citrix delivery solutions can be broken down into individual components as described earlier in this guide. The most common (but not limited to) components for a Citrix delivery solution are:

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

<!--JK Would it add value here to include links to the above core services (AD etc) firewall requirements collateral? Enjoy those high end RPC ports-->

A good knowledge of networking requirements is critical before attempting to implement network segmentation <!--JK: need to align our wording to the above - you use microseg above--> as a misconfiguration could impact the operational ability and stability of your deployment.

<!--JK: I am not sure as to the value of the below statement. It's not considered but that's OK? If that's the case, its just superfluous words.-->
<note>
In a typical deployment windows firewall is commonly used to block inbound network traffic, however, little consideration is given to the outbound traffic. This is still a valid approach as a layered security posture is a desired approach in most situations.
</note>

Using Citrix Licensing as a component example, there are 3 elements required to properly secure it. <!--JK: I flipped the definition table and image placement around - it flows (again, i find myself amusing) better that way. Also took the liberty of adding an example column to your table and restructuring - cleaner-->

| Element | Description | Example |
| --- | --- | --- |
| Inbound | Networks, Services, Ports, and Protocols that require inbound communication to Citrix Licensing. | Citrix Delivery Controllers and TCP Port 27000 |
| Entity | The virtual machines servicing the element. | The Citrix Licensing server |
| Outbound | Networks, Services, Ports, and Protocols that require outbound communication from Citrix Licensing. | Domain Controllers for authentication |

The below image shows <!--JK: whatever you want it to say here-->

![Image showing Citrix Licensing as a component with inbound and outbound networking requirements](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image03.png "Image showing Citrix Licensing as a component with inbound and outbound networking requirements")

<!--JK: These images need some work - I'd love to see some nicer images in them, or if we can't do that, make the alignment of text etc look the same :)-->

Each component should be thoroughly documented prior to deploying microsegmentation to have the greatest chance of success when enforcing the security policy. <!--JK: Should this wording be combined with the above requirements not that you have?-->

A non-exhaustive example of Citrix Licensing security design tables are shown below.

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

<!--JK: You need to put a big fat note here calling out that this is an example only - or fatten this out a touch with the other requirements such as AV, management agents etc - just examples to get the brain thinking? You can even use Example: Global Catalog in the description. Maybe I am just being over cautious-->