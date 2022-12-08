# Lab Build Modules

## Introduction

This repository is for your Nutanix End User Computing Lab Build Modules. It helps you to automate the creation and maintenance of Windows Desktop and Server images used in the Nutanix EUC Solutions engineering lab.

## Overview

This repository includes everything you will need to deploy lab virtual machines.

There are two main script components

- A PowerShell script to configure the Nutanix Clusters `/build/New-ClusterConfigAHV.ps1`
- A PowerShell script to create the golden images: `/build/New-VirtualMachine.ps1`

Both scripts can be executed with Visual Studio Code and Docker Desktop integration.

Currently, the deployment of virtual machines use:

- Nutanix v2 API calls to create the VM
- MDT server to deploy the base Operating System
- Ansible for installing applications and applying optimizations
- [Chocolatey Package Management](https://chocolatey.org/) for latest applications as required
- The [Evergreen PowerShell Module](https://www.powershellgallery.com/packages/Evergreen) for latest applications as required
- The [Nevergreen PowerShell Module](https://www.powershellgallery.com/packages/Nevergreen) for latest applications as required

###
MDT OS images are imported with the following naming convention:

| Char Length| Description | Example |
| --- | --- | --- |
| 3 | OS type | `W10`, `W11` or `SRV` |
| 4 | Client OS Build Version | `21H2` |
| | Server OS Build Version | `2016`, `2019`, `2022` |
| 4 | year and month of release | May 2022: `2205` |

Examples:

| OS Type | Naming |
| --- | ---| 
| Client | `W10-21H2-2205` |
| Server | `SRV-2022-2205` | 

Iso files can be downloaded from https://my.visualstudio.com/downloads for importing into MDT.

## Prerequisites

Before you start, make sure to have the following:

| Category | Requirement |
| --- | --- |
| Infrastructure | Nutanix with Prism Element |
| Infrastructure | Storage Container configured on the Nutanix Cluster. See `New-ClusterConfigAHV.ps1` |
| Infrastructure | Network VLAN Configured on the Nutanix Cluster. See `New-ClusterConfigAHV.ps1` |
| Infrastructure | MDT Boot ISO uploaded to the Nutanix Cluster. See `New-ClusterConfigAHV.ps1` |
| Infrastructure | MDT Task Sequence configured for the relevant build |
| Execution Environment | [Docker Desktop](https://www.docker.com/products/docker-desktop/) This approach simplifies the process of not having to install tools directly in the base operating system |
| Execution Environment | [Microsoft Visual Studio Code](https://code.visualstudio.com/) This is needed if following the Docker approach | 
| Execution Environment | [Remote Development VS Code Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) Extension needed to operate inside of the container |

# General steps to prepare for deployment

1. Clone this repository

    ```
    git clone https://github.com/nutanix-enterprise/solutions-euc.git
    ```

    **NOTE:** Make sure you are connected to the Nutanix VPN - this is important because you will be connecting to on-premises clusters and building servers directly from the Docker Container

2. Make sure you have the docker desktop application running on your laptop. Click on Remote Explorer on the left of Visual Studio Code, then open Folder in Container. Make sure to open the Solutions-EUC folder and Visual Studio will build a container for you, install all the relevant tools and open the repository within that container. The first time you open up the folder in the container it may take some time as it has to download and install all the components

    Open In Folder

    ![](/engineering/lab/images/open_in_folder.png)

    You will know you are connected to the container when you see the following in the bottom right of your VS Code window

    ![](/engineering/lab/images/docker_connected.png)

3. Open a PowerShell terminal inside the container using the Terminal Dropdown in Visual Studio Code, this can be found on the right hand side of the terminal

    ![](/engineering/lab/images/posh_terminal.png)

4. Move to the build directory by entering the following command

    ```
    cd ./engineering/lab/build/
    ```

5. Rename the `LabConfig.json.template` file to `LabConfig.json` and update file with your values:

    ```
    cp LabConfig.json.template LabConfig.json
    ```

    Once the file is updated, close and save it

    ```
    {
        "Cluster": {
            "ip": "10.10.10.10",
            "username": "admin",
            "password": "password",
            "CVMsshpassword": "password"
        },
            "VM": {
            "UEFI": true,
            "Secureboot": true,
            "vTPM": false,
            "CPUsockets": "1",
            "CPUcores": "2",
            "vRAM": "4096",
            "Disksize": "64",
            "ISO": "LiteTouchPE_x64-NP.iso", 
            "ISOUrl": "http://webserver/mdt/",
            "VLAN": "164",
            "Container": "VDI",
            "Hypervisor": "AHV",
            "Method": "MDT"
        },
            "MDTconfig": {
            "serverIP" : "10.10.10.10",
            "share" : "MDT$",
            "UserName" : "Administrator",
            "Password" : "password",
            "Domain" : "domain",
            "Directory" : "mdt"
        },
        "Ansibleconfig": {
            "ansiblepath": "/workspaces/solutions-euc/engineering/lab/ansible/"
        },
        "Slackconfig": {
            "Slack" : "https://hooks.slack.com/services/slackservice"
        },
        
        "ProductKeys": {
            "2019": "WMDGN-G9PQG-XVVXX-R3X43-63DFG",
            "2022": "WX4NM-KYWYW-QJJR4-XV3QB-6VM33"
        }
    }
    ```

## Preparing the Nutanix Cluster

**NOTE:** This step will typically only be required once unless values are being changed:

1. Run the following command to start a build then follow the on-screen prompts to configure the build variables

    ```
    ./New-ClusterConfigAHV.ps1
    ```

2. Once the configuration has completed you will receive a notification in the #vsi-monitor slack channel

    ![](/engineering/lab/images/ahv_reconfigure.png)

## Steps to build a Virtual Machine

1. Run the following command to start a build, then follow the on-screen prompts to configure the build variables:

    ```
    ./New-VirtualMachine.ps1
    ```

2. As the build progresses you will receive 2 notifications in the #vsi-monitor Slack channel. 

   - The first one is to tell you that the MDT portion of the build sequence is complete
   - The second is to tell you that the Ansible process has completed
  
    Please note you will receive 2 notifications even if you select `No` for the Ansible run as the second notification takes this into account but will only happen after the VM is shut down and a snapshot has been taken

    ![](/engineering/lab/images/vsi_result.png)

## Notes for Windows Users

Docker Desktop uses the Windows Subsytem for Linux (WSL). By default WSL is memory intensive and will reserve as much memory as it can get it's hands on. To mitigate this issue, follow the below process to limit memory consumption:

Resolution noted from [here](https://www.koskila.net/how-to-solve-vmmem-consuming-ungodly-amounts-of-ram-when-running-docker-on-wsl/)

```
# Shutdown WSL
wsl --shutdown

# Test for and Create .wslconfg file
If (!(test-path $Env:UserProfile\.wslconfg)) { new-item -ItemType File $Env:UserProfile\.wslconfg }

# Add Memory limit
Add-Content $Env:UserProfile\.wslconfg [wsl2]
Add-Content $Env:UserProfile\.wslconfg memory=2GB

# restart docker
restart-service *docker* -Verbose

```