# Nutanix End User Computing 
## Lab Build Modules

## Introduction
This repo is for your Nutanix End User Computing Lab Build Modules. It helps you to automate the creation and maintenance of Windows Desktop and Server images used in the Nutanix EUC Solutions engineering lab.


* Windows Server 2022 and Windows 10/11 golden images

## Reguirements
The Powershell script to ceeate the golden images: /deployments/images/mdt/CreateVM-API-Container.ps1
This can be used using Visual Studio Code and Docker Desktop.

Currently the script is using:

* Nutanix v2 API calls to create the VM
* MDT server to install the Base image
* Ansible for installing applications and applying optimizations

###
MDT OS images are imported with the following naming convention:
* 3 characters for OS type (W10, W11 or SRV) - 4 numbers: client is for OS Build version (21H2 for example) and server is for server version (2016, 2019, 2022) - 4 numbers for year and month of installed updates (2205 = year 2022, month May).
Examples:
Client OS: W10-21H2-2205
Server OS: SRV-2022-2205

Iso files can be downloaded from https://my.visualstudio.com/downloads

=======
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

1. Make sure you are connected to the Nutanix VPN - this is important because you will be connecting to on-premises clusters and build servers directly from the Docker Container

2. Update the DockerFile and comment out the powershell commands that are irrelevant to the Operating System you are running the Container on.
    ```
    # Use this line if you are using x64
    RUN curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/powershell-7.3.0-linux-x64.tar.gz

    # # Use this line if you are using ARM
    RUN curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/powershell-7.3.0-linux-arm64.tar.gz
    ```

1. Make sure you have the docker desktop application running on your laptop. Click on Remote Explorer on the left of Visual Studio Code, then open Folder in Container. Make sure to open the Solutions-EUC folder and Visual Studio will build a container for you, install all the relevant tools and open the repository within that container

    Open In Folder

    ![](/ntnx-euc-lab/images/open_in_folder.png)

    You will know you are connected to the container when you see the following in the bottom right of your VSCode window

    ![](/ntnx-euc-lab/images/docker_connected.png)

1. My default the terminal window should open up and have the language of 'bash' selected.  In the console you will need to run the following command (substituting %USERNAME%, %PASSWORD%, %MDT_SERVER_IP% and %MDT_SHARE%) to mount a drive to the MDT Deployment server

    ```
    sudo mkdir /mnt/mdt
    sudo chmod 777 /mnt/mdt
    sudo mount -t cifs -o rw,file_mode=0117,dir_mode=0177,username=%%USERNAME%%,password='%%PASSWORD%%',domain=wsperf //%%MDT_SERVER_IP%%/%%MDT_SHARE%% /mnt/mdt"
    ```
    This should return no errors and enable you to connect to the MDT server from within the container.

2. Open a PowerShell terminal inside the container using the Terminal Dropdown in Visual Studio Code, this can be found on the right hand side of the terminal

    ![](/ntnx-euc-lab/images/posh_terminal.png)

3. Move to the Build Directory by entering the following command

    ```
    cd ./ntnx-euc-lab/deployments/images/mdt/
    ```

4. Rename the CreateVM.json.template file to CreateVM.json and update file with your values (NOTE: At present there is no ability to create new VLANS so please ensure the details you enter are relevant for the target cluster you are planning on deploying to)

    For reference, the Ansible path should be "/workspaces/solutions-euc/ntnx-euc-lab/deployments/images/ansible/" including the trailing /

    Once the file is update, close and save it

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

1. Run the following command to start a build then follow the on screen prompts to configure the build variables

    ```
    cd ./ntnx-euc-lab/deployments/images/mdt/
    ```

1. As the build progresses you will receive 2 notifications in the #vsi-monitor Slack channel. The first one is to tell you that the MDT portion of the build sequence is complete and the second is to tell you that the Ansible process has completed.  Please note you will receive 2 notifications even if you select No for the Ansible run as the second notification takes this into account but will only happen after the VM is shot down and a snapshot has been taken.

    ![](/ntnx-euc-lab/images/vsi_result.png)
