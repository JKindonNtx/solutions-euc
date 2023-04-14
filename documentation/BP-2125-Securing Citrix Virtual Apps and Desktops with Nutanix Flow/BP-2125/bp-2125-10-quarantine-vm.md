# Quarantine a Virtual Machine

Nutanix Flow provides the ability to quarantine a VM should there be a security breach in the environment. To quarantined a VM:

- Navigate to the Prism Central menu, select "**Compute and Storage**", then click "**VMs**". 
- Select "**View by**" from the top level menu on the right, and select the custom view defined earlier.

![VM Overview Categories](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image35.png "VM Overview Categories")

Click to select a VM to quarantine and select "**Actions**" then "**Quarantine VMs**".

![VM Quarantine](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image45.png "VM Quarantine")

Select "**Strict**" or "**Forensic**" based on the requirement and click "**Quarantine**".

![VM Quarantine Selection](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image46.png "VM Quarantine Selection")

The Virtual Machine view will update to reflect the quarantined VM.

![VM Quarantine Confirmation](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image47.png "VM Quarantine Confirmation")

To take the VM out of quarantine click to select a VM to take out of quarantine to and select "**Actions**" then "**Unquarantine VMs**"

As mentioned earlier there are 2 types of quarantine:

- Forensic
- Strict

Depending on the requirements you can define rules to allow inbound access to the virtual machine by editing the Security Policy for quarantine. The options for this are shown below.

![Example Quarantine Policy](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image06.png "Example Quarantine Policy")

Work with the security team to determine what actions you need to take before, during, and after a VM quarantine operation. Consider using VM and storage snapshots along with Flow Network Security quarantine to enable a successful response to any suspicious activity.