function Set-NTNXVmClone {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VmUuid,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Body
    )

    try {
        if ($TargetCVM) {
            $NTNXVmClone = Invoke-PublicApiMethodNTNX -Method "POST" -Path "vms/$($VmUuid)/clone" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -Body $Body -ErrorAction Stop
        }
        else {
            $NTNXVmClone = Invoke-PublicApiMethodNTNX -Method "POST" -Path "vms/$($VmUuid)/clone" -Body $Body -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        #Break
    }
    
    return $NTNXVmClone
}