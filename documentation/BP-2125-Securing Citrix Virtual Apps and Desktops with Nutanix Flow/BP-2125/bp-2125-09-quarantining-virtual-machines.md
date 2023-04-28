# Quarantining Virtual Machines

Flow Network Security can quarantine a VM if there's a security breach in the environment. 

To quarantine a VM, review the [Flow Network Security documentation](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Guide:mul-quarantine-rule-configuration-c.html). To use the custom VM view you defined earlier, select it in the **View by** option in the top-level menu on the right side of the screen in Prism Central.

To remove a VM from quarantine, select it from the VM view, then select **Actions** and click **Unquarantine VMs**.

Flow Network Security offers two types of quarantine:

- Forensic
- Strict

Depending on the requirements you can define rules to allow inbound access to the VM by editing the security policy for quarantine. The following figure shows the two options for quarantine type.

![Example Quarantine Policy](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image06.png "Example Quarantine Policy")

Work with your security team to determine what actions you need to take before, during, and after a VM quarantine operation. Consider using VM and storage snapshots along with Flow Network Security quarantine to prepare a successful response to any suspicious activity.