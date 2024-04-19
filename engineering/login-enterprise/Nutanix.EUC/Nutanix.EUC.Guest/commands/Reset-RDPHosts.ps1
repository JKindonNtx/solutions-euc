function Reset-RDPHosts {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][array]$Hosts,
        [Parameter(Mandatory = $true)][int]$MaxIterations,
        [Parameter(Mandatory = $true)][int]$SleepTime,
        [Parameter(Mandatory = $false)][switch]$RebootHosts,
        [Parameter(Mandatory = $false)][switch]$ClearProfiles,
        [Parameter(Mandatory = $true)][string]$UserName,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $true)][string]$DomainName
    )

    $TotalErrorCount = 0

    $user = $UserName
    $pass = ConvertTo-SecureString $Password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($user, $pass)

    if ($RebootHosts.IsPresent) {
    
        $Reboot_Success = @()

        # Reboot Each VM in Host List
        foreach ($RDP_Host in $Hosts) {
            $RDP_Host = ($RDP_Host + "." + $DomainName)
            try {
                Write-Log -Message "Attempting to reboot RDP Host: $($RDP_Host)" -Level Info
                if ($IsLinux){
                    Invoke-Command -ScriptBlock {Restart-Computer -force} -ComputerName $RDP_Host -Credential $credential -Authentication Negotiate -ErrorAction Stop -AsJob
                }
                elseif ($IsWindows){
                    Restart-Computer -ComputerName $RDP_Host -Force -Credential $credential -ErrorAction Stop
                }
                
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
        $Host_Validation_Iteration_Count = $MaxIterations # Try x number of times to connect after reboot
        $Host_Validation_Wait_Time = $SleepTime # How long to wait between attempts
        $Hosts_Alive = @() # Open an array for Validated hosts

        if ($TotalErrorCount -lt 1) {
            Write-Log -Message "Waiting for 60 seconds for hosts to reboot" -Level Info
            Start-Sleep 60

            #Validate Hosts are back online
            foreach ($RDP_Host in $Hosts) {
                $RDP_Host = ($RDP_Host + "." + $DomainName)

                $Host_Validation_Iteration = 1
        
                while (($Hosts_Alive -notcontains $RDP_Host)) {
                    if ($Host_Validation_Iteration -eq ($Host_Validation_Iteration_Count + 1)) {
                        Write-Log -Message "Not all machines responded after the reboot" -Level Error
                        $TotalErrorCount ++
                    }
                    Write-Log -Message "Testing connectivity to RDP Host $($RDP_Host) after reboot. Attempt: $($Host_Validation_Iteration) of $($Host_Validation_Iteration_Count)" -Level Info
                    if ($IsLinux){
                        If (Test-Connection -ComputerName $RDP_Host -TcpPort 3389 -quiet) {
                            $Hosts_Alive += $RDP_Host
                            Write-Log -Message "Successfully connected to RDP Host $($RDP_Host) after reboot" -Level Info
                        }
                        else {
                            Write-Log -Message "Failed to connect to RDP Host $($RDP_Host) after reboot. Waiting for $($Host_Validation_Wait_Time) seconds " -Level Warn
                            Start-Sleep $Host_Validation_Wait_Time
                            $Host_Validation_Iteration ++
                        }
                    }
                    elseif ($IsWindows){
                        $Host_Alive = Test-NetConnection -ComputerName $RDP_Host -Port 3389 -ErrorVariable netError -WarningAction SilentlyContinue -InformationAction SilentlyContinue
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
            }

            if ($TotalErrorCount -lt 1) {
                Write-Log -Message "All Hosts successfully connected after reboot" -Level Info

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
    }

    #Now proceed with DelProf
    if ($ClearProfiles.IsPresent) {
        foreach ($RDP_Host in $Hosts) {
            $RDP_Host = ($RDP_Host + "." + $DomainName)
            try {
                Write-Log -Message "Cleaning Local Profiles after Reboot for RDP Host: $($RDP_Host)" -Level Info
                if ($IsLinux){
                    try {
                        Invoke-Command -ScriptBlock {
                            param($Cred)
                            $DelProfLocation = "c:\tools\delprof\"
                            $DelProfSource = "\\ws-files\automation\Apps\Other\Delprof2"
                            $AppExe = "Delprof2.exe"
                            $Arguments = "/id:vsile* /u /q /i"
                            if (Test-Path ($DelProfLocation + "\" + $AppExe)) {
                                Start-Process -FilePath "$DelProfLocation\$AppExe" -ArgumentList $Arguments -NoNewWindow
                            } 
                            else {
                                New-Item -Path $DelProfLocation -Type Directory -Force | Out-Null
                                New-PSDrive -Name "W" -PSProvider "FileSystem" -Root $DelProfSource -Credential $Cred
                                Copy-Item -Path "W:\$AppExe" -Destination $DelProfLocation -Force
                                Remove-PSDrive -Name "W" -Force
                                Start-Process -FilePath "$DelProfLocation\$AppExe" -ArgumentList $Arguments -NoNewWindow
                            }
                        } -ComputerName $RDP_Host -Credential $credential -Authentication Negotiate -ErrorAction Stop -ArgumentList $Credential
                    }
                    catch {
                        Write-Log -Message $_ -Level Error
                        $TotalErrorCount ++
                    }
                }
                elseif ($IsWindows){
                    try {
                        Invoke-Command -ComputerName $RDP_Host -ScriptBlock {
                            param($Cred)
                            $DelProfLocation = "c:\tools\delprof\"
                            $DelProfSource = "\\ws-files\automation\Apps\Other\Delprof2"
                            $AppExe = "Delprof2.exe"
                            $Arguments = "/id:vsile* /u /q /i"
                            if (Test-Path ($DelProfLocation + "\" + $AppExe)) {
                                Start-Process -FilePath "$DelProfLocation\$AppExe" -ArgumentList $Arguments -NoNewWindow
                            } 
                            else {
                                New-Item -Path $DelProfLocation -Type Directory -Force | Out-Null
                                New-PSDrive -Name "W" -PSProvider "FileSystem" -Root $DelProfSource -Credential $Cred
                                Copy-Item -Path "W:\$AppExe" -Destination $DelProfLocation -Force
                                Remove-PSDrive -Name "W" -Force
                                Start-Process -FilePath "$DelProfLocation\$AppExe" -ArgumentList $Arguments -NoNewWindow
                            } 
                        } -Credential $credential -ErrorAction Stop -ArgumentList $Credential

                        Write-Log -Message "Successfully Cleaned Profiles for RDP Host: $($RDP_Host)" -Level Info
                    }
                    catch {
                        Write-Log -Message $_ -Level Error
                        $TotalErrorCount ++
                    }
                }
                
            }
            catch {
                Write-Log -Message "Failed to Clean Profiles for RDP Host: $($RDP_Host): Error: $_" -Level Error
                Write-Log -Message $_ -Level Error
                $TotalErrorCount ++
            }
        }
    }
    
    if ($TotalErrorCount -gt 0) {
        $Validated = $false
    }
    else {
        $Validated = $true
    }
    
    return $Validated
}
