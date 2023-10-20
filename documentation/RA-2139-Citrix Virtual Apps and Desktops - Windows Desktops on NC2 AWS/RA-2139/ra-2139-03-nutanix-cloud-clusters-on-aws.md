# Nutanix Cloud Clusters on AWS 

## Overview

NC2 on AWS situates the complete Nutanix hyperconverged infrastructure (HCI) stack directly on an Amazon Elastic Compute Cloud (EC2) bare-metal instance. This bare-metal instance runs a Controller VM (CVM) and AHV just like any on-premises Nutanix deployment, using the AWS elastic network interface (ENI) to connect to the network. 

AHV user VMs don’t require any additional configuration to access AWS services or other EC2 instances.

AHV runs an efficient embedded distributed network controller that integrates user VM networking with AWS networking. AHV assigns all user VM IP addresses to the bare-metal host where the VMs run. Instead of creating an overlay network, the AHV embedded network controller provides the networking information of the VMs running on NC2 in AWS, even as a VM moves around the AHV hosts. Because NC2 on AWS integrates IP address management with AWS Virtual Private Cloud (VPC), AWS allocates all user VM IP addresses from the AWS subnets in the existing VPCs.

## Nutanix Cloud Networking

Nutanix can deliver a true hybrid multicloud experience because it has native cloud networking. Nutanix's integration with the AWS networking stack means that every VM deployed on NC2 in AWS gets a native AWS IP address, so as soon as you migrate an application to or create an application on NC2 in AWS, it has full access to all AWS resources. Integration also removes the burden of managing and deploying an additional network overlay. Because the Nutanix network capabilities are directly on top of the AWS overlay, network performance remains high and additional network controllers don’t consume host resources.

With native network integration, you can deploy NC2 on AWS in existing AWS VPCs. Because existing AWS environments have gone through change control and security processes already, you don’t need to do anything except allow NC2 on AWS to talk to the NC2 management console. We believe that this integration enables you to increase security in your cloud environments.

Nutanix uses native AWS API calls to deploy AOS on bare-metal EC2 instances and consume network resources. Each bare-metal EC2 instance has full access to its bandwidth through an ENI. For example, if you deploy Nutanix to an i4i.metal instance, each instance has access to 25 Gbps. With AHV, the ENI ensures that you don’t need to set up additional networking high availability for redundant network paths to the top-of-rack switch. 

AHV uses Open vSwitch (OVS) for all VM networking. You can configure VM networking through Prism or the aCLI, and each vNIC connects to a tap interface. 

To learn more about Nutanix cloud networking, including information on how to create a subnet in AWS and how AHV IP address management works, read the Nutanix Cloud Clusters on AWS tech note.
