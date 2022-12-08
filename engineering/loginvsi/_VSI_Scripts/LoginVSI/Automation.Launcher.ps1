function Reboot-Launchers {
    ##############################
    #.SYNOPSIS
    #Reboots the launchers
    #
    #.DESCRIPTION
    #Reboots the Login VSI launchers on the specified host
    #
    #.PARAMETER LauncherPrefix
    #Prefix for the launcher naming
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor where launchers are hosted
    #
    #.EXAMPLE
    #Reboot-Launchers -LauncherPrefix "T3L" -HostName "VAL-INFRA2"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################

    param(
        [system.array]$Launchers
        )

    Write-Host (Get-Date) ": Rebooting launchers."
    
    foreach ($launcher in $launchers) { 
        
        $try = 10
        $i = 0
        do {
            try {
                $i = $i + 1
                Write-Host (Get-Date) ": Rebooting: $launcher."
                Restart-Computer -ComputerName $launcher -Force
                $rebootLauncher = $true
            } catch {
                Write-Host (Get-Date) ": Something went wrong while rebooting launcher: $launcher."
                Write-Host (Get-Date) ": Attempt $i of $try."
                $rebootLauncher = $false
                
                if ($i -eq $try) {
                    Write-Error ": Failed to reboot launcher: $launcher."
                    break
                }
            }
        } while ($rebootLauncher -eq $false)

    }
}

function Validate-Launchers {
    ##############################
    #.SYNOPSIS
    #Validates if the launchers are running
    #
    #.DESCRIPTION
    #Validates if the Login VSI launchers are running on the specified host
    #
    #.PARAMETER LauncherPrefix
    #Prefix for the launcher naming
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor where launchers are hosted
    #
    #.EXAMPLE
    #Validate-Launchers -LauncherPrefix "T3L" -HostName "VAL-INFRA2"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################

    param(
        [string]$LauncherPrefix,
        [string]$HostName,
        [int]$LauncherAmount
    )

    Write-Host (Get-Date) ": Validating launchers."

    Import-Module -Name Hyper-V
    For ($i = 1;$i -le $LauncherAmount;$i++)
    {
        $iFormatted = "{0:d3}" -f $i
        $VMName = $LauncherPrefix + "-LS" + $iFormatted

        if ((Get-VM -ComputerName $HostName -Name $VMName).State -ne "Running") {
            Get-VM -ComputerName $HostName -Name $VMName | Start-VM -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }

        $max = 10
        $v = 0
        while ($v -ne $max) {
            try {
                $process = Invoke-Command -ComputerName $VMName -ScriptBlock {Get-Process -Name "Agent"} -ErrorAction SilentlyContinue
                if ($process) {
                    break
                }
                Start-Sleep -Seconds 10
                
            }
            catch {
                Start-Sleep -Seconds 10
            }

            $v++
        }

        if ($v -gt $max) {
            Write-Error -Message "Launcher $VMName is not running!"
        }
    }
    
}

function Configure-Launchers {
    ##############################
    #.SYNOPSIS
    #Configures the launcher based on VM's
    #
    #.DESCRIPTION
    #Validates if the Login VSI launchers are running on the specified host
    #
    #.PARAMETER Share
    #Share of Login VSI
    #
    #.PARAMETER LauncherPrefix
    #Prefix for the launcher naming
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor where launchers are hosted
    #
    #.PARAMETER LauncherAmount
    #The expected amount of configured launchers
    #
    #.PARAMETER LaunchersArray
    #Array of launcher names based from the Login VSI configuration
    #    
    #.EXAMPLE
    #Configure-Launchers -Share "\\VAL-FS03\VSIShare" -LauncherPrefix "T3" -HostName "VAL-INFRA2" -LauncherAmount 2 -LaunchersArray {"LS-001", "LS-002"}
    #
    #.NOTES
    #Initial creation of generic function
    ##############################

    param(
        [string]$Share,
        [string]$LauncherPrefix,
        [string]$HostName,
        [int]$LauncherAmount,
        [array]$LaunchersArray
    )

    Write-Host (Get-Date) ": Configuring launchers."

    if ($LaunchersArray.Count -ne $LauncherAmount)
    {
        Write-Host (Get-Date) ": Launchers are misconfigured, correcting launchers ini."
        $launcherArray = @()
        Import-Module -Name Hyper-V
        For ($i = 1;$i -le $LauncherAmount;$i++)
        {
            $iFormatted = "{0:d3}" -f $i
            $VMName = $LauncherPrefix + "-LS" + $iFormatted
            if (Get-VM -ComputerName $HostName -Name $VMName) {
                $launcherArray += $VMName
            }
        }

        Write-Host (Get-Date) ": Creating new Launchers ini file."
        New-Item -Path "$Share\_VSI_Configuration\Launchers.ini" -ItemType File -Force | Out-Null

        Write-Host (Get-Date) ": Adding new launcher configuration."  
        foreach ($launcherItem in ($launcherArray | Sort-Object)) {
            Add-Content -Path "$Share\_VSI_Configuration\Launchers.ini" -Value "[$launcherItem]"
            Add-Content -Path "$Share\_VSI_Configuration\Launchers.ini" -Value "Capacity=25"
            Add-Content -Path "$Share\_VSI_Configuration\Launchers.ini" -Value "Disabled=0"
            Add-Content -Path "$Share\_VSI_Configuration\Launchers.ini" -Value "CMLaunch=0"
            Add-Content -Path "$Share\_VSI_Configuration\Launchers.ini" -Value "Notes="
        }

        return $true
    }

    return $false
}

function Collect-LauncherData {
    ##############################
    #.SYNOPSIS
    #Collects data from the launcher
    #
    #.DESCRIPTION
    #Collects the performance data from the launcher
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER LauncherPrefix
    #Prefix of the laucnhers
    #
    #.PARAMETER TestName
    #Name of the test
    #
    #.PARAMETER Share
    #The share
    #
    #.EXAMPLE
    #Collect-LauncherData -HostName "VAL-INFRA2" -LauncherPrefix "T3" -TestName "Win10_TEST" -Share "\\VAL-FS03\VSIShare"
    #
    #.NOTES
    #General notes
    ##############################
    Param(
        [System.Array]$Launchers,
        [string]$TestName,
        [string]$Share
    )
    
    Write-Host (Get-Date) ": Collect all performance data from launchers."

    $testRun = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($TestName)}

    foreach ($launcher in $launchers) {    
        $items = Get-ChildItem -Path "\\$($launcher)\c$\PerfLogs\Admin\" | Where-Object {$_.Name.StartsWith("$($testRun.Name)")}
        $items | Copy-Item -Destination $testRun.FullName
    }
    
}

function Capture-LauncherData {
    ##############################
    #.SYNOPSIS
    #Captures performance data
    #
    #.DESCRIPTION
    #Captures perfomance data from the launchers
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER LauncherPrefix
    #Prefix of the laucnhers
    #
    #.PARAMETER TestName
    #Name of the active test
    #
    #.PARAMETER Duration
    #The duration of the test
    #
    #.EXAMPLE
    #Capture-LauncherData -HostName "VAL-INFRA2" -LauncherPrefix "T3" -TestName "Win10_TEST_run_1" -Duration 2880
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Array]$Launchers,
        [string]$TestName,
        [int]$Duration
    )

    Write-Host (Get-Date) ": Starting performance data capture on launchers."
    
    $delay = 30
    $timeout = [math]::Round($Duration + ($delay * 5))

    foreach ($launcher in $launchers) {
        $fileName = $TestName + "_RDA_" + "$($launcher)"

        Start-Job -ScriptBlock {
            Param(
                [string]$jobLauncher,
                [string]$jobTestName,
                [int]$jobTimeout,
                [int]$jobDelay
            )

            Invoke-Command -ComputerName $jobLauncher -ScriptBlock {
                Param (
                    [string]$invokeTestName,
                    [int]$invokeTimeout,
                    [int]$invokeDelay
                )

                logman.exe create counter $invokeTestName --v -si "00:00:$invokeDelay" -f csv -c "\Processor(*)\*" "\Memory\*" "\PhysicalDisk(*)\*" "\Network Interface(*)\*"
                logman.exe start $invokeTestName

                Start-Sleep -Seconds $invokeTimeout
                
                logman.exe stop $invokeTestName
                logman.exe delete $invokeTestName

            } -ArgumentList  @($jobTestName, $jobTimeout, $jobDelay)

        }  -ArgumentList  @($($launcher), $fileName, $timeout, $delay)
    }
}