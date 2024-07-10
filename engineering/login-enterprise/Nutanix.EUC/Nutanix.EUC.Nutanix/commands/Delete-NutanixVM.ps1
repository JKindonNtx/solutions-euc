function Delete-NutanixVM {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VmUuid
    )

    try {
        if ($TargetCVM) {
            $VM = Invoke-PublicApiMethodNTNX -Method "DELETE" -Path "/vms/$($VmUuid)/?delete_snapshots=true" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -ErrorAction Stop
        }
        else {
            $VM = Invoke-PublicApiMethodNTNX -Method "DELETE" -Path "/vms/$($VmUuid)/?delete_snapshots=true" -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        #Break
    }
    
    return $VM
}