function Reset-RDPHosts {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][array]$Hosts,
        [Parameter(Mandatory = $true)][int]$MaxIterations,
        [Parameter(Mandatory = $true)][int]$SleepTime,
        [Parameter(Mandatory = $false)][switch]$DownloadDelProf,
        [Parameter(Mandatory = $false)][switch]$ClearProfiles,
        [Parameter(Mandatory = $false)][string]$UserName,
        [Parameter(Mandatory = $false)][string]$Password
    )

    $TotalErrorCount = 0

    $user = $UserName
    $pass = ConvertTo-SecureString $Password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($user, $pass)

    $Reboot_Success = @()

    # Reboot Each VM in Host List
    foreach ($RDP_Host in $Hosts) {
        try {
            Write-Log -Message "Attempting to reboot RDP Host: $($RDP_Host)" -Level Info
            #Restart-Computer -ComputerName $RDP_Host -Force -Credential $credential -ErrorAction Stop
            Restart-Computer -ComputerName (Resolve-DnsName -Name $RDP_Host -Type PTR).NameHost -Force -Credential $credential -ErrorAction Stop
            Write-Log -Message "Successfully rebooted RDP Host: $($RDP_Host)" -Level Info
            $Reboot_Success += $RDP_Host
        }
        catch {
            Write-Log -Message "Failed to reboot RDP Host: $($RDP_Host)" -Level Error
            Write-Log -Message $_ -Level Error
            $TotalErrorCount ++
        }
    }
    # Confirm the VM is back by an RDP Port check
    $Host_Validation_Iteration_Count = $MaxIterations # Try 4 times
    $Host_Validation_Wait_Time = $SleepTime # How long to wait between attempts
    $Hosts_Alive = @() # Open an array for Validated hosts

    if ($TotalErrorCount -lt 1) {
        Write-Log -Message "Waiting for 60 seconds for hosts to reboot" -Level Info
        Start-Sleep 60

        #Validate Hosts are back online
        foreach ($RDP_Host in $Hosts) {
        
            $Host_Validation_Iteration = 1
    
            while (($Hosts_Alive -notcontains $RDP_Host)) {
                if ($Host_Validation_Iteration -eq ($Host_Validation_Iteration_Count + 1)) {
                    Write-Log -Message "Not all machines responded after the reboot" -Level Error
                    $TotalErrorCount ++
                }
                Write-Log -Message "Testing connectivity to RDP Host $($RDP_Host) after reboot. Attempt: $($Host_Validation_Iteration) of $($Host_Validation_Iteration_Count)" -Level Info
                $Host_Alive = Test-NetConnection -ComputerName (Resolve-DnsName -Name $RDP_Host -Type PTR).NameHost -Port 3389 -ErrorVariable netError -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                if ($Host_Alive.TcpTestSucceeded -eq $true) {
                    $Hosts_Alive += $RDP_Host
                    Write-Log -Message "Successfully connected to RDP Host $($RDP_Host) after reboot" -Level Info
                }
                else {
                    Write-Log -Message "Failed to connect to RDP Host $($RDP_Host) after reboot. Waiting for $($Host_Validation_Wait_Time) seconds " -Level Warn
                    Start-Sleep $Host_Validation_Wait_Time
                    $Host_Validation_Iteration ++
                }
            }
        }

        if ($TotalErrorCount -lt 1) {
            Write-Log -Message "All Hosts successfully connected after reboot" -Level Info

            #Now proceed with DelProf
            # Delprof Profiles?
            if ($ClearProfiles.IsPresent) {
                foreach ($RDP_Host in $Hosts) {
                    try {
                        Write-Log -Message "Cleaning Local Profiles after Reboot for RDP Host: $($RDP_Host)" -Level Info
                        if ($DownloadDelProf.IsPresent) {
                            try {
                                Invoke-Command -ComputerName (Resolve-DnsName -Name $RDP_Host -Type PTR).NameHost -ScriptBlock {
                                    $extractPath = "c:\tools\delprof"
                                    if (Test-Path "$extractPath\Delprof2 1.6.0\DelProf2.exe") {
                                        Set-Location -Path "$extractPath\Delprof2 1.6.0"
                                        .\delprof2.exe /ed:admin /u /q
                                    }
                                    else {
                                        $null = New-Item -Path $extractPath -ItemType Directory -Force
                                        $url = "https://helgeklein.com/downloads/DelProf2/current/Delprof2%201.6.0.zip"
                                        $zipFile = "$extractPath\DelProf2.zip"
                                        Invoke-WebRequest -Uri $url -OutFile $zipFile
                                        Expand-Archive -Path $zipFile -DestinationPath $extractPath
                                        Set-Location -Path "$extractPath\Delprof2 1.6.0"
                                        .\delprof2.exe /u /q
                                    }
                                } -Credential $credential -ErrorAction Stop
                            }
                            catch {
                                Write-Log -Message $_ -Level Error
                                $TotalErrorCount ++
                            }

                        }
                        else {
                            try {
                                Invoke-Command -ComputerName (Resolve-DnsName -Name $RDP_Host -Type PTR).NameHost -ScriptBlock { 
                                    Set-Location -Path "c:\tools\delprof\Delprof2 1.6.0"
                                    .\delprof2.exe /u /q 
                                } -Credential $credential -ErrorAction Stop
                            }
                            catch {
                                Write-Log -Message $_ -Level Error
                                $TotalErrorCount ++
                            }
                        }
                        Write-Log -Message "Successfully Cleaned Profiles for RDP Host: $($RDP_Host)" -Level Info
                    }
                    catch {
                        Write-Log -Message "Failed to Clean Profiles for RDP Host: $($RDP_Host): Error: $_" -Level Error
                        Write-Log -Message $_ -Level Error
                        $TotalErrorCount ++
                    }
                }
            }

        }
        else {
            Write-Log -Message "Not all Hosts connected after reboot. Not Proceeding" -Level Warn
            Break
        }
    }
    else {
        Write-Log -Message "Not all reboots were successful. Not Proceeding" -Level Warn
        Break
    }
    
    if ($TotalErrorCount -gt 0) {
        $Validated = $false
    }
    else {
        $Validated = $true
    }
    
    return $Validated
}
