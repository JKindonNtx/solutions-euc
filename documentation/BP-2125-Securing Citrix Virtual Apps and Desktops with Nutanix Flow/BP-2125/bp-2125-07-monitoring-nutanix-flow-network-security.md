# Validate Communication

Creating the policies in Monitor mode allows you to operate the CVAD environment in a non-intrusive Monitoring state for a few hours, days, or weeks to check for any traffic missed in the policy. 

This is vitally important to prevent an outage when you change the policy mode from "**Monitor**" to "**Enforce**".

By opening up a defined Security Policy you can view traffic that is discovered but not covered by any defined rules. You can inspect the traffic by hovering over the yellow line and if applicable, add it to the policy by either allowing the address space access or updating the service to include the port and protocol.

![Monitoring Network Blocks](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image40.png "Monitoring Network Blocks")

The above example shows traffic from an external IP not included in the **Campus Network address space**  trying to access the **Citrix License server over ICMP**. This has been blocked by Nutanix Flow.

Once satisfied that policies are functioning as expected, and the relevant access is in place, you can enforce the restrictions.