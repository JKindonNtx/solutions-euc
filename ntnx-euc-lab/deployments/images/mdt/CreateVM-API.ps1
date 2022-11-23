# Create VM template using REST API
# Install Posh-SSH module. Required to connect to the hosts using SSH. Used for capturing performance stats.
if (!((Get-Module -ListAvailable *) | Where-Object {$_.Name -eq "Posh-SSH"})) {
    Write-Host "SSH module not found, installing missing module."
    Install-Module -Name Posh-SSH -RequiredVersion 2.3.0 -Confirm:$false -Force
}
Import-Module Posh-SSH
Remove-PSSnapin "Microsoft.BDD.PSSNAPIN"

# disable SSL certification verification
# you probably shouldn't do this in production ...
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
    $certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback +=
                delegate
                (
                    Object obj,
                    X509Certificate certificate,
                    X509Chain chain,
                    SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
                }
            }
        }
"@
Add-Type $certCallback
}
[ServerCertificateValidationCallback]::Ignore()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Functions
Function Get-Cluster {
    <#
    .Synopsis
    This function will collect cluster information.
    .Description
    This function will collect the cluster information using REST API call based on Invoke-RestMethod
    #>
    Param (
    [string] $debug
    )
    $credPair = "$($mgmtUser):$($mgmtPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($mgmtIP):9440/api/nutanix/v3/clusters/list"
    $Payload = @{
    kind   = "cluster"
    offset = 0
    length = 999
    } 
    $JSON = $Payload | convertto-json
    try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
    }
    catch {
    Start-Sleep 10
    Write-Host (Get-Date) ": Going once"
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
    }
    Return $task
}

Function Get-NTNXV2 {
    <#
    .Synopsis
    This function will collect information using the V2 API.
    .Description
    This function will collect the information using REST API call based on Invoke-RestMethod
    #>
    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $APIpath,
        [string] $debug
    )
    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/$APIpath"
    try {
    $task = Invoke-RestMethod -Uri $URL -method "get" -ContentType 'application/json' -headers $headers;
    }
    catch {
    Start-Sleep 10
    Write-Host (Get-Date) ": Going once"
    $task = Invoke-RestMethod -Uri $URL -method "get" -ContentType 'application/json' -headers $headers;
    }
    Return $task
}

Function Create-VMV2 {
    <#
    .Synopsis
    This function will create a snapshot of the VM using the V2 API.
    .Description
    This function will create a snapshot of the VM using REST API call based on Invoke-RestMethod. 
    #>
    Param (
        [System.object] $VMconfig,
        [string] $Name,
        [string] $VMtimezone,
        [string] $StorageUUID,
        [string] $ISOUUID,
        [string] $VLANUUID,
        [string] $debug
    )
    $Disksize = [int64]"$($VMconfig.VM.Disksize)"*1gb
    if ($($VMconfig.VM.vTPM)) {
        $Machinetype = "Q35"
        $vTPM = "true"
    }
    Elseif ($($VMconfig.VM.Secureboot)) {
        $Machinetype = "Q35"
        $vTPM = "false"
    }
    Elseif ($($VMconfig.VM.UEFI)) {
        $Machinetype = "PC"
        $vTPM = "false"
    }
    Else {
        $Machinetype = "PC"
        $vTPM = "false"
    }
    If ($($VMconfig.VM.UEFI)){
        [string] $UEFI = "true"
    }
    Else {
        [string] $UEFI = "false"
    }
    If ($($VMconfig.VM.Secureboot)){
        [string] $Secureboot = "true"
    }
    Else {
        [string] $Secureboot = "false"
    }
    $credPair = "$($VMconfig.cluster.username):$($VMconfig.cluster.password)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($VMconfig.cluster.ip):9440/PrismGateway/services/rest/v2.0/vms"
    $Payload = "{ `
        ""boot"": { `
          ""boot_device_order"": [ `
            ""CDROM"", `
            ""NIC"", `
            ""DISK"" `
          ], `
          ""secure_boot"": " + $Secureboot + ", `
          ""uefi_boot"": " + $UEFI + " `
        }, `
        ""machine_type"": """ + $Machinetype + """, `
        ""memory_mb"": " + $($VMconfig.VM.vRAM) + ", `
        ""name"": """ + $Name + """, `
        ""num_cores_per_vcpu"": " + $($VMconfig.VM.CPUcores) + ", `
        ""num_vcpus"": " + $($VMconfig.VM.CPUsockets) + ", `
        ""storage_container_uuid"": """ + $StorageUUID + """, `
        ""timezone"": """ + $VMTimezone + """, `
        ""vm_disks"": [{ `
            ""disk_address"": { `
              ""device_bus"": ""SCSI"", `
              ""device_index"": 0 `
            }, `
            ""vm_disk_create"": { `
              ""size"": " + $Disksize + ", `
              ""storage_container_uuid"": """ + $StorageUUID + """ `
              } `
            }, `
            { `
            ""disk_address"": { `
              ""device_bus"": ""SATA"", `
              ""device_index"": 0, `
              ""is_cdrom"": true `
            }, `
            ""is_cdrom"": true, `
            ""vm_disk_clone"": { `
              ""disk_address"": { `
                ""device_bus"": ""SATA"", `
                ""device_index"": 0, `
                ""vmdisk_uuid"": """ + $ISOUUID + """ `
              } `
            } `
          } `
        ], `
        ""vm_nics"": [ `
          { `
            ""adapter_type"": ""E1000"", `
            ""is_connected"": true, `
            ""network_uuid"": """ + $VLANUUID + """ `
          } `
        ] `
      }"
    try {
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -headers $headers;
    }
    catch {
    Start-Sleep 10
    Write-Host (Get-Date) ": Going once"
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -headers $headers;
    }
    Return $task
}
Function Set-VMpowerV2 {
    <#
    .Synopsis
    This function will set Power state of VM using the V2 API.
    .Description
    This function will set Power state using REST API call based on Invoke-RestMethod.
    Allowed actions: "ON", "OFF", POWERCYCLE", "RESET", "PAUSE", "SUSPEND", "RESUME", "SAVE", "ACPI_SHUTDOWN", "ACPI_REBOOT" 
    #>
    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $APIpath,
        [string] $Action,
        [string] $debug
    )
    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/$APIpath"
    $Payload = @{
        "transition"="$($Action)"
        } 
        $JSON = $Payload | convertto-json
    try {
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;
    }
    catch {
    Start-Sleep 10
    Write-Host (Get-Date) ": Going once"
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;
    }
    Return $task
}

Function Remove-CDROMV2 {
    <#
    .Synopsis
    This function will remove CD-ROM of the VM using the V2 API.
    .Description
    This function will remove CD-ROM of the VM using REST API call based on Invoke-RestMethod. 
    #>
    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $VMUUID,
        [string] $debug
    )
    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/vms/$($VMUUID)/disks/detach"
    $Payload = "{ `
        ""vm_disks"":[ `
            { `
                ""disk_address"": `
                { `
                    ""device_bus"":""SATA"", `
                    ""device_index"":0 `
                } `
            }] `
    }"
    try {
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -headers $headers;
    }
    catch {
    Start-Sleep 10
    Write-Host (Get-Date) ": Going once"
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -headers $headers;
    }
    Return $task
}

Function New-VMSnapV2 {
    <#
    .Synopsis
    This function will create a snapshot of the VM using the V2 API.
    .Description
    This function will create a snapshot of the VM using REST API call based on Invoke-RestMethod. 
    #>
    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $VMUUID,
        [string] $SnapName,
        [string] $debug
    )
    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/snapshots"
    $Payload = "{ `
        ""snapshot_specs"":[ `
            {""snapshot_name"":""" + $Snapname + """, `
            ""vm_uuid"":""" + $VMUUID + """ `
        }] `
    }"
    try {
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -headers $headers;
    }
    catch {
    Start-Sleep 10
    Write-Host (Get-Date) ": Going once"
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -headers $headers;
    }
    Return $task
}

Function Update-Slack {
    ##############################
    #.SYNOPSIS
    #Send update to Slack
    #
    ##############################
    Param(
        [String]$VMname,
        [String]$Slack

    )
    
    $body = ConvertTo-Json @{
        username = "LoginVSI automation factory"
        attachments = @(
            @{
                fallback = "Finished installing VM template."
                color = "#36a64f"
                pretext = "*Finished installing VM template*"
                title = $VMName
                text = "The VM with name $VMName is finished installing the ansible playbook and a snapshot was created."  
            }
        )
    }
    $RestError = $null
    Try {
        Invoke-RestMethod -uri $Slack -Method Post -body $body -ContentType 'application/json' | Out-Null
    } Catch {
      $RestError = $_
    }
}

[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None") ]
# Setting variables
$VMconfig = Get-Content -Path "$PSScriptRoot\CreateVM.json" -Raw | ConvertFrom-Json
$ESXihost = "$($VMconfig.Cluster.host)"
$Testhost = "$($VMconfig.Cluster.host)"
$mgmtIP = "$($VMconfig.Cluster.ip)"   
$mgmtUser = "$($VMconfig.Cluster.username)"
$mgmtPassword = "$($VMconfig.Cluster.password)"
$mgmtPasswordSec = ConvertTo-SecureString $mgmtPassword -AsPlainText -Force
$hypervisor = "$($VMconfig.VM.Hypervisor)"
$deploymentShare = "$($VMconfig.MDTconfig.deploymentShare)"
$MDTsqlServer = "$($VMconfig.MDTconfig.MDTsqlServer)"
$MDTSQLinstance = "$($VMconfig.MDTconfig.MDTSQLinstance)"
$MDTdatabase = "$($VMconfig.MDTconfig.MDTdatabase)"
$ansiblehost = "$($VMconfig.Ansibleconfig.ansiblehost)"
$ansiblepassword = "$($VMconfig.Ansibleconfig.password)"
$ansibleplaybook = "$($VMconfig.Ansibleconfig.playbook)"
$ansiblepath = "$($VMconfig.Ansibleconfig.ansiblepath)"
$Slack = "$($VMConfig.Slackconfig.slack)"
$debug = 2
$Clusterinfo = Get-Cluster -ClusterPC_IP $mgmtIP -nxPassword $mgmtPassword -clusername $mgmtUser -debug $debug
$VMTimezone = ($Clusterinfo.entities |Where-Object {$_.status.resources.network.external_ip -eq $($mgmtIP)}).status.resources.config.timezone
$Containerinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "storage_containers" -debug $debug
$StorageUUID = ($Containerinfo.entities |Where-Object {$_.name -eq $($VMconfig.VM.Container)}).storage_container_uuid
$Hostinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "hosts" -debug $debug
$HostUUID = ($Hostinfo.entities |Where-Object {$_.service_vmexternal_ip -eq $($Testhost)}).uuid
$Networkinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "networks" -debug $debug
$VLANUUID = ($Networkinfo.entities |Where-Object {$_.name -eq $($VMconfig.VM.VLAN)}).uuid
$ISOinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "images" -debug $debug
$ISOUUID = ($ISOinfo.entities |Where-Object {$_.name -eq $($VMconfig.VM.ISO)}).vm_disk_id
 
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1"
Add-PSSnapin "Microsoft.BDD.PSSNAPIN" | Out-Null
Write-Host (Get-Date) ":Loading MDT Powershell cmdlets"
If (!(Test-Path MDT:)) { New-PSDrive -Name MDT -Root $deploymentShare -PSProvider Microsoft.BDD.PSSNAPIN\MDTPROVIDER | Out-Null } 

$OSversion = Read-Host "Select Windows version (10, 11 or SRV)"
If ($OSversion -eq "SRV") {
    $winversions = Get-Item "MDT:\Operating Systems\Windows Server\*SERVERDATACENTER *"
}
Else {
    $winversions = Get-Item "MDT:\Operating Systems\Windows $osversion\Windows ?? Enterprise in*"
}

$i = 1
foreach($winver in $winversions){
    $winverselect = $winver.name -replace ".*in " -replace " install.wim"
    Write-Host "$i = $winverselect"
    $i++
}
$n = Read-Host "Select a version (Last 4 digits represents the installed updates: YYMM)"
$winverselected = $winversions[$n-1]
$WinVerBuild = $($winverselected.name) -replace ".*in " -replace " install.wim"
$VMId = (New-Guid).Guid.SubString(1,4)
$VName = $WinVerBuild.Substring(0,$WinVerBuild.Length-5) 
$Name = "$VName-$VMId"
$TaskSequenceID = "W$OSversion-BASE"

Write-Host "
_   _ _   _ _____  _    _   _ _____  __  
| \ | | | | |_   _|/ \  | \ | |_ _\ \/ / 
|  \| | | | | | | / _ \ |  \| || | \  /  
| |\  | |_| | | |/ ___ \| |\  || | /  \  
|_| \_|\___/  |_/_/   \_\_| \_|___/_/\_\ 
                                                                                                                                                                                        
"

Write-Host "
--------------------------------------------------------------------------------------------------------"
Write-Host "Cluster IP:             $mgmtIP"
Write-Host "Hypervisor:             $hypervisor"
Write-Host "Container name:         $($VMconfig.VM.Container)"
Write-Host "Configured VLAN:        $($VMconfig.VM.VLAN)"
Write-Host "Windows version:        $OSversion"
Write-Host "Windows Build:          $WinVerBuild"
Write-Host "VM Name:                $Name"
Write-Host "vCPUs:                  $($VMconfig.VM.CPUSockets) sockets - $($VMconfig.VM.CPUCores) core(s) per socket"
Write-Host "Memory:                 $($VMconfig.VM.vRAM) MB"
Write-Host "
--------------------------------------------------------------------------------------------------------"

$confirmationStart = Read-Host "Ready to deploy the template? [y/n]"
while($confirmationStart -ne "y") {
    if ($confirmationStart -eq 'n') { exit }
    
    Write-Host "Invalid input, please use y or n."
    $confirmationStart = Read-Host "Ready to deploy the template? [y/n]"
}
#Remove existing SSH keys.
Get-SSHTrustedHost | Remove-SSHTrustedHost

# Importing MDT DB modules
remove-module 'MDTDB' -ErrorAction SilentlyContinue
$loadedmodules = (Get-module | Select-Object name).name
if (!($loadedmodules.Contains("MDTDB"))) {
    import-module .\MDTDB.psm1 -force
    Write-Host (Get-Date) ":Loading the MDT Powershell module"
}
else {
    Write-Host (Get-Date) ":MDT CMDlets are not loaded, aborting the script"
    Break
}

# Connecting to the MDT DB with current user logon
Try {
    Connect-MDTDatabase -sqlServer $MDTsqlserver -instance $MDTSQLinstance -database $MDTdatabase | Out-Null
    Write-Host (Get-Date) ":Connecting to the MDT Database"
}
Catch {
    Write-Host (Get-Date) ":Couldn't connect to the MDT Database"
}

# Get GUID of OS
if ($OSVersion -eq 'SRV') {
    $RefImgOSguid = (Get-ItemProperty "MDT:\Operating Systems\Windows Server\$($winverselected.name)").guid
} Else {
    $RefImgOSguid = (Get-ItemProperty "MDT:\Operating Systems\Windows $OSversion\$($winverselected.name)").guid
}

# Modify Test Task Sequence to use new RefImg OS
$TSPath = "$($deploymentShare)\Control\$($TaskSequenceID)\ts.xml"
$TSXML = [xml](Get-Content $TSPath)
$TSXML.sequence.globalVarList.variable | Where-Object {$_.name -eq "OSGUID"} | ForEach-Object {$_."#text" = $RefImgOSguid}
$TSXML.sequence.group | Where-Object {$_.Name -eq "Install"} | ForEach-Object {$_.step} | Where-Object {$_.Name -eq "Install Operating System"} | ForEach-Object {$_.defaultVarList.variable} | Where-Object {$_.name -eq "OSGUID"} | ForEach-Object {$_."#text" = $RefImgOSguid}
$TSXML.Save($TSPath)

if ($hypervisor -eq 'AHV') {
    Try {
        # Create the VM
        Write-Host (Get-Date)":Create the VM with name $Name."
        $VMtask = Create-VMV2 -VMconfig $VMconfig -Name $Name -VMTimezone $VMtimezone -StorageUUID $StorageUUID -ISOUUID $ISOUUID -VLANUUID $VLANUUID -debug $debug
        $VMtaskID = $VMtask.task_uuid
        Write-Host (Get-Date)":Wait for VM create task ($VMtaskID) to finish." 
        Do {
            $VMtaskinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "tasks/$($VMtaskID)" -debug $debug
            $VMtaskstatus = $VMtaskinfo.percentage_complete
            If ( $VMtaskstatus -ne 100) {
                Start-Sleep -Seconds 5
            }
            Else {
                Write-Host (Get-Date)":Task is completed."
            }
        }
        Until ($VMtaskstatus -eq 100)
        $VMinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms" -debug $debug
        $VMUUID = ($VMinfo.entities |Where-Object {$_.name -eq $($Name)}).uuid
        Write-Host (Get-Date)":ID is $VMUUID"
        $VMNIC = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/nics" -debug $debug
        $VMMAC = ($VMNIC.entities |Where-Object {$_.is_connected -eq "True"}).mac_address
        # Adding the VM to the MDT database
        New-MDTComputer -assettag $Name -macAddress $VMMAC -settings @{SkipWizard="YES"; TaskSequenceID="$TaskSequenceID"; ComputerName="$Name"; OSDComputerName="$Name"; SkipComputerName="YES"; SkipTaskSequence="YES" }
        Write-Host (Get-Date)":Adding $Name to the MDT Database" 
        Write-Host (Get-Date)":Power on VM."
        Set-VMpowerV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON" -debug $debug

        # Preparing MDT phase, monitoring the DB to make sure the VM deployment is finished
        Write-Host (Get-Date)":Waiting for the VM to PXE boot to the MDT share and start the task sequence"
        Start-Sleep 180 
        If (!(Test-Path MDT:)) { New-PSDrive -Name MDT -Root $deploymentShare -PSProvider Microsoft.BDD.PSSNAPIN\MDTPROVIDER | Out-Null }                
        Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $Name } | Out-Null
        Write-Host (Get-Date)":Getting MDT Monitoring Data"
        
        # Write-Host "Waiting for task sequence to complete."
        Write-Host (Get-Date)":Waiting for task sequence to complete"
        Do {
            $InProgress = Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $Name }
            If ( $InProgress.PercentComplete -lt 100 ) {
                If ( $InProgress.StepName.Length -eq 0 ) { $StatusText = "Waiting for update" }
                Start-Sleep -Seconds 5
            }
            Else {
                Write-Progress -Activity "Task sequence complete" -PercentComplete 100
            }
        }
        Until ($InProgress.CurrentStep -eq $InProgress.TotalSteps)
        Write-Host (Get-Date)":Task Sequence completed"
        
        #Remove MDT computer
        Try {
            Connect-MDTDatabase -sqlServer $MDTsqlserver -instance $MDTSQLinstance -database $MDTdatabase | Out-Null
            Write-Host (Get-Date)":Connecting to the MDT Database"
        }
        Catch {
            Write-Host (Get-Date)":Couldn't connect to the MDT Database"
        }
        Try {
            $MDTComputer = Get-MDT -assettag $Name
            Remove-MDTComputer -id $MDTComputer.ID | Out-Null
            Write-Host (Get-Date)":Remove computer from MDT database."
        }
        Catch {
            Write-Host (Get-Date)":Couldn't remove the computer from MDT database."
        }
        Write-Host (Get-Date)":Wait for VM to power off." 
        Do {
            $VMinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)" -debug $debug
            $VMpower = $VMinfo.power_state
            If ( $VMpower -ne "OFF" ) {
                Start-Sleep -Seconds 5
            }
            Else {
                Write-Host (Get-Date)":VM is $VMpower."
            }
        }
        Until ($VMpower -eq "OFF")
        Write-Host (Get-Date)": Eject CD-ROM from VM."
        Remove-CDROMV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -VMUUID "$($VMUUID)" -debug $debug
        Start-Sleep 5
        Write-Host (Get-Date)":Power on VM."
        Set-VMpowerV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON" -debug $debug
        Write-Host (Get-Date)":Wait for IP-address."
        Start-Sleep 10
        Do {
            $VMNIC = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/nics" -debug $debug
            $VMip = ($VMNIC.entities |Where-Object {$_.is_connected -eq "True"}).ip_address
            If ([string]::IsNullOrEmpty($VMip) -Or $VMip.StartsWith("169.254")) {
                Start-Sleep -Seconds 5
            }
            Else {
                Write-Host (Get-Date)":IP address is $VMip."
            }
        }
        Until (![string]::IsNullOrEmpty($VMip) -And $VMip -notlike "169.254*")
        Start-Sleep 20
        # Start ansible
        Write-Host (Get-Date)":Start Ansible playbook."
        $command = "ansible-playbook -i $($VMip), $($ansiblepath)$($ansibleplaybook) --extra-vars `"winos_path=$($WinVerBuild)`""
        $password = ConvertTo-SecureString "$ansiblepassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName "$($ansiblehost)" -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
        $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200).output
        Remove-SSHSession -Name $Session | Out-Null 
        Write-Host (Get-Date)": Ansible playbook is finished."
        Write-Host (Get-Date)":Power off VM."                
        Set-VMpowerV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/set_power_state" -Action "ACPI_SHUTDOWN" -debug $debug
        Write-Host (Get-Date)":Wait for VM to power off." 
        Do {
            $VMinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)" -debug $debug
            $VMpower = $VMinfo.power_state
            If ( $VMpower -ne "OFF" ) {
                Start-Sleep -Seconds 5
            }
            Else {
                Write-Host (Get-Date)":VM is $VMpower."
            }
        }
        Until ($VMpower -eq "OFF")
        Start-Sleep 5
        Write-Host (Get-Date)":Finished installation." 
        Write-Host (Get-Date)":Create snapshot."
        New-VMSnapV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -VMUUID "$($VMUUID)" -Snapname "$($Name)_Snap_Optimized" -debug $debug
        Write-Host (Get-Date)":Snapshot created."
        Update-Slack -VMName $Name -Slack $Slack
    }
    Catch {
        Write-Host (Get-Date)":Can't create the VM"
    }
}

