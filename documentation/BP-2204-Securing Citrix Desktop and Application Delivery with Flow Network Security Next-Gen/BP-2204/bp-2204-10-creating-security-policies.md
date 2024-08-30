# Creating Security Policies

Full details on the mechanics of creating a Flow Network Security Next-Gen Application Policies can be found in the [Nutanix Flow Network Security Guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Network-Security-Guide-v4_0_0:fns-security-policy-configuration-c.html). This guide will detail key concepts and steps required to create and apply security policies needed to secure your Citrix delivery solution.

## Categories

Catagories <!--JK: I love a good catagory as much as the next guy, prefer a category though. Find myself amusing --> must be assigned to the virtual machines (entities) that require securing. In a typical Citrix delivery solution, these can easily be broken down into logical groups for the various components. 

A single category can have multiple values assigned, this makes designing categories straight forward. An example is shown below. <!--JK: can these be displayed in table format? Would be cleaner-->

### Citrix Infrastructure

- Citrix Infrastructure
  - Cloud Connectors
  - Controllers
  - FAS
  - Licensing
  - PVS
  - Session Recording
  - SQL
  - StoreFront
  - WEM

### Citrix Virtual Delivery Agents

- Citrix VDA
  - General
  - Secure


<!--JK: So, far my understanding is we aren't doing anything based on VDI policies in these examples, it makes me think the below points is superflous?-->
<note>
The VDI Policy in Flow Network Security Next-Gen allows security policies to be assigned based on a users Active Directory group. As Application Policies were used for this testing we can group VDAs with a similar function and secure them based on that group. The example above shows General and Secure VDA groups.
</note>

Ensure the applicable category is assigned to the relevant virtual machine prior to designing your policies. 

<!--JK: This is talking to a negative, I would reword this entire piece to just say something like the below:
Assigning categories to virtual machines is a manual process that is undertaken via the Prism Central GUI. This is problematic with the Citrix Desktop and Application deployment methods MCS or PVS as these virtual machines are fluid and can be scaled up or down depending on the IT administrators needs. To tackle this Nutanix Playbooks can be used to identity a new virtual machine at build and assign the relevant category based on any number of criteria. Details of this process can be found in the Appendix.
-->
Nutanix Playbooks can be used to identity new virtual machines at build or provisioning stage, to then assign the relevant category based on any number of criteria. Details of this process can be found in the Appendix. <!--JK: placeholder comment, maybe we can talk to other automation options too-->

## Addresses

Addresses can be defined as known network ranges (specific or a CIDR block) that entities will communicate with either inbound or outbound. Flow Network Security Next-Gen allows you to create these known networks outside of the security policy allowing easy manipulation of the address space should it change.

Create recognizable addresses for known networks that the Citrix components will communicate with. Example address definitions can be found in the table below.

_Table: Creating Security Policies: Addresses_

| Name | Description | Subnet Details |
| --- | --- | --- |
| Domain Services | Domain Controllers | 10.20.30.1-4 |
| VLAN 123 | Citrix VLAN - Infrastructure | 10.20.40.0/24 |
| VLAN 124 | General VDA Network | 10.20.50.0/24 |
| VLAN 125 | Secure VDA Network | 10.20.60.0/24 |

## Services

Managing the various ports and protocols required to operate can fast become overwhelming and confusing. These various ports and protocols can be grouped together in a logical unit called a Service within Flow Network Security Next-Gen.

Create easy to identify services for each Citrix component. Example service definitions can be found in the table below. <!--JK: I just wonder if we should stick with the licensing component as a consistent example-->

_Table: Creating Security Policies: Services_

| Service Name | Protocol | Port |
| --- | --- | --- |
| Citrix WEM | TCP | 8284 |
| Citrix WEM | TCP | 8285 |
| Citrix WEM | TCP | 8286 |
| Citrix WEM | TCP | 8287 |
| Citrix WEM | TCP | 8288 |

## Application Policies

Application Policies are created for each component and the relevant inbound and outbound rules applied. Refer to the Security Design tables you created in order to correctly apply the inbound and outbound entities, addresses, and services allowed to communicate with the component.

Create an Application Security Policy for each component defined earlier. When creating the policy be sure to select "**Secure Entities**", "**Generic Policy**", "**VLAN Subnets**" and enable "**Policy Hit Logs**".

An example Application Security Policy can be seen below.

![Image showing a high level security policy for a prism central managed advanced networking platform](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image05.png "Image showing a high level security policy for a prism central managed advanced networking platform")

![Image showing a high level traffic policy for a prism central managed advanced networking platform](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image06.png "Image showing a high level traffic policy for a prism central managed advanced networking platform")

<!--JK: happy reader seeing non block images :) 5 bucks says that get pulled out-->

Save the policy and put it in "**Monitor Mode**". <!--JK: We need to be consistent on when we bold these bits and bobs, in some places we do, in others we don't-->

### Monitor Mode

Monitor mode is a valuable tool within Flow Network Security Next-Gen that will allow testing of security policies before enforcing them and blocking un-configured traffic. 

When a policy is in monitor mode it will not actively block traffic inbound or outbound from the secured entity, it will, however, log this and show it in the console. This gives the ability to edit and update the application security policy rules prior to enforcing them and blocking traffic, giving a greater confidence that the application security policy will not interrupt operations.

![Image showing a high level traffic policy for a prism central managed advanced networking platform in monitor mode](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image07.png "Image showing a high level traffic policy for a prism central managed advanced networking platform in monitor mode")

### Enforce Mode

Enable enforce mode to apply the application security policy and start to active block un-defined traffic inbound and outbound.

<note>
Be sure to validate all un-defined traffic in monitor mode before moving the application security policy to enforce mode to minimize disruption.
</note>

![Image showing a high level traffic policy for a prism central managed advanced networking platform in enforce mode](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image08.png "Image showing a high level traffic policy for a prism central managed advanced networking platform in enforce mode")

## Isolation Policy

Isolation Policies identify two groups of virtual machines by category, and blocks communications between the groups.

In the case of a Citrix delivery solution, you may wish to isolate the general purpose VDAs from communicating with the Secure VDAs. This ensures that the Secure VDAs remain isolated and cannot be laterally accessed should an attacker breach a general purpose VDA.

Isolation Policies can be put into Monitor Mode initially to ensure that no desired traffic is being sent between the virtual machine groups prior to enforcement of the policy.

![Example Isolation Policy between General and Secure VDAs](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image09.png "Example Isolation Policy between General and Secure VDAs")

## Quarantine Policy

Prism Central <!--JK:PC or Flow?--> has system-defined quarantine policies that enable you to perform the following tasks:

- Completely isolate an infected VM that must not have any traffic associated with it.
- Isolate an infected VM but specify a set of forensic tools that can communicate with the VM.

The system-defined quarantine policies are created for All VLANs and VPCs. The system-defined VLAN specific quarantine policies are:

- Quarantine Forensic Policy - VLAN Subnets 
- Quarantine Strict Policy - VLAN Subnets 

<note>
You cannot create or delete a quarantine policy. However, you can modify existing (system-defined) quarantine policy.
</note>

You are able to update your Quarantine policies to allow inbound tools to communicate with the virtual machine in the event of an attack then quarantine a virtual machine from Prism Central.

![Example Quarantine Policy](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image10.png "Example Quarantine Policy")

## Example Citrix Policy Set

<!--JK: this needs a small description I think-->

![Example Citrix Policy](../images/BP-2204-Securing_Citrix_Desktop_And_Application_Delivery_With_Flow_Network_Security_Next-Gen_image11.png "Example Citrix Policy")