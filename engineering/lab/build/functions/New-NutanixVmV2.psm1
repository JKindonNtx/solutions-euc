<#
.Synopsis
    Create a new VM on a Nutanix Cluster
.DESCRIPTION
    Create a new VM on a Nutanix Cluster
.EXAMPLE
    New-NutanixVmV2 -Name "VM" -VMTimeZone "GMT" - StorageUUID "{UUID}" -ISOUUID "{UUID}" -VLANUUID "{UUID}"
.INPUTS
    TaskSequenceID - The Task Sequence to update
    Name - The VM Name
    VMtimezone - The VM Timezone
    StorageUUID - The Storage UUID
    ISOUUID - The ISO UUID
    VLANUUID - The VLAN UUID
.NOTES
    Sven Huisman        29/11/2022          v1.0.0              Function Creation
    David Brett         28/11/2022          v1.0.0              Update Error Handling
.FUNCTIONALITY
    Create a new VM on a Nutanix Cluster
#>

function New-NutanixVmV2
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                  PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [System.object[]]
        $JSON,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $Name,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $VMtimezone,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $StorageUUID,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $ISOUUID,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $VLANUUID
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'New-NutanixVmV2'" 
    }

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

        $credPair = "$($JSON.Cluster.UserName):$($JSON.Cluster.password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($JSON.Cluster.ip):9440/PrismGateway/services/rest/v2.0/vms"

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

        try {
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
        catch {
            Start-Sleep 10
            Write-Host (Get-Date) ": Going once"
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'New-NutanixVmV2'" 
        Return $task
    }
}