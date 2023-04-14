# Conclusion

## Nutanix Flow

- Protecting desktops and infrastructure VMs for a CVAD deployment on AHV is simple, secure, and scalable with Flow. 
- Prism Central makes it simple to create categories to group VMs and security policies to protect them. Security policies stop desktop VMs from accessing restricted resources and spreading malware, and prevent outside access for both desktops and infrastructure. 
- Thanks to the dynamic nature of categories and security policies, VMs are automatically secured at creation. 
- Flow visualization allows you to constantly monitor traffic to ease the burden of policy creation and catch any unexpected traffic.
- Use address spaces and services when defining rules as this will allow you to easily add to and change the rule base in a run environment.

## Citrix Virtual Apps and Desktops

Nutanix Flow is a great way to secure CVAD for both Infrastructure and Workers however currently there are some considerations to be taken into account when implementing and designing Nutanix Flow.

- Citrix Infrastructure is an easy win as by nature it is static in its configuration.
- 1:1 user to desktop mappings can be either secured using an Application Security policy or a VDI security policy based on the business needs.
- Scale should be considered if using the VDI Security Policies (not covered in this document).
- 1:Many user to desktop configurations are not currently supported in Nutanix Flow however,
  - Designing for 1:Many can overcome limitations in that you can "silo" groups of multi-user servers with similar requirements and apply security policies to these as a group. 
- Nutanix Flow will impact the boot cycle (with a slightly longer boot to registration time) of Citrix Workers so cater for this in your boot timings.

## Overall Security Posture

- Implementing Nutanix Flow (even for infrastructure only) will help the overall security posture of your deployment.
- Remember the idea is to slow attackers down so aim to put as many obstacles in front of the attackers without impacting your user experience, Nutanix Flow can help with this. 
- Logging is key, you need to ship your logs to a central location to your Security Operations teams can regularly review and react to them.