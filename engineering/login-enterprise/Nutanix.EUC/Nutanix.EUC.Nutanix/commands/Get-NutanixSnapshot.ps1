function Get-NutanixSnapshot {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][String]$SnapshotName,
        [Parameter(Mandatory = $false)][String]$VM
    )

    Write-Log -Message "Validating Snapshot $($SnapshotName) exists on Target Cluster $($VSI_Target_CVM)" -Level Info

    if ($NTNXInfra.Testinfra.HypervisorType -eq "AHV") {

        $All_Snapshots = Invoke-PublicApiMethodNTNX -Method "GET" -Path "snapshots"
    
        $snap_validated = $All_Snapshots.entities | Where-Object {$_.snapshot_name -eq $SnapshotName}
    
        if ($null -ne $snap_validated) {
            Write-Log -Message "Snapshot $($SnapshotName) Validated" -Level Info
        }
        else {
            Write-Log -Message "Snapshot $($SnapshotName) does not exist. Validation Failed." -Level Warn
            Break #Temporary! Replace with #Exit 1
        }
    }
    if ($NTNXInfra.Testinfra.HypervisorType -eq "ESXi") {
        # TBD
        Get-Snapshot -VM $VM -Name $SnapshotName -Server $VSI_Target_vCenterServer
    }
}
