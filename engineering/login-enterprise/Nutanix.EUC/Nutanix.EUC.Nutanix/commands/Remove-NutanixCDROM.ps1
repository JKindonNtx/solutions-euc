function Remove-NutanixCDROM {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VmUuid,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword
    )

    # Create Payload
        $Payload = "{ `
            ""vm_disks"":[ `
                { `
                    ""disk_address"": `
                    { `
                        ""device_bus"":""sata"", `
                        ""device_index"":3 `
                    } `
                }] `
        }"

    try {
        if ($TargetCVM) {
            $task = Invoke-PublicApiMethodNTNX -Method "POST" -Path "vms/$($VmUuid)/disks/detach" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -Body $Payload -ErrorAction Stop
        }
        else {
            $task = Invoke-PublicApiMethodNTNX -Method "POST" -Path "vms/$($VmUuid)/disks/detach" -Body $Payload -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        #Break
    }
    
    return $task

} # Remove-NutanixCDROM