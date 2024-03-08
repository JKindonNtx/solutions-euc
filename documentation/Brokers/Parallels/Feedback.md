# Parallels RAS on Nutanix AHV

Feedback from testing Parallels RAS on Nutanix. This does not include NC2 qualification considerations.

## Nutanix Integration

-  RAS integration is via Prism Element (PE) currently. Does not support Prism Central.
-  Uses a combination of v1 and v2 API calls for CRUD (provisioning) and power management tasks.
-  Decent integration as far as provisioning goes.
  
## Virtual Machine Deployment Workflow

Parallels uses a Template concept for provisioning. In the tested release (19.2) a template is tied to a pool. In 19.3, for other hypervisors such as vmware, the template has been decoupled. This functionality will be brought into Nutanix. The current flow is as follows. Note that all tasks are native within the RAS console unless identified otherwise.

-  Create a VM in Nutanix AHV.
-  Via a Nutanix "Provider" in RAS, import the VM and mark it as a Template. Depending on the OS, either one, or two agents are required in guest. These can be deployed via the RAS Console.
-  Create a Pool, and specify the appropriate machine template and Provisioning type:
   -  Thin Provision: This method will initially use the Nutanix API to create a snapshot of the VM disk, and then clone additional VMs from the snapshot
   -  Full Clone: This method will clone directly from the VM disk.
-  All Active Directory and Scale configurations are configured on the Pool. RASPrep makes each unique VM unique, and manages the Active Directory relationships within it's database.
-  To update a Template VM, set to maintenance mode in RAS, which then powers on the VM in Nutanix.
   -  Make the required changes to the VM.
   -  Remove Maintenance mode for the Template in RAS.
   -  Clones will be updated with the updated template.

## Parallels on Nutanix AHV Feedback

-  No Prism Central (PC) integration. Will have to use similar workflow as PE with v3/v4 APIs.
-  Documentation from RAS was very in depth. Attentiveness from product team was also good.
-  Validation on the Provider configuration was in place, but could be more intuitive - Adding a PC connection resulted in a "non compatible Nutanix version" warning vs a "you are trying to connect to Nutanix in the wrong way" sort of warning.
-  Very similar capability set to Citrix MCS but some limits in scalability with the current Template to Pool limitation.
-  Provisioning metrics are captured in the RAS RA.
-  There is no performance or end result difference for full clone vs thin clone in RAS - ultimately a machine is either created from the snapshot or a direct clone of the template VM disk.
-  Provisioning challenges at scale were dignified, owned and remediated by the RAS team.
-  Decoupling of the Template VM to Pool relationship will be a significant improvement - but this isn't a huge issue given the scale and target customer - the integration does feel "native" similar to a Citrix MCS.