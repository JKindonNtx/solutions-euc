# Nutanix Cloud Platform Overview

Nutanix delivers a web-scale, hyperconverged infrastructure (HCI) solution purpose-built for virtualization and both containerized and private cloud environments. This solution brings the scale, resilience, and economic benefits of web-scale architecture to the enterprise through the Nutanix Cloud Platform, which combines the core HCI product families (Nutanix AOS and Nutanix Prism Management) along with other software products that automate, secure, and back up cost-optimized infrastructure.

Available attributes of the Nutanix Cloud Platform stack include:

- Optimized for storage and compute resources.
- Machine learning to plan for and adapt to changing conditions automatically.
- Intrinsic security features and functions for data protection and cyberthreat defense.
- Self-healing to tolerate and adjust to component failures.
- API-based automation and rich analytics.
- Simplified one-click upgrades and software life cycle management.
- Native file services for user and application data.
- Native disaster recovery solutions.
- Powerful and feature-rich virtualization. 
- Flexible virtual networking for visualization, automation, and security.
- Cloud automation and life cycle management.
  
Nutanix provides services and can be broken down into three main components: 
- A HCI-based distributed storage fabric. 
- Management and operational intelligence from Prism. 
- AHV virtualization. 
 
Nutanix Prism offers administrators one-click infrastructure management for virtual environments running on AOS. AOS is hypervisor agnostic, supporting two third-party hypervisors (VMware ESXi and Microsoft Hyper-V) in addition to the native Nutanix hypervisor, AHV.
 
![Nutanix Cloud Platform](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image01.png "Nutanix Cloud Platform")

## Nutanix HCI Architecture

Nutanix does not rely on traditional SAN or network-attached storage (NAS) or expensive storage network interconnects. It combines highly dense storage and server compute (CPU and RAM) into a single platform building block. Each building block delivers a unified, scale-out, shared-nothing architecture with no single points of failure.

The Nutanix solution requires no SAN constructs, such as LUNs, RAID groups, or expensive storage switches. All storage management is VM-centric, and I/O is optimized at the VM virtual disk level. The software solution runs on nodes from a variety of manufacturers that are either entirely solid-state storage with NVMe for optimal performance or all-SSD storage that provides a combination of performance and additional capacity. The storage fabric automatically tiers data across the cluster to different classes of storage devices using intelligent data placement algorithms. For best performance, algorithms make sure the most frequently used data is available in memory or in flash on the node local to the VM. 

To learn more about the Nutanix Cloud Platform, visit the [Nutanix Bible](https://www.nutanixbible.com) and [Nutanix.com](https://www.nutanix.com/products/cloud-platform). 

