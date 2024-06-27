function Get-OmnissaVMsIP {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VmUuid,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword
    )

    try {
        if ($TargetCVM) {
            $NTNXIP = Invoke-PublicApiMethodNTNX -Method "GET" -Path "vms/$($VmUuid)/?include_vm_disk_config=false&include_vm_nic_config=true" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -ErrorAction Stop
        }
        else {
            $NTNXIP = Invoke-PublicApiMethodNTNX -Method "GET" -Path "vms/$($VmUuid)/?include_vm_disk_config=false&include_vm_nic_config=true" -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        #Break
    }
    
    return $NTNXIP
}

