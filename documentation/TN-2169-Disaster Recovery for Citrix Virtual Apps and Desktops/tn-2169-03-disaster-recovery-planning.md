# Disaster Recovery Planning

## Nutanix Disaster Recovery Terminology

Nutanix recommends gaining familiarity with the following terms and concepts before you begin configuring protection with Nutanix Disaster Recovery or Nutanix Disaster Recovery as a Service (DRaaS).

Availability zone (AZ)
: A zone that can have one or more independent datacenters interconnected by low-latency links. An AZ can be at your physical location (on-premises), in Nutanix Cloud Clusters (NC2), or in Nutanix Cloud Services. AZs are physically isolated from each other to ensure that a disaster at one AZ doesn't affect another AZ. An instance of Prism Central represents an on-premises AZ.

On-premises AZ
: An AZ at your physical location.

Nutanix Cloud Services
: An AZ in a Nutanix datacenter.

Primary AZ
: The AZ that initially hosts guest VMs you want to protect.

Recovery AZ
: An AZ where you can recover the protected guest VMs when an event causes downtime at the primary AZ. You can configure up to two recovery AZs for a guest VM.

Nutanix cluster
: A cluster running AHV or ESXi nodes in an on-premises AZ, Nutanix Cloud Services, or any supported public cloud via NC2. Nutanix Disaster Recovery doesn't support guest VMs from Hyper-V clusters.

NC2 
: NC2 extends on-premises environments to the cloud. NC2 consumes bare-metal infrastructure on public cloud platforms.

Prism Element
: A service built into the platform for every Nutanix cluster deployed. With Prism Element, you can configure, manage, and monitor a single Nutanix cluster.

Prism Central
: Prism Central manages different clusters across separate physical locations on one screen and offers an organizational view into a distributed Nutanix environment.

Virtual Private Cloud (VPC)
: A logically isolated network service in Nutanix Cloud Services. A VPC provides the complete IP address space for hosting user-configured VPNs. With a VPC, you can create workloads manually or by failover from a paired primary AZ.

Source virtual network
: The virtual network from which guest VMs migrate during a failover or failback operation.

Recovery virtual network
: The virtual network to which guest VMs migrate during a failover or failback operation.

Network mapping
: A visualization of two virtual networks in paired AZs. A network map specifies a recovery network for all guest VMs on the source network. When you perform a failover or failback operation, the guest VMs in the source network recover in the corresponding (mapped) recovery network.

VM category
: A key-value pair that groups similar guest VMs. Associating a protection policy with a VM category ensures that the protection policy applies to all the guest VMs in the group regardless of how the group scales over time.

Recovery point
: A copy of the state of a system at a particular point in time.

Recoverable entity
: A guest VM that you can restore from a recovery point.

Protection policy
: A configurable policy that takes recovery points of the protected guest VMs at equal time intervals and replicates them to the recovery AZs.

Recovery plan
: A configurable policy that orchestrates restoring protected guest VMs at the recovery AZ.

Recovery point objective (RPO)
: The maximum acceptable amount of time elapsed since the last data recovery point.

Recovery time objective (RTO)
: The maximum acceptable amount of time elapsed between the failure event and restored service.

Refer to the Nutanix Disaster Recovery Terminology section of the [Nutanix Disaster Recovery Guide](https://portal.nutanix.com/page/documents/details?targetId=Leap-Xi-Leap-Admin-Guide:Leap-Xi-Leap-Admin-Guide) for more information.

## Disaster Recovery Considerations

Nutanix has built-in data protection at the cluster level as well as Nutanix Disaster Recovery (previously Leap; a disaster recovery orchestration service) integrated with Nutanix Prism. We recommend that you choose the disaster recovery method you're more familiar with: 

- Protection domains with native data protection 
- Protection policies and recovery plans with Nutanix Disaster Recovery

### Native Data Protection

Native data protection uses protection domains to back up VMs. A protection domain is a defined group of entities (VMs and volume groups) at the cluster level that you can snapshot and replicate to at least one remote site. Each remote site is a Nutanix cluster, either on-premises or in the cloud. You can use protection domains with asynchronous and NearSync replication.

![Native Data Protection: Per-VM Replication at the Cluster Level](../images/native-data-protection-per-vm-replication-at-the-cluster-level.png "Native Data Protection: Per-VM Replication at the Cluster Level")

Refer to the [Data Protection and Disaster Recovery best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2005-Data-Protection:BP-2005-Data-Protection) and [tech note](https://portal.nutanix.com/page/documents/solutions/details?targetId=TN-2027-Data-Protection-and-Disaster-Recovery:TN-2027-Data-Protection-and-Disaster-Recovery) for more detailed information.

### Nutanix Disaster Recovery

Nutanix Prism provides a single web console for monitoring and managing multiple clusters. With Nutanix Disaster Recovery, which orchestrates operations around migrations and unplanned failures, Prism also includes protection policies and recovery plans to protect data for AHV and ESXi. You can apply orchestration policies from a central location, ensuring consistency across all your sites and clusters.

Prism uses AZs to manage these protection policies and recovery plans. Nutanix defines an AZ as a logical management boundary for all the clusters that one Prism Central instance manages, regardless of whether those clusters are deployed in the cloud or on-premises.

![Primary and Recovery Nutanix Clusters at Different On-Premises AZs](../images/primary-and-recovery-nutanix-clusters-at-different-on-prem-azs.png "Primary and Recovery Nutanix Clusters at Different On-Premises AZs")

To use Nutanix Disaster Recovery to protect data between two different Prism Central instances, pair one Prism Central instance with the remote AZ (or Prism Central instance) you want to fail over to. Once the two instances are paired, all the associated categories you used to apply the protection policies to your VMs, the protection policies themselves, and the recovery plans sync between them. In the event of a site failure, you still have access to the recovery plan to orchestrate the failover.

#### Protection Policies

A protection policy automates the creation and replication of snapshots across all the clusters managed by Prism Central. When you configure a protection policy for creating local snapshots, specify the RPO, retention policy, and the entities you want to protect. If you want to automate snapshot replication to a remote location, you can also specify the remote location.

Nutanix synchronizes protection policies between paired AZs. After you perform a failover to the recovery location, that location becomes the primary and snapshot replication automatically resumes to the former primary location (which has become the new recovery location) to protect the system from future failover events. If the VPN is connected, your workloads are protected automatically; the administrator doesn’t need to take action to ensure that the two datacenters remain in sync.

![Protection Policy Options](../images/protection-policy-options.png "Protection Policy Options")

#### Recovery Plans

A recovery plan orchestrates restoring protected VMs at a backup location, whether that location is on-premises or in a public cloud. Recovery plans can either recover all specified VMs at once or, with what is essentially a runbook functionality, use start sequences with optionally configurable interstage delays to recover applications gracefully and in the required order. Recovery plans that restore applications in Nutanix DRaaS can also create the required networks during failover and assign public-facing IP addresses to VMs.

Recovery plans also allow protected VMs to run embedded custom scripts. As long as you have Nutanix Guest Tools (NGT) installed, you can use a custom script to perform a variety of customizations, like change desktop wallpaper or even update existing management software after the failover. NGT contains drivers for AHV and allows advanced customization. On failover, the recovery plan provides a variety of options to change or maintain VM IP addresses. The plan shows the last four digits of the VM's new IP address, so you know beforehand what the new IP address is and can act on it.

![Recovery Plan Configuration](../images/recovery-plan-configuration.png "Recovery Plan Configuration")

<note> 
When you use Citrix App Layering, MCS, or PVS on Nutanix, don't install and enable NGT on base images. Nutanix recommends that you only install VirtIO drivers in base images with Citrix App Layering, MCS, or PVS nonpersistent images. If you use Citrix MCS to deploy a full clone image, you can install NGT after the MCS full clone deployment is complete.
</note>

Refer to the [Data Protection and Disaster Recovery best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2005-Data-Protection:BP-2005-Data-Protection) and [tech note](https://portal.nutanix.com/page/documents/solutions/details?targetId=TN-2027-Data-Protection-and-Disaster-Recovery:TN-2027-Data-Protection-and-Disaster-Recovery) for more detailed information.
