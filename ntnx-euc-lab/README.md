# Nutanix End User Computing 
## Lab Build Modules

## Introduction
This repo is for your Nutanix End User Computing Lab Build Modules. It helps you to automate the creation and maintenance of Windows Desktop and Server images used in the Nutanix EUC Solutions engineering lab.

## Prerequisite
Before you start, make sure to:

* Environment with Nutanix Prism Element

* [Docker Desktop](https://www.docker.com/products/docker-desktop/) This approach simplifies the process of not having to install tools directly in the base operating system

* [Microsoft Visual Studio Code](https://code.visualstudio.com/) This is needed if following the Docker approach

* [Remote Development VS Code Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) Extension needed to operate inside of the container

* Current Pre-reqs

    * Storage Container configured on the Nutanix Cluster

    * Network VLAN Configured on the Nutanix Cluster

    * MDT Boot ISO uploaded to the Nutanix Cluster

    * MDT Task Sequence configured for the relevant build

## Steps

1. Clone this repository

    ```
    git clone https://github.com/nutanix-enterprise/solutions-euc.git
    ```

1. Make sure you are connected to the Nutanix VPN

1. Update the DockerFile and un-comment the powershell commands that are relevant to the Operating System you are running the Container on

1. Click on Remote Explorer on the left of Visual Studio Code, then open Folder in Container. Make sure to open the Solutions-EUC folder and Visual Studio will build a container for you, install all the relevant tools and open the repository within that container

1. Open a PowerShell terminal inside the container using the Terminal Dropdown in Visual Studio Code

1. Move to the Build Directory

    ```
    cd ./ntnx-euc-lab/deployments/images/mdt/
    ```

1. Rename the CreateVM.json.template file to CreateVM.json and update file with your values

    ```
    {
        "Cluster": {
            "ip": "10.10.10.10",
            "username": "admin",
            "password": "password"
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
            "VLAN": "VLAN164",
            "Container": "VDI",
            "Hypervisor": "AHV"
        },
        "MDTconfig": {
            "serverIP" : "10.10.10.10",
            "share" : "MDTShare$"
        },
        "Ansibleconfig": {
            "ansiblepath": "/path/to/ansible/playbooks/including/trailing/slash/"
        },
        "Slackconfig": {
            "Slack" : "https://hooks.slack.com/services/slackhookservice"
        },
        
        "ProductKeys": {
            "2019": "",
            "2022": ""
        }
    }
    ```
