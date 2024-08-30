# Example Configuration

![Image showing a high level Citrix Desktop and Application deployment for a Prism Central managed advanced networking platform](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image04.png "Image showing a high level Citrix Desktop and Application deployment for a Prism Central managed advanced networking platform")
<!--JK: Usual image comments - we can make these better-->

The above diagram shows the following. <!--JK: it doesn't really...it just outlines boxes with words, if we can't change it, maybe we should say that the diagram represents the following:-->

- Prism Central is deployed and operational.
- The Network Controller is running on Prism Central.
- Microsegmentation is enabled on Prism Central. <!--KL: image has a space between micro and segmentation-->
- VLAN 123 is defined as a VLAN backed advanced network within Prism Central.
- There is a Nutanix AHV Citrix Infrastructure cluster.
- There is a Citrix Virtual Desktop Agent cluster.
- There are security policies deployed within Prism Central to manage the network traffic to and from the VDAs.
- There are one or more security policies defined within Prism Central to manage the network traffic to and from the individual Citrix Infrastructure components.
- VLAN 123 defined in Prism Central is backed by the enterprise network on the same VLAN.

This configuration was used for functionality and performance validation of Nutanix Flow Network Security Next-Gen within a Citrix delivery solution running on Nutanix AHV. Application Policies were used to define and secure the network surrounding the individual Citrix components within the test environment.

<!--JK: does this warrant a heading?-->
## VDI Policy

Flow Network Security Next-Gen offers the ability to define a VDI Policy allowing security policies to be based on the users Active Directory group membership rather than a category. 

Further reading about the VDI Policy within Nutanix Flow Network Security Next-Gen can be found [here](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Network-Security-Guide-v4_0_0:fns-vdi-rule-configuration-c.html).