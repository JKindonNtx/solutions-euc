function Start-ServerMonitoring {
    <#
        .SYNOPSIS
        Starts or stops remove telegraf services on a list of machines
    
        .DESCRIPTION
        Starts or stops remove telegraf services on a list of machines

        .EXAMPLE
        Start-ServerMonitoring -ServersToMonitor "Server1","Server2" -Mode StartMonitoring -ServiceName "Telegraf"

        .EXAMPLE
        Start-ServerMonitoring -ServersToMonitor "Server1","Server2" -Mode StopMonitoring -ServiceName "Telegraf"

    #>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][Array]$ServersToMonitor,
        [Parameter(Mandatory = $true)][ValidateSet("StartMonitoring", "StopMonitoring")][String]$Mode,
        [Parameter(Mandatory = $true)][String]$ServiceName
    )

    foreach ($Server in $ServersToMonitor) {
        if ($Mode -eq "StartMonitoring" ) {
            try {
                $Service = Invoke-Command -ComputerName $Server -ScriptBlock { param($ServiceName) Get-Service | Where-Object {$_.Name -eq $($ServiceName)} } -ArgumentList $ServiceName -ErrorAction Stop
                if ($null -ne $Service) {
                    if ($Service.Status -ne "Running") {
                        Write-Log -Message "Starting service $($Service.Name) on $($Server)" -Level Info
                        try {
                            Invoke-Command -ComputerName $Server -ScriptBlock { param($ServiceName) Get-Service | Where-Object {$_.Name -eq $($ServiceName)} | Start-Service -ErrorAction Stop } -ArgumentList $ServiceName -ErrorAction Stop
                            Write-Log -Message "Service $($Service.Name) started on $($Server)" -Level Info
                        }
                        catch {
                            Write-Log -Message $_ -Level Error
                        }
                    }
                    else {
                        Write-Log -Message "Service $($Service.Name) is $($Service.Status) on $($Server)" -Level Info
                    }
                }
                else {
                    Write-Log -Message "Failed to get $($ServiceName) service on $($Server)" -Level Error
                    Write-Log -Message $_ -Level Error
                }
            }
            catch {
                Write-Log -Message "Failed to get $($ServiceName) service on $($Server)" -Level Error
            }
        }
        if ($Mode -eq "StopMonitoring") {
            try {
                $Service = Invoke-Command -ComputerName $Server -ScriptBlock { param($ServiceName) Get-Service | Where-Object {$_.Name -eq $($ServiceName)} } -ArgumentList $ServiceName -ErrorAction Stop
                if ($null -ne $Service) {
                    Write-Log -Message "Service $($ServiceName) is $($Service.Status) on $($Server)" -Level Info
                    if ($Service.Status -eq "Running") {
                        Write-Log -Message "Stopping $($ServiceName) service on $($Server)" -Level Info
                        try {
                            Invoke-Command -ComputerName $Server -ScriptBlock { param($ServiceName) Get-Service | Where-Object {$_.Name -eq $($ServiceName)} | Stop-Service -ErrorAction Stop } -ArgumentList $ServiceName -ErrorAction Stop
                            Write-Log -Message "Service $($ServiceName) stopped on $($Server)" -Level Info
                        }
                        catch {
                            Write-Log -Message "Failed to stop service $($Service.Name) on Server $($Server)" -Level Error
                            Write-Log -Message $_ -Level Error
                        }
                    }
                }
                else {
                    Write-Log -Message "Failed to get $($ServiceName) service on $($Server)" -Level Error
                    Write-Log -Message $_ -Level Error
                }  
            }
            catch {
                Write-Log -Message "Failed to get $($ServiceName) service on $($Server)" -Level Error
                Write-Log -Message $_ -Level Error
            }
        }
    }
}