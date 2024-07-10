function Get-NTNXVM {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VmUuid
    )

    try {
        if ($TargetCVM) {
            $NTNXVM = Invoke-PublicApiMethodNTNX -Method "GET" -Path "vms/$($VmUuid)?include_vm_disk_config=true" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -ErrorAction Stop
        }
        else {
            $NTNXVM = Invoke-PublicApiMethodNTNX -Method "GET" -Path "vms/$($VmUuid)?include_vm_disk_config=true" -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        #Break
    }
    
    return $NTNXVM
}