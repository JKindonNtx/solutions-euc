function Get-NTNXVMs {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword
    )

    try {
        if ($TargetCVM) {
            $NTNXVMS = Invoke-PublicApiMethodNTNX -Method "GET" -Path "vms" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -ErrorAction Stop
        }
        else {
            $NTNXVMS = Invoke-PublicApiMethodNTNX -Method "GET" -Path "vms" -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        #Break
    }
    
    return $NTNXVMS.entities
}