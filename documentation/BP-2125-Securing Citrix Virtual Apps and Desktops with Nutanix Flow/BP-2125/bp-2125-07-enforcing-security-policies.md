# Enforcing Security Policies

To move policies from monitor mode to enforce mode, perform the following steps:

- In Prism Central, select **Network and Security**, then click "**Security Policies**. 
- Select the policy you want to enforce.
- In the **Actions** dropdown menu, select **Enforce**.
- Complete the confirmation dialog box and click **Confirm**.

![Enforce Security Policy](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image41.png "Enforce Security Policy")

<note>
You don't need to enforce all your policies at the same time. Use a gradual approach to ensure that the production environment continues to function properly.
</note>

The policy is now enforced.

![Enforced Security Policy](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image42.png "Enforced Security Policy")

If any issues arise because a policy blocks traffic, perform the following steps to return to monitor mode:

- Select the policy you want to return to monitor mode.
- In the **Actions** dropdown menu, select **Monitor**.
- Complete the confirmation dialog box and click **Confirm**.