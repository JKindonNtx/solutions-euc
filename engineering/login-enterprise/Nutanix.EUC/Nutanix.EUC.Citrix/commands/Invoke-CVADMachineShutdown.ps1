Function Invoke-CVADMachineShutdown {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$DDC,
        [Parameter(Mandatory = $true)][string]$CatalogName,
        [Parameter(Mandatory = $true)][int32]$MaxRecordCount
    )
    
    $MachineList = try {
        Get-BrokerMachine -AdminAddress $DDC -CatalogName $CatalogName -MaxRecordCount $MaxRecordCount -InMaintenanceMode $False -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Warn
        Continue
    }

    $MachineList = $MachineList | Where-Object {$_.PowerState -eq "On"}
    $MachineListCount = ($MachineList | Measure-Object).count

    if ($MachineListCount -gt 0) {
        Write-Log -Message "Powering down $($MachineListCount) Machines after final run" -Level Info
        foreach ($Machine in $MachineList) {
            try {
                $null = New-BrokerHostingPowerAction -AdminAddress $DDC -Action Shutdown -MachineName $Machine.MachineName -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Warn
            }
        }

        Write-Log -Message "Waiting 120 seconds for machines to power down after final run" -Level Info
        Start-Sleep -Seconds 120

        $MachineListRemainingOn = Get-BrokerMachine -AdminAddress $DDC -CatalogName $CatalogName -MaxRecordCount $MaxRecordCount -InMaintenanceMode $False -ErrorAction Stop
        $MachineListRemainingOn = $MachineListRemainingOn | Where-Object {$_.PowerState -eq "On" -or $_.PowerState -eq 'TurningOff'}
        $MachineListRemainingOnCount = ($MachineListRemainingOn | Measure-Object).Count

        if ($MachineListRemainingOnCount -gt 0) {
            Write-Log -Message "There are $($MachineListRemainingOnCount) machines that may not be shut down. Please check Catalog $($CatalogName)" -Level Warn
            $AllMachinesOff = $false
        } else {
            $AllMachinesOff = $true
        }

    } else {
        Write-Log -Message "All Machines are powered down" -Level Info
        $AllMachinesOff = $true
    }

    return $AllMachinesOff
}