# _VSI_Scripts
This document describes the Nutanix LoginVSI automation framework. The original .json files are ignored by github (could have sensitive information in it), so you will find .json.txt files instead. Make sure to rename these files to .json.

# Prerequisites

## Active Directory, DHCP prep
OU where target desktops are
OU were Launcher VMs are
Group Policies
LoginVSI user accounts
## VSI management server
This describes the prerequisites for the Login VSI management server.
### Install
Install on the LoginVSI server:
- Powershell 5.x
- Citrix XenApp and XenDesktop SDK
- VMware vSphere Powershell modules
- VMware Horizon Powershell modules
- Nutanix Cmdlets (NutanixCmdlets.msi)
- Anaconda3 (installs Python 3 for Windows)
    - This is required to upload the results to perf.nutanix.com
- Github (Git-2.32.0.2-64-bit.exe)
    * Start Git-Bash
    * Set your username: git config --global user.name "FIRST_NAME LAST_NAME"
    * Set your email address: git config --global user.email "MY_NAME@example.com"
    * create a public git repository ntnx-vsi-results (location where the VSI-charts are saved after each run to be able to post to Slack)
    * create ssh key to be able to read/write to github.com/username/ntnx-vsi-results/
        - ssh-keygen -t ed25519 -C "name@nutanix.com"
        - Store the key pair in %HOMEPATH%\.ssh\
        - Create %HOMEPATH%\.ssh\config
        config:
        Host github.com-_vsi_results
	    Hostname github.com
        IdentityFile=~/.ssh/<Name of ssh key>
    * From Git-Bash go to the folder where you want the ntnx-vsi-results folder to be stored (d:\data for example)
    * git clone git@github.com-_vsi_results:/username/ntnx-vsi-results.git
    * The VSI results folder should now be in D:\Data\ntnx-vsi-results
    * Edit [config.json](config.json.txt) to include this path ("localGitrepo": "D:\\Data\\ntnx-vsi-results\\",
    * Also make sure that "GitURL": "github.com/username/ntnx-vsi-results/" is pointing to the correct user and repository.




### LoginVSI setup
- LoginVSI setup (Install in D:\LoginVSI)
- Install LoginVSI pro library
- Install LoginVSI license file
- Extract .\_Tools\_VSI_Tools.zip to D:\LoginVSI\_VSI_Tools
- Extract the content of this github repository in D:\LoginVSI\_VSI_Scripts
- Copy .\Workloads\*.txt to D:\LoginVSI\_VSI_Workloads\Custom Workloads\
- Run the LoginVSI console and configure
    * Launchers
    * Select workload "KnowledgeWorker_". This is the same as the official KnowledgeWorker, but this one will not get stuck as often as the original one.

## Launcher VMs
Deploy golden image using MDT task: 
Currently 30 launcher VMs on cluster RTPTest83 (AHV), pinned to node 1,2,3 and 30 launcher VMs on cluster RTPTest84 (ESXi), pinned to node 1,2,3
Launcher VMs are deployed using Citrix CVAD (WS-XD3).

### VSI Launcher prep
If deploying new Launcher VMs, make sure that there are enough Citrix licenses available!

# Prepare test
Before starting a test, prepare the hosting infrastructure and the broker
## Hosting
Create golden image
### VMware ESXi
Pin desktops to 1 node
Add Hosting connection to Citrix CVAD (WS-XD3) or VMware Horizon (WS-HCON01)
### Nutanix AHV
Set host affinity on golden image
Add Hosting connection to Citrix CVAD (WS-XD3

## Broker

### Citrix
- Create Machine Catalog
- Create Delivery Group 
    - Make sure that the name for MC, DG and published desktop name are all equal.
    - Add Desktops to DG.
- Edit Delivery group > Power management > make sure all VMs are always on (weekdays and weekends)

### VMware
- Create desktop pool
instant clones, linked clones

## Prepare Automation
Edit the appropriate config files (when changing hosting and/or broker):
* AHV and AOS (even when using AOS on ESXi): edit (remove .txt extension) [config.AHV.json](/Nutanix/config.AHV.json.txt)
* VMware (When running on ESXi): edit (remove .txt extension) [config.ESXserver.json](/VMware/config.ESXserver.json.txt)
* Citrix CVAD (When using Citrix CVAD): edit (remove .txt extension) [config.XenDesktop.json](/Citrix/XenDesktop.json.txt)
* VMware Horizon (When using VMware Horizon): edit (remove .txt extension) [config.View.json](/VMware/config.View.json.txt)

Edit the main [config.json](config.json.txt) (remove .txt extension). This is used by [automation.ps1](automation.ps1).
Read the [config.json.readme.txt](config.json.readme.txt) for more information about the fields and values.



