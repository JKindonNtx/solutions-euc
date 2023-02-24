function New-NutanixVM {
<#
    .SYNOPSIS
    Creates a Virtual Machine.

    .DESCRIPTION
    This function will create a new Virtual Machine on a Nutanix Cluster.
    
    .PARAMETER JSON
    The LabConfig JSON File

    .PARAMETER Name
    The user name to use for connection

    .PARAMETER VMtimezone
    The password for the connection

    .PARAMETER StorageUUID
    The VLAN Number

    .PARAMETER ISOUUID
    The VLAN Description

    .PARAMETER VLANUUID
    The VLAN Description

    .EXAMPLE
    PS> New-NutanixVM -JSON $JSON -Name "VM" -VMTimeZone "GMT" - StorageUUID "{UUID}" -ISOUUID "{UUID}" -VLANUUID "{UUID}" -UserName $UserName

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    Task variable containing the output of the Invoke-RestMethod command run

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/New-NutanixVM.md

    .NOTES
    Author          Version         Date            Detail
    Sven Huisman    v1.0.0          28/11/2022      Function creation
    David Brett     v1.0.1          06/12/2022      Updated Parameter definition
                                                    Updated function header to include MD help file
                                                    Changed Write-Host from hardcoded function name to $($PSCmdlet.MyInvocation.MyCommand.Name)

#>


    [CmdletBinding()]

    Param
    (
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [System.object[]]$JSON,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$Name,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$UserName,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$VMtimezone,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$StorageUUID,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$ISOUUID,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$VLANUUID
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":Name: $Name" 
        Write-Host (Get-Date)":VMtimezone: $VMtimezone" 
        Write-Host (Get-Date)":StorageUUID: $StorageUUID" 
        Write-Host (Get-Date)":ISOUUID: $ISOUUID" 
        Write-Host (Get-Date)":VLANUUID: $VLANUUID" 

        # Gather VM Config Details
        $Disksize = [int64]"$($JSON.VM.Disksize)"*1gb

        if ($($JSON.VM.vTPM)) {
            $Machinetype = "Q35"
            $vTPM = "true"
        } elseif ($($JSON.VM.Secureboot)) {
                $Machinetype = "Q35"
                $vTPM = "false"
            } elseif ($($JSON.VM.UEFI)) {
                $Machinetype = "PC"
                $vTPM = "false"
            } else {
            $Machinetype = "PC"
            $vTPM = "false"
        }

        If ($($JSON.VM.UEFI)){
            [string] $UEFI = "true"
        }
        Else {
            [string] $UEFI = "false"
        }

        If ($($JSON.VM.Secureboot)){
            [string] $Secureboot = "true"
        }
        Else {
            [string] $Secureboot = "false"
        }

        $VMDescription = "$(Get-Date -DisplayHint Date) $UserName"

        $credPair = "$($UserName):$($JSON.Cluster.password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($JSON.Cluster.ip):9440/PrismGateway/services/rest/v2.0/vms"

        # Create Payload
        $Payload = "{ `
        ""boot"": { `
          ""boot_device_order"": [ `
            ""CDROM"", `
            ""DISK"", `
            ""NIC""
          ], `
          ""secure_boot"": " + $Secureboot + ", `
          ""uefi_boot"": " + $UEFI + " `
        }, `
        ""description"": """ + $VMDescription + """, `
        ""machine_type"": """ + $Machinetype + """, `
        ""memory_mb"": " + $($JSON.VM.vRAM) + ", `
        ""name"": """ + $Name + """, `
        ""num_cores_per_vcpu"": " + $($JSON.VM.CPUcores) + ", `
        ""num_vcpus"": " + $($JSON.VM.CPUsockets) + ", `
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

        # Invoke Rest Method
        try {
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
        catch {
            Start-Sleep 10
            Write-Host (Get-Date) ": Going once"
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $task
    } # End

} # New-NutanixVM