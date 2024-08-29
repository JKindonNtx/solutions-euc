# Example Configuration

![Image showing a high level Citrix Desktop and Application deployment for a Prism Central managed advanced networking platform](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image04.png "Image showing a high level Citrix Desktop and Application deployment for a Prism Central managed advanced networking platform")

The above diagram shows the following.

- Prism Central is deployed and operational.
- The Network Controller is running on Prism Central.
- Microsegmentation is enabled on Prism Central.
- VLAN 123 is defined as a VLAN backed advanced network within Prism Central.
- There is a Nutanix AHV Citrix Infrastructure cluster.
- There is a Citrix Virtual Desktop Agent cluster.
- There are security policies deployed within Prism Central to manage the network traffic to and from the VDAs.
- There are one or more security policies defined within Prism Central to manage the network traffic to and from the individual Citrix Infrastructure components.
- VLAN 123 defined in Prism Central is backed by the enterprise network on the same VLAN.

This Citrix Desktop and Application deployment configuration was used for functionality and performance validation of Nutanix Flow Network Security Next-Gen within a Citrix environment running on Nutanix AHV. Application Policies were used to define and secure the network surrounding the individual Citrix components within the test environment.

## VDI Policy

Flow Network Security Next-Gen offers the ability to define a VDI Policy allowing security policies to be based on the users Active Directory group membership rather than a category. 

Further reading about the VDI Policy within Nutanix Flow Network Security Next-Gen can be found [here](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Network-Security-Guide-v4_0_0:fns-vdi-rule-configuration-c.html).