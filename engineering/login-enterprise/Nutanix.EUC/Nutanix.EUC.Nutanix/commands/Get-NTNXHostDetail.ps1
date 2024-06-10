function Get-NTNXHostDetail {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword
    )

    try {
        if ($TargetCVM) {
            $NTNXHosts = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -ErrorAction Stop
        }
        else {
            $NTNXHosts = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts" -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }
    
    return $NTNXHosts.entities
}