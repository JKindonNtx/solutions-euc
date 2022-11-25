# Nutanix End User Computing 
## Lab Build Modules

## Introduction
This repo is for your Nutanix End User Computing Lab Build Modules. It helps you to automate the creation and maintenance of:

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

