function Set-NTNXVmSnapshot {

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
            $Snap = Invoke-PublicApiMethodNTNX -Method "POST" -Path "snapshots" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -Body $Body -ErrorAction Stop
        }
        else {
            $Snap = Invoke-PublicApiMethodNTNX -Method "POST" -Path "snapshots" -Body $Body -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        #Break
    }
    
    return $Snap
}