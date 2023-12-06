function Get-NutanixSnapshot {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][String]$SnapshotName,
        [Parameter(Mandatory = $false)][String]$VM,
        [Parameter(Mandatory = $false)][String]$HypervisorType,
        [Parameter(Mandatory = $false)][String]$HostingConnection,
        [Parameter(Mandatory = $false)][String]$Type,
        [Parameter(Mandatory = $false)][String]$DDC
    )

    Write-Log -Message "Validating Snapshot $($SnapshotName) exists on Target Cluster $($VSI_Target_CVM)" -Level Info

    if ($HypervisorType -eq "AHV") {
        #Validate at the AHV Level
        $All_Snapshots = Invoke-PublicApiMethodNTNX -Method "GET" -Path "snapshots"
    
        $snap_validated = $All_Snapshots.entities | Where-Object {$_.snapshot_name -eq $SnapshotName}
    
    }

    if (($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") -and $HypervisorType -eq "ESXi") {
        #Switch to a Citrix hosting connection snapshot based validation
        try {
            $snap_validated = Invoke-Command -ComputerName $DDC -ScriptBlock { param($HostingConnection,$VM) asnp citrix*; Test-Path XDHyp:\HostingUnits\$HostingConnection\$VM} -ArgumentList $HostingConnection,$VM -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Failed to get snapshot details from Citrix Hosting Connection $($HostingConnection)" -Level Error
            Write-Log -Message $_ -Level Error
            Exit 1
        }
    }

    if ($Type -eq "Horizon" -and $HypervisorType -eq "ESXi") {
        #Validate at the VC level
        try {
            $temp_vsphere_connection = Connect-VIServer -Server $VSI_Target_vCenterServer -User $VSI_Target_vCenterUsername -Password $VSI_Target_vCenterPassword -Force -ErrorAction Stop
            $snap_validated = Get-Snapshot -VM $VM -Name $SnapshotName -Server $temp_vsphere_connection -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Failed to get snapshot details from vcenter $($VSI_Target_vCenterServer)" -Level Error
            Write-Log -Message $_ -Level Error
            Exit 1
        }
    }

    if ($null -ne $snap_validated) {
        Write-Log -Message "Snapshot $($SnapshotName) validated" -Level Info
    }
    else {
        Write-Log -Message "Snapshot $($SnapshotName) does not exist. Validation Failed." -Level Warn
        Exit 1
    }
}