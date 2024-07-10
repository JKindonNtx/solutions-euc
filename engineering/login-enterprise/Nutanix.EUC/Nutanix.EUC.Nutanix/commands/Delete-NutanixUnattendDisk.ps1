function Delete-NutanixUnattendDisk {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$DiskUuid
    )

    try {
        if ($TargetCVM) {
            $VM = Invoke-PublicApiMethodNTNXv2 -Method "DELETE" -Path "disks/$($DiskUuid)?force=true" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -ErrorAction Stop
        }
        else {
            $VM = Invoke-PublicApiMethodNTNXv2 -Method "DELETE" -Path "disks/$($DiskUuid)?force=true" -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        #Break
    }
    
    return $VM
}