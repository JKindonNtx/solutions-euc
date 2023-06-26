# Citrix Virtual Apps and Desktops Overview

Citrix Virtual Apps and Desktops is a desktop virtualization solution that transforms desktops and applications into secure, on-demand services available to any user, anywhere, on any device. With Citrix Virtual Apps and Desktops, you can deliver individual Windows, web, and SaaS applications, and even full virtual desktops to PCs, Macs, tablets, smartphones, laptops, and thin clients with a high-definition user experience.

Citrix Virtual Apps and Desktops provides a complete virtual desktop and application delivery system by integrating several distributed components with advanced configuration tools that simplify the creation and real-time management of the virtual desktop infrastructure (VDI).

The following are the core components of Citrix Virtual Apps and Desktops. For more detailed information about these components, as well as best practices for running them on Nutanix, see the [Citrix Virtual Apps and Desktops on Nutanix best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2079-Citrix-Virtual-Apps-and-Desktops:BP-2079-Citrix-Virtual-Apps-and-Desktops).

Delivery Controller
: The Delivery Controller authenticates users, manages the assembly of users’ virtual desktop environments, and brokers connections between users and their virtual desktops. It's installed on servers in the datacenter and controls the state of the desktops, starting and stopping them based on demand and administrative configuration. In some editions, the Citrix license needed to run Citrix Virtual Apps and Desktops includes profile management to manage user personalization settings in virtualized or physical Windows environments.

Studio
: Citrix Studio is the management console where you configure and manage your Citrix Virtual Apps and Desktops environment. It provides different wizard-based deployment or configuration scenarios to publish resources using desktops or applications.

Machine Creation Services (MCS)
: Machine Creation Services is the building mechanism of the Citrix Delivery Controller that automates and orchestrates desktop deployment using a single image. MCS communicates with the orchestration layer of your hypervisor, providing a robust and flexible method of image management.

Provisioning
: Citrix Provisioning creates and provisions virtual desktops from a single desktop image on demand, optimizing storage utilization and providing a pristine virtual desktop to each user every time they log on. Desktop provisioning also simplifies desktop images, provides optimal flexibility, and offers fewer points of desktop management for both applications and desktops.

Virtual Delivery Agent (VDA)
: The Virtual Delivery Agent is installed on virtual desktops and enables direct FMA (FlexCast Management Architecture) connections between the virtual desktop and user devices.

Workspace app
: The Citrix Workspace app, installed on user devices, enables direct HDX connections from user devices to applications and desktops using Citrix Virtual Apps and Desktops. The Citrix Workspace app allows access to published resources from your desktop, Start menu, web browser, or Citrix Workspace app user interface.

FlexCast
: Citrix Virtual Apps and Desktops with FlexCast delivers virtual desktops and applications tailored to meet the diverse performance, security, and flexibility requirements of every worker in your organization. Centralized, single-instance management helps you deploy, manage, and secure user desktops easily and efficiently.
