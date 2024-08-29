# Citrix Desktop and Application Delivery Overview

Both Citrix Virtual Apps and Desktops and Citrix Desktop as a Service (DaaS) are desktop virtualization solutions that transform desktops and applications into secure, on-demand services available to any user, anywhere, on any device. With Citrix solutions, you can deliver individual Windows, web, and software as a service (SaaS) applications and even full virtual desktops to PCs, Macs, tablets, smartphones, laptops, and thin clients with a high-definition user experience.

Both solutions provides a complete virtual desktop and application delivery system by integrating several distributed components with advanced configuration tools that simplify the creation and real-time management of the virtual desktop infrastructure (VDI).

Both solutions deliver the same capability, with differing components and considerations: 

The following are the core components of a Citrix Delivery Solution.

Delivery Controller
: The Delivery Controller authenticates users, manages the assembly of users' virtual desktop environments, and brokers connections between users and their virtual desktops. It's installed on servers in the datacenter and controls the state of the desktops, starting and stopping them based on demand and administrative configuration. In some editions, the Citrix license needed to run Citrix Virtual Apps and Desktops also includes profile management to manage user personalization settings in virtualized or physical Windows environments. In a Citrix DaaS deployment, the Delivery Controller is hosted by Citrix.

Cloud Connector
: The Cloud Connector runs on servers in the datacenter and serves as a communication channel between Citrix DaaS and the datacenter. It enables authentication by allowing you to use Active Directory forests and domains, supports Citrix DaaS resource publishing, and facilitates machine catalog provisioning while removing the need to manage Citrix DaaS delivery infrastructure components such as Delivery Controllers, SQL Server, Director, StoreFront, Licensing, and Citrix Gateway. Cloud Connectors are only used in a Citrix DaaS deployment.

Studio
: Citrix Studio is the management console that allows you to configure and manage your Citrix environment. It provides different wizard-based deployment or configuration scenarios to publish resources using desktops or applications.

Web Studio
: Citrix Web Studio is the HTML 5 web management console that allows you to configure and manage your Citrix environment. It provides different wizard-based deployment or configuration scenarios to publish resources using desktops or applications.

Machine Creation Services (MCS)
: Machine Creation Services is the building mechanism of the Citrix Delivery Controller that automates and orchestrates desktop deployment using a single image. MCS communicates with the orchestration layer of your hypervisor, providing a robust and flexible method of image management.

Provisioning
: Citrix Provisioning creates and provisions virtual desktops from a single desktop image on demand, optimizing storage utilization and providing a pristine virtual desktop to each user every time they log on. Desktop provisioning also simplifies desktop images, provides optimal flexibility, and offers fewer points of desktop management for both applications and desktops.

Virtual Delivery Agent (VDA)
: The Virtual Delivery Agent is installed on virtual desktops and enables direct FlexCast Management Architecture (FMA) connections between the virtual desktop and user devices.

Workspace app
: The Citrix Workspace app, installed on user devices, enables direct HDX connections from user devices to applications and desktops using Citrix DaaS. The Citrix Workspace app allows access to published resources from your desktop, Start menu, web browser, or Citrix Workspace app.

FlexCast
: Citrix DaaS with FlexCast delivers virtual desktops and applications tailored to meet the diverse performance, security, and flexibility requirements of every worker in your organization. Centralized, single-instance management helps you deploy, manage, and secure user desktops more easily and efficiently.

StoreFront
: StoreFront is an enterprise app store that aggregates applications and desktops from Citrix Virtual Apps and Desktops sites and Citrix DaaS into a single store for users to access published resources.

Director
: Citrix Director is a HTML 5 web portal offering basic analytics for your Citrix environment including login times, session metrics, and application usage.

Licensing
: Citrix Licensing is a central web management console to issue, revoke, and manage licenses relevant to your Citrix environment..

Workspace Environment Management
: Citrix Workspace Environment Management (WEM) provides central user environment management providing the ability to apply policy, security measures, and optimizations to your users and VDAs.

Session Recording
: Citrix Session Recording provides the ability to record a users session activity to a central repository using policy or triggers.

NetScaler
: NetScaler provides application delivery and secure remote access for applications published by Citrix Virtual Apps and Desktops and Citrix DaaS. NetScaler provides both gateway capabilities for remote access, and load balancing capabilities for service resiliency.

For more detailed information about these components, as well as best practices for running them on Nutanix, see the following guides:

-  [Citrix Virtual Apps and Desktops on Nutanix best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2079-Citrix-Virtual-Apps-and-Desktops:BP-2079-Citrix-Virtual-Apps-and-Desktops).
-  [Citrix DaaS on Nutanix best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2062-Citrix-Virtual-Apps-and-Desktops-Service:BP-2062-Citrix-Virtual-Apps-and-Desktops-Service).