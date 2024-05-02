# Citrix Virtual Apps and Desktops Overview

Citrix Virtual Apps and Desktops (Citrix VAD) is a desktop virtualization solution that transforms desktops and applications into secure, on-demand services available to any user, anywhere, on any device. With Virtual Apps and Desktops, you can deliver individual Windows, web, and SaaS applications, and even full virtual desktops to PCs, Macs, tablets, smartphones, laptops, and thin clients with a high-definition user experience.

Citrix Virtual Apps and Desktops provides a complete virtual desktop and application delivery system by integrating several distributed components with advanced configuration tools that simplify the creation and real-time management of the virtual desktop infrastructure.

The following are the core components of Virtual Apps and Desktops. For more detailed information about these components, as well as best practices for running them on Nutanix, see the [Citrix Virtual Apps and Desktops on Nutanix best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2079-Citrix-Virtual-Apps-and-Desktops:BP-2079-Citrix-Virtual-Apps-and-Desktops).

Delivery Controller
: The controller is installed on servers in the datacenter and authenticates users, manages the assembly of users' virtual desktop environments, and brokers connections between users and their virtual desktops. It controls the state of the desktops, starting and stopping them based on demand and administrative configuration. In some editions, the Citrix license needed to run Virtual Apps and Desktops also includes profile management to manage user personalization settings in virtualized or physical Windows environments.

Studio
: Citrix Studio is the management console that allows you to configure and manage your Citrix VAD environment. It provides different wizard-based deployment or configuration scenarios to publish resources using desktops or applications.

Machine Creation Services (MCS)
: Machine Creation Services is the building mechanism of the Citrix Delivery Controller that automates and orchestrates desktop deployment using a single image. MCS communicates with the orchestration layer of your hypervisor, providing a robust and flexible method of image management.

Provisioning (PVS)
: Citrix Provisioning creates and provisions virtual desktops from a single desktop image on demand, optimizing storage utilization and providing a pristine virtual desktop to each user every time they log on. Desktop provisioning also simplifies desktop images, provides optimal flexibility, and offers fewer points of desktop management for both applications and desktops.

Virtual Delivery Agent (VDA)
: The Virtual Delivery Agent is installed on virtual desktops and enables direct FMA (FlexCast Management Architecture) connections between the virtual desktop and user devices.

Workspace app
: The Citrix Workspace app, installed on user devices, enables direct HDX connections from user devices to applications and desktops using Citrix VAD. The Citrix Workspace app allows access to published resources from your desktop, Start menu, web browser, or Citrix Workspace app user interface.

FlexCast
: Citrix VAD with FlexCast delivery technology lets you deliver virtual desktops and applications tailored to meet the diverse performance, security, and flexibility requirements of every worker in your organization through a single solution. Centralized, single-instance management helps you deploy, manage, and secure user desktops more easily and efficiently.

## Provisioning Software Development Kit

The Citrix Provisioning Software Development Kit (SDK) applies the power and flexibility of Citrix-provisioned VMs to any hypervisor or cloud infrastructure service you choose.

The SDK enables you to create your own Provisioning plug-in, which you can add to the plug-ins installed by default by the Citrix installer. Once you install your plug-in, the Delivery Controller services discover and load it automatically. It then appears as a new connection type in Citrix Studio or Citrix Web Studio, allowing you to easily connect, configure, and provision on your chosen infrastructure platform using two key features:

- A set of .NET programming interfaces used to call your Provisioning plugin whenever it needs to act. Your plugin takes the form of a .NET assembly (DLL) that implements these interfaces. A plugin must implement several .NET interfaces, but each is designed to be small and easy to understand. Most interfaces have both a synchronous and an asynchronous variant, allowing you to choose the programming pattern that works best.
- The Citrix Common Capability Framework, which lets the rest of the product understand the specific custom features of your infrastructure and how you want those features displayed in Citrix Studio. The framework uses a high-level XML-based description language. Your plugin uses this language to produce specifications that allow Citrix Studio to intelligently adapt its task flows and wizard pages.

The plug-in made with the Citrix Provisioning SDK allows you to create the connection between Citrix Studio and AHV and gives you access to all the APIs offered through AHV. However, before you can use it, you need to install the Nutanix AHV plug-in for Citrix on Delivery Controllers. For more information, see [AHV Plug-in for Citrix](https://portal.nutanix.com/page/documents/details?targetId=NTNX-AHV-Plugin-Citrix:NTNX-AHV-Plugin-Citrix) (Nutanix portal credentials required).
