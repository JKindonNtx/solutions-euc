function Start-VSIVCMonitoring {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [Int32]$DurationInMinutes,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [Int32]$RampupInMinutes,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CPUReadyMonitoring')]
        [string]$Cluster,
        [Parameter(Mandatory = $false, ParameterSetName = 'TestMonitoring')]
        [switch]$AsJob,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CPUReadyMonitoring')]
        [string]$vCenterServer,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CPUReadyMonitoring')]
        [string]$vCenterUsername,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CPUReadyMonitoring')]
        [string]$vCenterPassword,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [string]$OutputFolder,
        [Parameter(Mandatory = $true, ParameterSetName = 'CPUReadyMonitoring')]
        [switch]$StopWhenVMsAreReady,
        [Parameter(Mandatory = $false, ParameterSetName = 'CPUReadyMonitoring')]
        [Int32]$CPUUtilMHz = 25,
        [Parameter(Mandatory = $false, ParameterSetName = 'CPUReadyMonitoring')]
        [Int32]$TimeOutMinutes = 60,
        [Parameter(Mandatory = $true, ParameterSetName = 'CPUReadyMonitoring')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [string]$vCenterCounterConfigurationFile = ".\ReportConfiguration.jsonc",
        [Parameter(Mandatory = $false, ParameterSetName = 'TestMonitoring')]
        [string]$StopMonitoringCheckFile = "$env:temp\VSIMonitoring_Stop.chk"
    )
    $vCenterCounterConfiguration = Get-Content $vCenterCounterConfigurationFile | ConvertFrom-Json
    
    $MonitoringScriptBlock = {
        param(
            $DurationInMinutes,
            $RampupInMinutes,
            $Cluster,
            $vCenterServer,
            $vCenterUsername,
            $vCenterPassword,
            $OutputPath,
            $FilePrefix,
            $vCenterCounterConfiguration,
            $StopMonitoringCheckFile
        )
        if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath | Out-Null }
        Import-Module VMware.VimAutomation.Core
        Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -InvalidCertificateAction Ignore -ParticipateInCeip $false -DisplayDeprecationWarnings $false -Scope Session -Confirm:$false | Out-Null
        Connect-VIServer -Server $vCenterServer -User $vCenterUsername -Password $vCenterPassword | Out-Null
       
        $vmCounterNames = $vCenterCounterConfiguration.CounterChartSections | Where-Object { $_.ComputeType -eq "VM" } | ForEach-Object { $_.Charts.Counters.id }
        $hostCounterNames = $vCenterCounterConfiguration.CounterChartSections | Where-Object { $_.ComputeType -eq "Host" } | ForEach-Object { $_.Charts.Counters.id }
        $Exclusions = $vCenterCounterConfiguration.VMsToExcludeFromMonitoring

        $clusterhosts = VMware.VimAutomation.Core\Get-VMHost -Location $Cluster.Split("/")[$Cluster.Split("/").Count - 1] -State "Connected"
        $VMs = VMware.VimAutomation.Core\Get-VM -Location $Cluster.Split("/")[$Cluster.Split("/").Count - 1] | Where-Object { $_.PowerState -eq "PoweredOn" }
        $VMData = Get-View -ViewType VirtualMachine 
        if (-not (Test-Path "$OutputPath\Configuration.csv")) {
            Set-Content -Path "$OutputPath\Configuration.csv" -Value "1:l,2:l,3:l"
        }
        Add-Content -Path "$OutputPath\Configuration.csv" -Value "#VM,,"
        foreach ($VM in $VMs) {

            foreach ($Exclusion in $Exclusions) {
                if ($vm.Name -like $Exclusion) {
                    $skipVM = $true
                }
            }
            if ($skipVM -ne $true) {
                $V = $VMData | Where-Object { $_.Name -eq $VM.Name }
                
                Add-Content -Path "$OutputPath\Configuration.csv" -Value "Name,$($V.Name),$($V.Config.CreateDate)"
                if (($v.config.hardware.device | Where-Object { $_.key -eq 11000 } | Measure-Object).Count -gt 0) {
                    $tpm = "TPM"
                } else {
                    $tpm = "no TPM"
                }
                if ($V.Config.Flags.VbsEnabled) {
                    $vbs = "VBS"
                } else {
                    $vbs = "no VBS"
                }
                if ($V.config.bootOptions.efiSecureBootEnabled) {
                    $sb = "SecureBoot on"
                } else {
                    $sb = "SecureBoot off"
                }
                Add-Content -Path "$OutputPath\Configuration.csv" -Value "Hardware,$($V.Config.Version),$($V.Config.Firmware.ToUpper()) ($tpm; $vbs; $sb)"
                Add-Content -Path "$OutputPath\Configuration.csv" -Value "CPU,$($V.Config.Hardware.NumCPU),$($V.Config.Hardware.NumCoresPerSocket) cores per socket ($($V.Config.CpuAllocation.Shares.Shares) Shares)"
                $MemMB = [Math]::Round($V.Config.Hardware.MemoryMB, 0)
                $MemRes = [Math]::Round(($V.Config.InitialOverhead.InitialMemoryReservation / 1MB), 0)
                $MemAlloc = [Math]::Round($($V.Config.MemoryAllocation.Reservation), 0)
                Add-Content -Path "$OutputPath\Configuration.csv" -Value "Memory,$($MemMB)MB,$($MemRes)MB overhead ($($MemAlloc)MB reserved)"
                $NIC = Get-NetworkAdapter $V.Config.Name
                Add-Content -Path "$OutputPath\Configuration.csv" -Value "Network,$($NIC.NetworkName),$($NIC.Type)"
                $DiskCommit = [Math]::Round($($V.summary.storage.committed / 1GB), 2)
                $DiskUnCommit = [Math]::Round($($V.summary.storage.uncommitted / 1GB), 2)
                Add-Content -Path "$OutputPath\Configuration.csv" -Value "Disk,$($DiskCommit)GB/$($DiskUnCommit)GB, $((Get-ScsiController $V.Config.Name | Select-Object -ExpandProperty Type))"
                $OSString = ($V.Config.ExtraConfig | Where-Object { $_.Key -eq "guestInfo.detailed.data" }).value.Split("prettyName=")[1]
                $OSVersion = ($OSString.Split("(")[0] -replace ",", "").TrimStart("'")
                $OSBuild = ($OSString.Split("(")[1] -replace "\)", "").TrimEnd("'")
                Add-Content -Path "$OutputPath\Configuration.csv" -Value "OS,$OSVersion,$OSBuild"
                $GPU = ($V.Config.Hardware.Device | Where-Object { $_.Key -eq 500 }).VideoRamSizeInKB
                Add-Content -Path "$OutputPath\Configuration.csv" -Value "GPU,$($GPU * 1KB /1MB)MB,$(($V.Config.Hardware.Device | Where-Object { $_.Key -eq 13000 }).DeviceInfo.Summary)"
                break
            }
        }
        $HostData = Get-View -ViewType HostSystem
        Add-Content -Path "$OutputPath\Configuration.csv" -Value "#Host,,"
        Foreach ($H in $HostData | Where-Object { $ClusterHosts.Name -contains $_.Name }) {

            
            Add-Content -Path "$OutputPath\Configuration.csv" -Value "Host,$($H.Name),$($H.Config.Product.FullName)"
            Add-Content -Path "$OutputPath\Configuration.csv" -Value "Server,$($H.Summary.Hardware.Vendor),$($H.Summary.Hardware.Model) (BIOS $( $H.Hardware.BiosInfo.BiosVersion))"
            Add-Content -Path "$OutputPath\Configuration.csv" -Value "CPU,$($H.Summary.Hardware.NumCpuPkgs)x,$($H.Summary.Hardware.CpuModel)"
            Add-Content -Path "$OutputPath\Configuration.csv" -Value "Total Cores,$($H.Hardware.CpuInfo.NumCpuCores),$($H.Summary.Hardware.NumCpuThreads) threads ($($H.Hardware.NumaInfo.NumNodes) NUMA Nodes)"
            $HWSupport = $H.Hardware.CpuPowerManagementInfo.HardwareSupport -replace ",", ";"
            Add-Content -Path "$OutputPath\Configuration.csv" -Value "Power Policy,$($H.Hardware.CpuPowerManagementInfo.CurrentPolicy),$HWSupport"
            $MemGB = [Math]::Round($($H.Summary.Hardware.MemorySize / 1GB), 0)
            Add-Content -Path "$OutputPath\Configuration.csv" -Value "Memory,$($MemGB)GB,"
            Add-Content -Path "$OutputPath\Configuration.csv" -Value "Devices,$($H.Summary.Hardware.NumHBAs) HBAs,$($H.Summary.Hardware.NumNics) NICs"
            $GraphGB = [Math]::Round($($H.Config.GraphicsInfo.MemorySizeInKB * 1KB / 1GB), 2)
            Add-Content -Path "$OutputPath\Configuration.csv" -Value "Graphics,$($H.Config.GraphicsInfo.VendorName),$($H.Config.GraphicsInfo.DeviceName) ($($GraphGB)GB) $($H.Config.GraphicsConfig.DeviceType.GraphicsType)-$($H.Config.GraphicsConfig.SharedPassthruAssignmentPolicy) )"
            
        }
        Add-Content -Path "$OutputPath\Configuration.csv" -Value "#General,,"
        Add-Content -Path "$OutputPath\Configuration.csv" -Value "vCenter,$vCenterServer,$($H.Client.ServiceContent.About.FullName)"



        $Started = Get-Date
        $StartTimeStamp = Get-Date
        $StartTimeStamp = [DateTime]::new($StartTimeStamp.Year, $StartTimeStamp.Month, $StartTimeStamp.Day, $StartTimeStamp.Hour, $StartTimeStamp.Minute, 0)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
        $StopMonitoring = $false
        $SampleSize = 20

        while ($StopMonitoring -eq $false) {
            $CurrentTime = Get-Date
            while ($StartTimeStamp.AddSeconds(60) -gt $CurrentTime) {
                #Write-Host "$(Get-Date) Waiting while $($StartTimeStamp.AddSeconds(60)) is gt $CurrentTime"
                Start-Sleep -Seconds 1
                $CurrentTime = Get-Date
            }
            $EndTimeStamp = $STarttimeStamp.AddSeconds($SampleSize)
            $hosts = VMware.VimAutomation.Core\Get-VMHost -Location $Cluster.Split("/")[$Cluster.Split("/").Count - 1] -State "Connected"
            $VMs = VMware.VimAutomation.Core\Get-VM -Location $Cluster.Split("/")[$Cluster.Split("/").Count - 1] | Where-Object { $_.PowerState -eq "PoweredOn" }

            foreach ($VM in $VMs) {
                $skipVM = $false
                foreach ($Exclusion in $Exclusions) {
                    if ($vm.Name -like $Exclusion) {
                        $skipVM = $true
                    }
                }
                if ($skipVM -eq $false) {
                    $statFormatted = New-Object PSObject
                    $statFormatted | Add-Member -MemberType NoteProperty -Name "Name" -Value $VM.Name
                    $statFormatted | Add-Member -MemberType NoteProperty -Name "Host" -Value $VM.VMHost.Name
                    $stats = $null
                    $vmCounterNamesCount = ($vmCounterNames | Measure-Object).Count
                    $stats = $VM | Get-Stat -Stat $vmCounterNames -Start $StartTimeStamp -Finish $EndTimeStamp -MaxSamples 1 -IntervalSecs $SampleSize -ErrorAction SilentlyContinue | Where-Object { $_.Instance -eq "" }
                    foreach ($stat in $stats) {
                        $statFormatted | Add-Member -MemberType NoteProperty -Name $stat.metricId -Value $stat.Value
                        $statFormatted | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value (Get-Date ($StartTimeStamp.ToUniversalTime()) -Format "o") -Force
                    }
                    
                    $statsCount = ($stats | Measure-Object).Count
                    if ($statsCount -eq $vmCounterNamesCount) {
                        $statFormatted | Export-Csv -Append -Path "$OutputPath\VM Raw.csv"
                    } else {
                        Set-Content -Append -Path "$OutputPath\VM Raw.txt" -Value "stats contained $statsCount counters required $vmCounterNamesCount, ignoring this sample"
                        Set-Content -Append -Path "$OutputPath\VM Raw.txt" -Value "Retrieved: " $stats.metricId
                        Set-Content -Append -Path "$OutputPath\VM Raw.txt" -Value "Configured: " $vmCounterNames
                    }
                }
            }
            
            foreach ($h in $Hosts) {
                
                $stats = $null
                $stats = $h | Get-Stat -Stat $hostCounterNames -Start $StartTimeStamp -Finish $EndTimeStamp -MaxSamples 1 -IntervalSecs $SampleSize | Where-Object { $_.Instance -eq "" } 
                $statFormatted = New-Object PSObject
                $statFormatted | Add-Member -MemberType NoteProperty -Name "Host" -Value $h.Name
                $statsCount = ($stats | Measure-Object).Count
                $hostCounterNamesCount = ($hostCounterNames | Measure-Object).Count
                foreach ($counter in $stats) {
                    $statFormatted | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value (Get-Date ($StartTimeStamp.ToUniversalTime()) -Format "o") -Force
                    $statFormatted | Add-Member -MemberType NoteProperty -Name $counter.metricId -Value $counter.Value
                }
                if ($statsCount -eq $hostCounterNamesCount) {
                    $statFormatted | Export-Csv -Append -Path "$OutputPath\Host Raw.csv"
                } else {
                    Set-Content -Append -Path "$OutputPath\Host Raw.txt" -Value "stats contained $statsCount counters required $hostCounterNamesCount, ignoring this sample"
                    Set-Content -Append -Path "$OutputPath\VM Raw.txt" -Value "Retrieved: " $stats.metricId
                    Set-Content -Append -Path "$OutputPath\VM Raw.txt" -Value "Configured: " $vmCounterNames
                }
                
            }

            $StartTimeStamp = $StartTimeStamp.AddSeconds($SampleSize)

            if (($sw.ElapsedMilliseconds / 1000) -ge (20 * 60)) {
                Connect-VIServer -Server $vCenterServer -User $vCenterUsername -Password $vCenterPassword | Out-Null
                $sw.Restart()
            }
            if ((New-TimeSpan -Start $Started -End (Get-Date)).TotalMinutes -ge ($DurationInMinutes + $RampupInMinutes)) { $StopMonitoring = $true }
            if (Test-Path $StopMonitoringCheckFile) { $StopMonitoring = $true }
        }
        
        
    }

    $VMReadyMonitoringScriptBlock = {
        param(
            $CPUUtilMHz,
            $TimeOut,
            $Cluster,
            $vCenterServer,
            $vCenterUsername,
            $vCenterPassword,
            $vCenterCounterConfiguration
        )
        Import-Module VMware.VimAutomation.Core
        Set-PowerCLIConfiguration -ParticipateInCeip $false -Scope AllUsers -Confirm:$false | Out-Null
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope AllUsers -Confirm:$false | Out-Null
        Connect-VIServer -Server $vCenterServer -User $vCenterUsername -Password $vCenterPassword | Out-Null
        # https://www.virten.net/2020/12/vsphere-7-0-performance-counter-description/
        $vmCounterNames = @(
            "cpu.usagemhz.average"
        )
        Write-Log "Waiting until all VMs have CPU below $($CPUUtilMHz) MHz"
        $StartTimeStamp = Get-Date
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $Exclusions = $vCenterCounterConfiguration.VMsToExcludeFromMonitoring
        while ((New-TimeSpan -Start $StartTimeStamp -End (Get-Date)).TotalMinutes -le ($TimeOut)) {
            $AllVMs = @()
            $ReadyVMs = @()
            $hosts = VMware.VimAutomation.Core\Get-VMHost -Location $Cluster.Split("/")[$Cluster.Split("/").Count - 1] -State "Connected"
            $VMs = VMware.VimAutomation.Core\Get-VM -Location $Cluster.Split("/")[$Cluster.Split("/").Count - 1] | Where-Object { $_.PowerState -eq "PoweredOn" }
            foreach ($VM in $VMs) {
                $skipVM = $false
                foreach ($Exclusion in $Exclusions) {
                    if ($vm.Name -like $Exclusion) {
                        $skipVM = $true
                    }
                }
                if ($skipVM -eq $false) {
                    $AllVMs += $VM
                }
            }
            foreach ($VM in $AllVMs) {
                $stat = $null
                $stat = $VM | Get-Stat -Stat $vmCounterNames -MaxSamples 1 -Realtime | Where-Object { $_.Instance -eq "" }
                if ($null -ne $stat) {
                    if ($stat[0].Value -lt $CPUUtilMHz) {
                        $ReadyVMs += $VM
                    }
                }
            }
            $AllVMCount = ($AllVMs | Measure-Object).Count
            $ReadyVMCount = ($ReadyVMs | Measure-Object).Count
            if ($AllVMCount -eq $ReadyVMCount) {
                Write-Log -Update "All VMs have CPU below $($CPUUtilMHz) MHz                         "
                break
            } else {
                Write-Log -Update "$ReadyVMCount of $AllVMCount VMS have CPU below $($CPUUtilMHz) MHz                                "
            }
            Start-Sleep -Seconds 60

            if (($sw.ElapsedMilliseconds / 1000) -ge (20 * 60)) {
                Connect-VSIVCMonitor -vCenterServer $vCenterServer -vCenterUserName $vCenterUsername -vCenterPassword $vCenterPassword | Out-Null
                $sw.Restart() | Out-Null
            }

        }
        Write-Log ""

    }
    if ($AsJob.IsPresent) {
        Get-Job -Name VSIMonitoringJob -ErrorAction Ignore | Stop-Job
        Get-Job -Name VSIMonitoringJob -ErrorAction Ignore | Remove-Job
        return (Start-Job -ScriptBlock $MonitoringScriptBlock -Name VSIMonitoringJob -ArgumentList @($DurationInMinutes, $RampupInMinutes, $Cluster, $vCenterServer, $vCenterUsername, $vCenterPassword, $OutputFolder, $FilePrefix, $vCenterCounterConfiguration, $StopMonitoringCheckFile))
    } else {
        if ($StopWhenVMsAreReady.IsPresent) {
            (Invoke-Command -ScriptBlock $VMReadyMonitoringScriptBlock -ArgumentList @($CPUUtilMHz, $TimeOutMinutes, $Cluster, $vCenterServer, $vCenterUsername, $vCenterPassword, $vCenterCounterConfiguration))
        } else {
            return (Invoke-Command -ScriptBlock $MonitoringScriptBlock -ArgumentList @($DurationInMinutes, $RampupInMinutes, $Cluster, $vCenterServer, $vCenterUsername, $vCenterPassword, $OutputFolder, $FilePrefix, $vCenterCounterConfiguration, $StopMonitoringCheckFile))
        }
    }
}