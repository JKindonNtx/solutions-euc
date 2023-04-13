# Enforce Security Policies

- Navigate to the Prism Central menu, select "**Network and Security**", then click "**Security Policies**". 
- Select the policy you wish to enforce.
- From the drop-down menu select "**Enforce**"
- Fill out the confirmation dialog and click "**Confirm**"

![Enforce Security Policy](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image41.png "Enforce Security Policy")

<note>
You do not need to enforce all your policies at the same time. Use a gradual approach here to ensure that you do not impact your production environment.
</note>

Once done you will see that the policy is now enforced.

![Enforced Security Policy](../images/bp-2125-securing-citrix-virtual-apps-and-desktops-with-nutanix-flow_image42.png "Enforced Security Policy")

If there are have issues with the policy blocking traffic that was missed during the monitor stage you can roll it back by performing the following.

- Select the policy you wish to roll back.
- From the drop-down menu select "**Monitor**"
- Fill out the confirmation dialog and click "**Confirm**"