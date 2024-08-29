# Nutanix Management Architecture Overview

Nutanix delivers the simplicity and agility of public cloud alongside the performance, security, and control of private cloud. Whether on-premises or hybrid, build the exact cloud you want, with unified management and operations, one-click simplicity, intelligent automation, and always-on availability.

Management of a Nutanix platform can be performed with 2 different GUI interfaces:

Prism Element
: A web management platform used to manage, monitor and optimize a local Nutanix cluster. Provides built-in native high availability and the ability to perform management actions local to the cluster it runs on.

Prism Central
: A central web management platform used to manage, monitor, automate, secure, and optimize multiple Nutanix clusters. Provides a central management platform to effectively manage your entire Nutanix estate.

![Overview of the Nutanix Hybrid Multicloud Management Architecture showing 3 clusters with Prism Element and a overlay for Prism Central](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image02.png "Overview of the Nutanix Hybrid Multicloud Management Architecture showing 3 clusters with Prism Element and a overlay for Prism Central")

## Nutanix Management With Flow Network Security Next-Gen

Understanding how to manage a Nutanix platform is critical in order to implement Nutanix Flow Network Security.

Traditionally virtual machine networks would be defined locally to each cluster using Prism Element. When using Nutanix Flow Network Security this management function moves to Prism Central and is handed over to a central [Flow Network Controller](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Virtual-Networking-Guide-vpc_2024_1:ear-flow-nw-vpc-concepts-pc-c.html) (explained later in this guide). 

Once a network configuration is defined within Prism Central it is pushed down to the relevant Prism Element instance and is available as a managed network for the virtual machines on that cluster.

This is crucial as Nutanix Flow Network Security Next-Gen and microsegmentation is applied using Prism Central and therefore requires the management of every network and virtual machine being secured with policies.