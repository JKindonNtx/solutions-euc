Function Get-CitrixBrokerMachineList {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$DDC,
        [Parameter(Mandatory = $true)][string]$DesktopGroupName,
        [Parameter(Mandatory = $true)][int32]$MaxRecordCount
    )

    $MachineList = try {
        Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopGroupName -MaxRecordCount $MaxRecordCount -InMaintenanceMode $False -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Warn
        Break # Replace with Exit 1
    }

    return $MachineList
}