# Nutanix Flow Network Security Next-Gen Overview

Nutanix Flow Network Security Next-Gen is the next-generation Nutanix microsegmentation solution with an enhanced policy model, advanced policy operation, and enterprise readiness features (v4 APIs, RBAC, and improved scale performance and resiliency). 

Implementing Flow Network Security Next-Gen offers the ability to monitor and control network traffic to and from your critical Citrix Desktop and Application delivery solution.

The following are the core concepts and terminology definitions for a Nutanix Flow Network Security Next-Gen implementation.

Microsegmentation
: The process of breaking down a network into smaller segments to make it more difficult for an attacker to access a whole system. Each segment acts as its own barrier: If an attacker broke into a system, the intruder would only be able to get to a single segment first, rather than the entire system.

Security Policy Model
: A schema of policies for specifying and enforcing a desired behavior. A Policy Model will have one or more policies.

Security Policy
: Defines how to protect assets from threats and how to handle situations when they do occur. Security policy is a collection of security rules and assets [entities, endpoints, categories, applications] on which the rules have to be enforced together.

Category
: Nutanix construct for the well known concept of Tags, are used to define groups of entities which policies and enforcement are applied to. They typically apply, but are not limited to: environment, application type, application tier, etc. Category: Key/Value "Tag". Examples: app | tier | group | location | subnet | etc. These categories are leveraged by policies to determine what rules / actions to apply.

Category Set
: A collection of Categories which are evaluated with an **AND** operation to resolve to a set of VMs where all categories in the Category Set are assigned.

Entity
: Nutanix entity is one or more instances of an object type such as a VM, cluster, security policy, project, or report. For the scope of Flow, we shall refer ‘Entity’ for end-points of traffic which can be a source or target of a protected entity:

: Source Entity: The entity from where the inbound traffic to a Secured Entity is to be controlled by a Flow policy

: Secured Entity: The entity which is being protected by the Flow policy

: Destination Entity: The entity to which the outbound traffic from the Secured Entity needs to be controlled.

Zero Trust
: A security concept centered on the belief that organizations should not automatically trust anything inside or outside its perimeters and instead must verify anything and everything trying to connect to its systems before granting access.

Blacklist
: Automatically approves everything. The user has to explicitly define what should be rejected.

Allowlist [least privilege model]
: Automatically denies everything. The user has to explicitly define what is allowed.

For more detailed information about these components, as well as best practices for installing and running them on Nutanix, see the following guides:

-  [Nutanix Flow Network Security Next-Gen](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Network-Security-Guide-v4_0_0:fns-flow-2-introduction-c.html).