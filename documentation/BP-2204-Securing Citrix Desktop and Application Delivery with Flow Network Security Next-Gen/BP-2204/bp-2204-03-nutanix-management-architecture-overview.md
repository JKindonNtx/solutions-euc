# Nutanix Management Architecture Overview

Nutanix delivers the simplicity and agility of public cloud alongside the performance, security, and control of private cloud. Whether on-premises or hybrid, build the exact cloud you want, with unified management and operations, one-click simplicity, intelligent automation, and always-on availability.

Management of a Nutanix platform can be performed with 2 different GUI interfaces:

Prism Element
: A web management platform used to manage, monitor and optimize a local Nutanix cluster. Provides built-in native high availability and the ability to perform management actions local to the cluster it runs on.

Prism Central
: A central web management platform used to manage, monitor, automate, secure, and optimize multiple Nutanix clusters. Provides a central management platform to effectively manage your entire Nutanix estate.

![Overview of the Nutanix Hybrid Multicloud Management Architecture showing 3 clusters with Prism Element and a overlay for Prism Central](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image02.png "Overview of the Nutanix Hybrid Multicloud Management Architecture showing 3 clusters with Prism Element and a overlay for Prism Central")
<!--JK: Any way we can make this images less dull? We have a good image library for icons etc - as a consumer it sort of feels like a quick hacked together square stencil lol!-->

## Nutanix Management With Flow Network Security Next-Gen

Understanding how to manage a Nutanix platform is critical in order to implement Nutanix Flow Network Security. <!-- Next-Gen?-->

Traditionally, virtual machine networks are defined locally to each cluster using Prism Element. When using Nutanix Flow Network Security Next-Gen <!--and microsegmentation--> is managed using Prism Central.

Once a network configuration is defined within Prism Central, it is delivered to the relevant Prism Element instance and is available for the virtual machines. Virtual machines attached to the managed network are secured with security policies.

Nutanix Flow Network Security Next-Gen is controlled by, a central [Flow Network Controller](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Virtual-Networking-Guide-vpc_2024_1:ear-flow-nw-vpc-concepts-pc-c.html). 

<!--JK: reworded some of the above-->