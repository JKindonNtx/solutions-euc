# Conclusion

## Flow Network Security

- Protecting desktops and infrastructure VMs for a Citrix Virtual Apps and Desktops deployment on AHV is simple, secure, and scalable with Flow Network Security. 
- Prism Central makes it simple to create categories to group VMs and security policies to protect them. Security policies stop desktop VMs from accessing restricted resources and spreading malware and prevent outside access for both desktops and infrastructure. 
- Thanks to the dynamic nature of categories and security policies, VMs are automatically secured at creation. 
- With Flow Network Security visualization, you can constantly monitor traffic to ease the burden of policy creation and catch any unexpected traffic.
- Use address spaces and services when defining rules, as these options allow you to easily add to and change the rule base in a run environment.

## Citrix Virtual Apps and Desktops

Flow Network Security is a great way to secure Citrix Virtual Apps and Desktops for both infrastructure and worker VMs. Consider the following factors when implementing and designing Nutanix Flow:

- Citrix infrastructure is an easy win, as it has a static configuration.
- Based on your business needs, you can secure one-to-one user-to-desktop mappings using either an application security policy or a VDI security policy.
- If you're using VDI security policies (not covered in this document), be sure to consider scale.
- Flow Network Security doesn't currently support one-to-many user-to-desktop configurations. 
  - However, if you design for one-to-many user-to-desktop configurations, you can establish groups of multiuser servers with similar requirements and apply security policies to them together, which can overcome some limitations. 
- Flow Network Security can cause a slightly longer boot to registration time for Citrix worker VMs, so account for this factor in your boot timings.

## Overall Security Posture

- Implementing Flow Network Security (even for infrastructure only) can improve the overall security posture of your deployment.
- Remember that the basic strategy is to slow attackers down, so try to put as many obstacles in front of attackers as possible without impacting your user experience. Flow Network Security can help. 
- Logging is key. Send your logs to a central location where your security operations teams can regularly review and react to them.