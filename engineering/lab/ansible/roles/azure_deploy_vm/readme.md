# Setup Ansible for Azure

Deploying Azure Virtual Machines with Ansible requires several chained components outlined below:

## Container Configuration

Ansible requires the `azure.azcollection` module to interact with Azure. This is deployed via an Ansible Galaxy Collection. Execute the following from within the build container:

```
curl -O https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements-azure.txt
pip install -r requirements-azure.txt
rm requirements-azure.txt
ansible-galaxy collection install azure.azcollection
```

## Authentication and Connection

Ansible uses an Azure Service Principal (App) to interact with Azure. You can read the [Microsoft Quickstart here](https://learn.microsoft.com/en-us/azure/developer/ansible/create-ansible-service-principal?tabs=azure-cli).

There are two methods to provide Ansible with the appropriate credential details:

1. You can define a credentials file within the Container. By default, Ansible will look for a `~/.azure/credentials` file with the following content:

```
[default]
subscription_id=<subscription_id>
client_id=<security-principal-appid>
secret=<security-principal-password>
tenant=<security-principal-tenant>
```

2. You can export (this is more secure) the detail as environment variables using the following code:

```
export AZURE_SUBSCRIPTION_ID=<subscription_id>
export AZURE_CLIENT_ID=<security-principal-appid>
export AZURE_SECRET=<security-principal-password>
export AZURE_TENANT=<security-principal-tenant>
```

## Ansible Playbook and Roles

A playbook has been configured for Azure VM deployments: `azure_deploy_vms.yaml`. Additionally, an Ansible Role exists: `azure_deploy_vms.yaml`.

The following outcomes are achieved:

1. The instance is deployed in Azure.
2. Ansible remoting is configured within the VM by an Azure Extension.
3. [PENDING] The VM is joined to the `WSPerf` Domain. This uses the Ansible galaxy `microsoft.ad` collection.
4. [PENDING] The VM is targeted with an Ansible Playbook for image build tasks.
5. An Azure snapshot is created for the VM.
6. The VM is deallocated (Powered-Off).

## Ansible Variable Files and Instance Specific components for Azure

The current setup for Azure VM builds uses the following logic and files:

-  `vars_azure_common.yml` contains general configuration items for Azure, configurations such as `Resource Group`, `location`, `vnet` and `subnet` details etc.
-  An instance-specific variables file that is passed to the pipeline at the time of execution, for example, `vars_azure_standard_d8as_v5_w10ms.yml`. This contains **unique** information for the VM build:
   -  `vm_name`: The name of the VM to be created in Azure. For example, `d8as-v5-w10ms`.
   -  `vm_sku`: The instance Sku/size. For example, `Standard_D8as_v5`.
   -  `disk_sku`: The Disk Sku for the OS disk. For example, `PremiumSSD_LRS`.
   -  `disk_size`: The physical size of the disk in GiB. For example, `127` equates to a `P10 Premium Disk`.
   -  `license_type`: The license type for the VM run. This sets the VM to either `Windows_Client` for Windows 10 or 11, Windows 10 or 11 Enterprise Multi-Session or `Windows_Server` for Windows Server OS BYOD. If not set, the VM includes a license and is billed accordingly. You want this set.
   -  `admin_username`: The local admin account to be set on the VM.
   -  `admin_password`: The password of the local admin account.
   -  `offer`: The instance offering (OS) that you want to use. For example, `Windows-10`, `Windows-11` or `WindowsServer`.
   -  `publisher`: The offering publisher. For example, `MicrosoftWindowsDesktop` or `MicrosoftWindowsServer`.
   -  `sku`: The specific sku of the offering. For example, `win10-22h2-avd-g2` for Windows 10 Enterprise Multi-Session, `win11-23h2-avd` for Windows 11 Enterprise Multi-Session and `2022-datacenter-g2` for Windows Server 2022.
   -  `accelerated_networking`: Accelerated Networking in use or not. Boolean value.
   -  `winrm_timeout`: The timeout to wait for winrm connectivity for Ansible post the deployment of Ansible provisioning scripts.
   -  `winrm_port`: The port used for Ansible. Default is `5986`.

The following variable configuration files have been created for the performance testing initiative:

-  `vars_azure_standard_d8as_v5_ws2022.yml`
-  `vars_azure_standard_d8as_v5_w10ms.yml`
-  `vars_azure_standard_d8as_v5_w11ms.yml`
-  `vars_azure_standard_d8s_v5_ws2022.yml`
-  `vars_azure_standard_d8s_v5_w10ms.yml`
-  `vars_azure_standard_d8s_v5_w11ms.yml`
-  `vars_azure_standard_e8s_v5_ws2022.yml`
-  `vars_azure_standard_e8s_v5_w10ms.yml`
-  `vars_azure_standard_e8s_v5_w11ms.yml`
-  `vars_azure_standard_f8s_v2_ws2022.yml`
-  `vars_azure_standard_f8s_v2_w10ms.yml`
-  `vars_azure_standard_f8s_v2_w11ms.yml`
-  `vars_azure_standard_f16s_v2_ws2022.yml`
-  `vars_azure_standard_f16s_v2_w10ms.yml`
-  `vars_azure_standard_f16s_v2_w11ms.yml`

When you are executing a build, you can run the following Ansible command:

`ansible-playbook azure_deploy_vm.yml --extra-vars "@./azure_vars/vars_azure_standard_d8as_v5_ws2022.yml"`

This will build a Windows Server 2022 machine, based on the Azure Standard_D8as_v5 spec instance.

## Finding Sku Details for Azure VMs

The easiest way to identify image offering details and VM sku is via az cli, which is filterable. You can use the following examples:

-  `az vm image list --output table --all --publisher Microsoft --offer Windows-10 --sku avd` will find all current Windows 10 Enterprise Multi-Session offerings
-  `az vm image list --output table --all --publisher Microsoft --offer Windows-11 --sku avd` will find all current Windows 11 Enterprise Multi-Session offerings
-  `az vm image list --output table --all --publisher Microsoft --offer WindowsServer --sku 2022` will find all current Windows Server 2022 offerings

Note that we use the latest release for each. This is configured in the `main.yml` for the `azure_deploy_vm` role under the image configuration.
