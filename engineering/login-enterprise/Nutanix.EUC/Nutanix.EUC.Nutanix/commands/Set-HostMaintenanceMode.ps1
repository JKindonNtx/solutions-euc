function Set-HostMaintenanceMode {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$Node,
        [Parameter(Mandatory = $true)][ValidateSet("Enabled","Disabled")][string]$State,
        [Parameter(Mandatory = $true)]$Session,
        [Parameter(Mandatory = $true)]$HostCount
    )
    
    if ($State -eq "Enabled") {
        Write-Log -Message "This is a $($HostCount) Node Test. Entering Maintenance Mode for Host: $($Node)" -Level Info
        $command = "~/bin/acli host.enter_maintenance_mode $Node wait=false"
        try {
            $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200 -ErrorAction Stop).output
        }
        catch {
            Write-Log -Message "Failed to Set Maintenance Mode on Host: $($Node)" -Level Warn
            Write-Log -Message $_ -Level Warn
            Break
        }
        Write-Log -Message "Sleeping for 20 seconds" -Level Info
        Start-Sleep -Seconds 20
        
    }
    elseif ($State -eq "Disabled") {
        Write-Log -Message "Ensuring Maintenance mode disabled for Host: $($Node)" -Level Info
        $command = "~/bin/acli host.exit_maintenance_mode $Node"
        try {
            $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200 -ErrorAction Stop).output
        }
        catch {
            Write-Log -Message "Failed to unset Maintenance Mode on Host: $($Node)" -Level Warn
            Write-Log -Message $_ -Level Warn
            Break
        }
        Write-Log -Message "Sleeping for 20 seconds" -Level Info
        Start-Sleep -Seconds 20
    }

    return $true # Do this, or just terminate above - if we do this, we need to add error logic into Set-NTNXHostAlignment Function
}