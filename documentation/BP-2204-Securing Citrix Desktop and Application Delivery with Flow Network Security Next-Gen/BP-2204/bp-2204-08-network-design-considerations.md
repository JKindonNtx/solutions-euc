# Network Design Considerations

Traditional Citrix delivery solutions running on Nutanix may use a basic VLAN network defined within Prism Element. This VLAN will be assigned to the virtual machines and network connectivity will traverse this connection.

When using Nutanix Flow Network Security Next-Gen there is a requirement to use Advanced Networking within Nutanix. Using advanced networking requires the implementation of a Network Controller on Prism Central. <!--JK I have read this before further up?-->

<!--JK: try the below instead?
Before implementing microsegmentation it is required that you define your networking requirements within Prism Central in order to apply security policies. This will consist of some or all of the following:
-->
Before implementing microsegmentation <!--just align the wording with whatever you decide from the previous comments--> security policies you must define your networking requirements within Prism Central. Some examples include:

- Configuring VLAN Backed Networks
- Configuring Virtual Private Clouds
- Configuring Overlay Networks
- Configuring Transient Virtual Private Clouds
- Configuring Routes
- Configuring Network Address Spaces

The following are 2 core components of an Advanced Network within Nutanix Prism Central.

<!--JK: these don't warrant headings, I split them into a list and reworded a touch
## Advanced VLAN Network

This is a network that is defined within Prism Central using advanced networking. This network will often operate in the same way that a basic network does in Prism Element with the exception of being managed via Prism Central and being accessible by the Flow Network Security Next-Gen policy engine.

## Virtual Private Cloud

A Virtual Private Cloud (VPC) is an independent and isolated IP address space that functions as a logically isolated virtual network. A VPC could be made up of one or more subnets that are connected through a logical or virtual router. The IP addresses within a VPC must be unique. However, IP addresses may overlap across VPCs. As VPCs are provisioned on top of another IP-based infrastructure (connecting AHV nodes), they are often referred to as the overlay networks.

The Citrix delivery solution in this guide was designed using a VLAN backed advanced network configuration.

For more information regarding advanced networking and its implementation please read the [Nutanix Flow Virtual Networking Guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Virtual-Networking-Guide-vpc_2024_1:ear-flow-nw-audience-and-purpose-c.html).
-->

Advanced VLAN Network
: A network that is defined within Prism Central using advanced networking. This network will operate in the same way that a basic network does in Prism Element but is managed by Prism Central and accessible to the Flow Network Security Next-Gen policy engine.

Virtual Private Cloud
: A Virtual Private Cloud (VPC) is an independent and isolated IP address space that functions as a logically isolated virtual network. A VPC could be made up of one or more subnets that are connected through a logical or virtual router. The IP addresses within a VPC must be unique. However, IP addresses may overlap across VPCs. As VPCs are provisioned on top of another IP-based infrastructure (connecting AHV nodes), they are often referred to as the overlay networks.
: The Citrix delivery solution in this guide was designed using a VLAN backed advanced network configuration. <!--JK: because....what about MCS integration, do we need to talk to the plugin architecture here?-->

For more information regarding advanced networking and its implementation please read the [Nutanix Flow Virtual Networking Guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Virtual-Networking-Guide-vpc_2024_1:ear-flow-nw-audience-and-purpose-c.html).