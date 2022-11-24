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
        $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
    }
    catch {
        Start-Sleep 10
        Write-Host (Get-Date) ": Going once"
        $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
    }

    Return $task
}