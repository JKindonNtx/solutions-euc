# Workspot on Nutanix AHV
Feedback from testing Workspot on Nutanix for Nutanix Cloud Clusters Qualification.

## Nutanix Integration
- Workspot integrates with Nutanix AHV using Prism Element (PE). 
- Workspot uses VM clone, delete, and power management APIs for integration.
- There is not other integration for Nutanix.
  
## Virtual Machine Deployment Workflow
1. Create a VM for a template VM.
2. Install Workspot agent.
3. Run Workspot Config Editor.
   1. Domain join.
   2. OU location
   3. Additional settings. 
4. Shutdown VM.

## Update Virtual Machine Workflow
1. Clone existing template VM.
2. Uninstall and reinstall Workspot agent.
3. Run Workspot Config Editor.
4. Shutdown VM.

## Workspot on Nutanix AHV Feedback
- No Prism Central (PC) integration. Will have to use similar workflow as PE with v3/v4 APIs.
- Need to validate whether using PE or PC for integration point. There is no validation of APIs/API versions. You can add a connection to PC but VM operations will fail.
- Snapshots/Recovery points should be used for image management workflow.
- Machine is tied to OU location, etc. using a Sysprep like operation causing VM per pool and VM per update.
- Connector uses Java.
- Connector install have to copy and paste key from portal.