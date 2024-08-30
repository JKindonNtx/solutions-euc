# Nutanix Flow Network Security Next-Gen Overview

Nutanix Flow Network Security Next-Gen is the next-generation Nutanix microsegmentation solution with an enhanced policy model, advanced policy operation, and enterprise readiness features (v4 APIs, RBAC, and improved scale performance and resiliency). 

Implementing Flow Network Security Next-Gen delivers the ability to monitor and control network traffic to and from your critical Citrix delivery solution.

The following are the core concepts and terminology definitions for a Nutanix Flow Network Security Next-Gen implementation.
<!--JK: I know some of these comes from the flow document, but i am commenting anyway, coz maybe the flow doco can get some updates too - or you can just ignore my rantings :)-->
Microsegmentation
: The process of breaking down a network into smaller segments to make it more difficult for an attacker to access a whole system. Each segment acts as its own barrier: If an attacker broke into a system, the intruder would only be able to get to a single segment first, rather than the entire system.

Security Policy Model
: A schema of policies for specifying and enforcing a desired behavior. A Policy Model will have one or more policies.

Security Policy
: Defines how to protect assets from threats and how to handle situations when they do occur. Security policy is a collection of security rules and assets [entities, endpoints, categories, applications] on which the rules have to be enforced together.
<!--JK: does security policy need a capital P?-->

Category
: The Nutanix construct for the well known concept of Tags <!--JK: I am not sure about this, we define a Category, others use tags, do we care about others?-->, are used to define groups of entities which <!--JK: ssecurity?-->policies and enforcement <!--JK: do we need to say enforcement of just policy?--> are applied to. They typically apply, but are not limited to: environment, application type, application tier, etc. Category: Key/Value "Tag". Examples: app | tier | group | location | subnet | etc. These categories are leveraged by policies to determine what rules / actions to apply. <!--JK: I find this entire bullet kind of confusing, think it can be reworked to simplify (don't cross Tag/Category etc-->

Category Set
: A collection of Categories which are evaluated with an **AND** operation <!--KL: this would be an operator?--> to resolve to a set of VMs where all categories in the Category Set are assigned. <!--JK: placeholder comment here, I think putting your operator descriptor here is too much - just define a category set definition, and specify how they work later on-->

Entity
<!--JL: I couldn't get my mouth around this one, had an attempt in cleaning it up below
: A Nutanix entity is one or more instances of an object type such as a VM, cluster, security policy, project, or report. For the scope of Flow, we refer to 'Entity' as an end-point for traffic. This end-point may be either a source, or target for a protected item:
-->
: A Nutanix entity entity refers to one or more instances of various object types, such as a VM, cluster, security policy, project, or report. Within the context of Flow <!--Next-Gen?-->, 'Entity' specifically denotes an endpoint for traffic, which can either be a source or a target for a protected item:

: Source Entity: The entity from where the inbound traffic to a Secured Entity is to be controlled by a <!--JK: Security?-->Flow policy <!--JK: watch for capitals, we have E and e in entity? It might be correct but checking>

: Secured Entity: The entity which is being protected by the Flow <!--JK: Security?--> policy <!--JK: This should be your first item as it will flow (hahah) better-->

: Destination Entity: The entity to which the outbound traffic from the Secured Entity needs to be controlled. <!--JK: watch for capitals, we have E and e in entity? It might be correct but checking>

Zero Trust
<!--JK: Try the below
: A security concept centered on the belief that organizations should not automatically trust anything inside or outside its perimeters and instead must verify anything and everything trying to connect to its systems before granting access.
-->
: A security concept based on the principle that organizations should not automatically trust any entity, whether inside or outside their perimeters. Instead, they must verify every attempt to connect to their systems before granting access

Blacklist
: Automatically approves everything. The user has to explicitly define what should be rejected. <!--JK: Is this correct? it reads backwards to my brain - a blacklist allows everything, and a whitelist blocks everything? Do we mean to say by default it approves all traffic until populated?-->

Allowlist [least privilege model]
: Automatically denies everything. The user has to explicitly define what is allowed.

For more detailed information about these components, as well as best practices for installing and running them on Nutanix, see the following guides: <!--JK: There is only one guide here, maybe inline the link and remove the plural-->

-  [Nutanix Flow Network Security Next-Gen](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Network-Security-Guide-v4_0_0:fns-flow-2-introduction-c.html).