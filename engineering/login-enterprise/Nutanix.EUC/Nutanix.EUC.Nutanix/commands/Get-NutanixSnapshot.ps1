function Get-NutanixSnapshot {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][String]$SnapshotName,
        [Parameter(Mandatory = $false)][String]$VM,
        [Parameter(Mandatory = $false)][String]$HypervisorType
    )

    Write-Log -Message "Validating Snapshot $($SnapshotName) exists on Target Cluster $($VSI_Target_CVM)" -Level Info

    if ($HypervisorType -eq "AHV") {

        $All_Snapshots = Invoke-PublicApiMethodNTNX -Method "GET" -Path "snapshots"
    
        $snap_validated = $All_Snapshots.entities | Where-Object {$_.snapshot_name -eq $SnapshotName}
    
    }
    if ($HypervisorType -eq "ESXi") {
        try {
            $temp_vsphere_connection = Connect-VIServer -Server $VSI_Target_vCenterServer -User $VSI_Target_vCenterUsername -Password $VSI_Target_vCenterPassword -Force -ErrorAction Stop
            $snap_validated = Get-Snapshot -VM $VM -Name $SnapshotName -Server $temp_vsphere_connection -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Failed to get snapshot details from vcenter $($VSI_Target_vCenterServer)" -Level Error
            Write-Log -Message $_ -Level Error
            Break #Temporary! Replace with #Exit 1
        }

        #$temp_vsphere_connection = Connect-VIServer -Server "10.47.21.61" -User "euc-solutions@vsphere.local" -Password "Nutanix/4u$" -Force
        #$snap_validated = Get-Snapshot -VM "W10-22H2-eedb" -Name "Horizon-vRAM64" -Server $temp_vsphere_connection
    }

    if ($null -ne $snap_validated) {
        Write-Log -Message "Snapshot $($SnapshotName) Validated" -Level Info
    }
    else {
        Write-Log -Message "Snapshot $($SnapshotName) does not exist. Validation Failed." -Level Warn
        Break #Temporary! Replace with #Exit 1
    }
}