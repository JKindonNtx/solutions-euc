# Network Design for a Secure Citrix Desktop and Application Delivery Solution

Traditional Citrix platforms running on Nutanix may use a VLAN network defined within Prism Element. This VLAN will be assigned to the virtual machines and network connectivity will traverse this connection.

When using Flow Network Security Next-Gen there is a requirement to use Advanced Networking within Nutanix. Using advanced networking requires the implementation of a Network Controller on Prism Central. 

Details of enabling the Network Controller in Prism Central can be found [in this guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Virtual-Networking-Guide-vpc_2024_1:Nutanix-Flow-Virtual-Networking-Guide-vpc_2024_1).

Consider the following implementation of networking within a Citrix platform.

![Image showing a typical network deployment for a citrix platform with a single vlan reaching the main enterprise network](../images/BP-XXXX-Securing_Citrix_Virtual_Apps_and_Desktops_with_Flow_Network_Security_NextGen_image03.png "Image showing a typical network deployment for a citrix platform with a single vlan reaching the main enterprise network")

All the Citrix Infrastructure and Virtual Delivery Agents are talking to the main enterprise network over VLAN 123. This VLAN is defines within Prism Element and assigned to the virtual machines on deployment.

Before implementing microsegmentation it is paramount that you define your networking requirements within Prism Central in order to apply security policies. 

You have 2 options for defining your networks based on your existing business requirements.

- VLAN Backed Network
- Virtual Private Cloud

## VLAN Backed Network

This is a network that is defined within Prism Central but uses advanced networking. This network will often operate in the same way that a basic network does in Prism Element with the exception of being managed via Prism Central and being accessible by the Flow Network Security policy engine.

## Virtual Private Cloud

A Virtual Private Cloud (VPC) is an independent and isolated IP address space that functions as a logically isolated virtual network. A VPC could be made up of one or more subnets that are connected through a logical or virtual router. The IP addresses within a VPC must be unique. However, IP addresses may overlap across VPCs. As VPCs are provisioned on top of another IP-based infrastructure (connecting AHV nodes), they are often referred to as the overlay networks. Tenants may spin up VMs and connect them to one or more subnets within a VPC.

*Note*: Whilst you can run a Citrix platform within a VPC it requires some reconfiguration of the infrastructure components in order to operate as expected. In this guide we show the process for using Flow Network Security Next-Gen using advanced networking VLAN backed networks.

For more information regarding advanced networking and its implementation please read the [Flow Virtual Networking Guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Virtual-Networking-Guide-vpc_2024_1:ear-flow-nw-audience-and-purpose-c.html).