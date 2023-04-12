# Conclusion

## Nutanix Flow

- Protecting desktops and infrastructure VMs for your critical Citrix Virtual Apps and Desktops deployment on AHV is easy, secure, and scalable with Flow. 
- Prism Central makes it simple to create categories to group VMs and security policies to protect them. Security policies stop desktop VMs from accessing restricted resources and spreading malware, and prevent outside access for both desktops and infrastructure. 
- Thanks to the dynamic nature of categories and security policies, VMs are automatically secured at creation. 
- Flow visualization allows you to constantly monitor traffic to ease the burden of policy creation and catch any unexpected traffic.
- Use address spaces and services when defining rules as this will allow you to easily add to and change the rule base in a run environment.

## Citrix Virtual Apps and Desktops

Nutanix Flow is a great way to secure your Citrix Virtual Apps and Desktops for both Infrastructure and Workers however currently there are some considerations to be taken into account when implementing and designing Nutanix Flow.

- Citrix Infrastructure is an easy win as by nature it is static in its configuration.
- One to one user to desktop mappings can be either secured using an Application Security policy or a VDI security policy based on your business needs.
- Scale should be considered if using the VDI Security Policies (not covered in this document).
- Many to one user to desktop configurations are not currently supported in Nutanix Flow however,
  - Designing for Many to One can overcome "some" limitations.
  - Silo your Server based workers and put restrictions in place based on the application set.
- Nutanix Flow will impact the boot cycle (with a slightly longer boot to registration time) of Citrix Workers so cater for this in your boot timings.

## Overall Security Posture

- Implementing Nutanix Flow (even for infrastructure only) will help the overall security posture of your deployment.
- Remember "something" is better than "Nothing". The overall idea is to slow down attackers in your environment.
- Logging is key, you need to ship your logs to a central location to your Security Operations teams can regularly review and react to them.