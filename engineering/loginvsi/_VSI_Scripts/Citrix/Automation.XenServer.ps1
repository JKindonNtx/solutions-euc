function Reboot-Host {
    ##############################
    #.SYNOPSIS
    #Reboots the host
    #
    #.DESCRIPTION
    #Stops all the running VM's and reboots the hypervisor host
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TargetPrefix
    #TargetPrefix name used for the delivery group
    #
    #.EXAMPLE
    #Reboot-Host -HostName "VAL-TARGET3" -TargetPrefix "T3"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$HostName,
        [string]$TargetPrefix)

    Import-Module -Name XenServerPSModule
    
    $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json

    Connect-XenServer -Server $HostName -UserName $($configXenServer.UserName) -Password $($configXenServer.Password) -NoWarnNewCertificates -SetDefaultSession
    
    Invoke-command -ComputerName "VAL-XD01" -ScriptBlock {
        Param([string]$envName)
        Import-Module Citrix*
        Add-PSSnapin Citrix*
        $DG = $null
        try {
            $DG = Get-BrokerDesktopGroup -Name $envName -ErrorAction SilentlyContinue 
            If ($DG -ne $null)
            {
                $DG | Set-BrokerDesktopGroup -InMaintenanceMode $true
            }
        }
        catch 
        {
            Write-Host "Could not get set desktop group in maintenance mode, proceeding without maintenance mode..."
        }
    } -ArgumentList $TargetPrefix
    <#
    Write-Host (Get-Date) ": Stop all VM's on host"
    $runningVms = Get-XenVM | Where-Object {$_.is_a_template -ne "False" -and $_.is_control_domain -ne "False" -and $_.power_state -eq "running"}
    try {
        $runningVms | Invoke-XenVM -XenAction CleanShutdown -ErrorAction Continue
    }
    catch {

        Write-Host (Get-Date) ": Something went wrong with friendly shutdown, waiting for other VM's to shutdown."
        Start-Sleep -Seconds 30
        Write-Host (Get-Date) ": Sending hard shutdown"
        
        Get-XenVM | Where-Object {$_.is_a_template -ne "False" -and $_.is_control_domain -ne "False" -and $_.power_state -eq "running"} | Invoke-XenVM -XenAction HardShutdown -ErrorAction Continue
    }
    
    
    $timeoutTime = 10
    $startTime = Get-Date
    $force = $false

    while ((Get-XenVM | Where-Object {$_.is_a_template -ne "False" -and $_.is_control_domain -ne "False" -and $_.power_state -eq "running"} )) {
        Start-Sleep -Seconds 5
        
        if (((Get-Date) - $startTime).TotalMinutes -gt $timeoutTime -and $force -eq $false) {
            Write-Host (Get-Date) ": Shutdown cycle took to long, forcing shutdown."
            $force = $true
            Get-XenVM | Where-Object {$_.is_a_template -ne "False" -and $_.is_control_domain -ne "False" -and $_.power_state -eq "running"} | Invoke-XenVM -XenAction Shutdown -ErrorAction Continue
        }
    }
    #>
    Write-Host (Get-Date) ": Rebooting hypervisor."
    Get-XenHost | Invoke-XenHost -XenAction Disable
    Get-XenHost | Invoke-XenHost -XenAction Reboot

    $startTime = Get-Date
    $timeout = 10
    while (Test-Connection -ComputerName $HostName -BufferSize 32 -Count 1 -Quiet) {
        Start-Sleep 5

        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Host $HostName not responding to reboot." 
            Stop-Transcript
        }
    }
}

function Validate-Host {
    ##############################
    #.SYNOPSIS
    #Validates if the host is availiable
    #
    #.DESCRIPTION
    #Validates if the host is available
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.EXAMPLE
    #Reboot-Host -HostName "VAL-TARGET3"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    param ([string]$HostName)
    
	Import-Module -Name XenServerPSModule
    
    $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json

    Write-Host (Get-Date) ": Validating hypervisor."
    
    $startTime = Get-Date
    $timeout = 10
    while (!(Test-Connection -ComputerName $HostName -BufferSize 32 -Count 1 -Quiet)) {
        Start-Sleep 5

        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Host $HostName not availible within $timeout minutes." 
            Stop-Transcript
        }
    }

    $connected = $false
    $count = 1
    $maxAttempt = 10
    while (!($connected)) {
        try {
            if ($count -ge $maxAttempt) {
                break
            }

            Connect-XenServer -Server $HostName -UserName $($configXenServer.UserName) -Password $($configXenServer.Password) -NoWarnNewCertificates -SetDefaultSessio
            $connected = $true
        }
        catch {
            Write-Host (Get-Date) ": Cannot connect to the host $hostName. Attempt $count of $maxAttempt"
            Start-Sleep 30
            $count++
        }
    }
}

Function Validate-Target {
    ##############################
    #.SYNOPSIS
    #Validates if the targets are running
    #
    #.DESCRIPTION
    #Validates if the target VM's are running on the specified host
    #
    #.PARAMETER TargetPrefix
    #Prefix for the target naming
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor where targets are hosted
    #
    #.EXAMPLE
    #Validate-Target -LauncherPrefix "T3-" -HostName "VAL-INFRA2"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    param(
        [string]$HostName,
        [string]$TargetPrefix
    )

    
    $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json

    Invoke-command -ComputerName "VAL-XD01" -ScriptBlock {
        Param([string]$envName)
        Import-Module Citrix*
        Add-PSSnapin Citrix*        
        $DG = $null
        try {
            $DG = Get-BrokerDesktopGroup -Name $envName -ErrorAction SilentlyContinue 
            If ($DG -ne $null)
            {
                $DG | Set-BrokerDesktopGroup -InMaintenanceMode $true
            }
        }
        catch 
        {
            Write-Host "Could not get set desktop group in maintenance mode, proceeding without maintenance mode..."
        }
    } -ArgumentList $TargetPrefix

    Connect-XenServer -Server $HostName -UserName $($configXenServer.UserName) -Password $($configXenServer.Password) -NoWarnNewCertificates -SetDefaultSession

    $allVms = Get-XenVM | Where-Object {$_.is_a_template -ne "False" -and $_.is_control_domain -ne "False" -and $_.name_label.StartsWith($TargetPrefix)}

    while ($currentVms = Get-XenVM | Where-Object {$_.is_a_template -ne "False" -and $_.is_control_domain -ne "False" -and $_.power_state -ne "running" -and $_.name_label.StartsWith($TargetPrefix)}) {
        
        Write-Host (Get-Date) ": $($allVms.Count - $currentVms.Count) of $($allVms.Count) are running."        
        try {
            Get-XenVM | Where-Object {$_.is_a_template -ne "False" -and $_.is_control_domain -ne "False" -and $_.power_state -ne "running" -and $_.name_label.StartsWith($TargetPrefix)} | Invoke-XenVM -XenAction Start
        } catch {
            try {
                Get-XenVM | Where-Object {$_.is_a_template -ne "False" -and $_.is_control_domain -ne "False" -and $_.power_state -ne "running" -and $_.name_label.StartsWith($TargetPrefix)} | Invoke-XenVM -XenAction PowerStateReset
            } catch {
                # nothing
            }
        }

        Start-Sleep -Seconds 30
    }
}

function Capture-HostData {
    ##############################
    #.SYNOPSIS
    #Captures performance data
    #
    #.DESCRIPTION
    #Captures perfomance data from the specified hypervisor
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TestName
    #Name of the active test
    #
    #.PARAMETER Duration
    #The duration of the test
    #
    #.EXAMPLE
    #Capture-HostData -HostName "VAL-TARGET3" -TestName "Win10_TEST_run_1" -Duration 2880
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$HostName,
        [string]$TestName,
        [int]$Duration
    )

    Write-Host (Get-Date) ": Starting performance data capture on hypervisor."
    
    
    $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json

    
    $delay = 30
    $timeout = [math]::Round($Duration + ($delay * 5))
    $path = "/root/$TestName.csv"

    $command = "timeout $($timeout)s rrd2csv -s $delay > $path"

    $password = ConvertTo-SecureString $($configXenServer.Password) -AsPlainText -Force
    $hostCredential = New-Object System.Management.Automation.PSCredential ($($configXenServer.UserName), $password)

    Start-Job -Scriptblock {
        Param(
            [PSCredential]$jobCred,
            [string]$jobHost,
            [string]$jobCommand
        )  

        $session = New-SSHSession -ComputerName $jobHost -Credential $jobCred -AcceptKey
        Invoke-SSHCommand -Index $session.SessionId -Command $jobCommand
        Get-SSHSession | Remove-SSHSession | Out-Null
    } -ArgumentList @($hostCredential, $HostName, $command)

}

Function Capture-NvidiaData {
    ##############################
    #.SYNOPSIS
    #Captures nvidia performance data
    #
    #.DESCRIPTION
    #Captures nvidia perfomance data from the specified hypervisor
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TestName
    #Name of the active test
    #
    #.PARAMETER Duration
    #The duration of the test
    #
    #.EXAMPLE
    #Capture-NvidiaData -HostName "VAL-TARGET3" -TestName "Win10_TEST_run_1" -Duration 2880
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$HostName,
        [string]$TestName,
        [int]$Duration
    )
    
    Write-Host (Get-Date) ": Starting NVIDIA performance data capture on hypervisor."
    
    
    $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json

    
    $delay = 30
    $timeout = [math]::Round($Duration + ($delay * 5))
    
    $path = "/root/$TestName.nvidia.csv"
    $command = "nvidia-smi -l $delay --format=csv,nounits,noheader --query-gpu=timestamp,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free,temperature.gpu,power.draw,clocks.current.graphics,clocks.current.sm,clocks.current.memory,clocks.current.video -f $path"

    $password = ConvertTo-SecureString $($configXenServer.Password) -AsPlainText -Force
    $hostCredential = New-Object System.Management.Automation.PSCredential ($($configXenServer.UserName), $password)

    Start-Job -Scriptblock {
        Param(
            [PSCredential]$jobCred,
            [string]$jobHost,
            [string]$jobCommand,
            [int]$jobTimeout
        )  

        $session = New-SSHSession -ComputerName $jobHost -Credential $jobCred -AcceptKey
        Invoke-SSHCommand -Index $session.SessionId -Command $jobCommand -TimeOut $jobTimeout
        Get-SSHSession | Remove-SSHSession | Out-Null
    } -ArgumentList @($hostCredential, $HostName, $command, $timeout)
}

Function Collect-HostData {
    ##############################
    #.SYNOPSIS
    #Collects performance data from host
    #
    #.DESCRIPTION
    #Downloads the perfomance data from the specified hypervisor
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TestName
    #Name of the test
    #
    #.PARAMETER Share
    #Location of the Login VSI share
    #
    #.EXAMPLE
    #Collect-HostData -HostName "VAL-TARGET3" -TestName "WIN10_x64_Test" -Share "\\VAL-FS03\VSIShare"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################   
    Param(
        [string]$HostName,
        [string]$TestName,
        [string]$Share
    )
    Write-Host (Get-Date) ": Collect all performance data from hypervisor."
    
    $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json


    $tempLocation = "$env:Temp\"

    $testNameFilter = $TestName + "_run"
    $testRuns = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($testNameFilter)}

    $password = ConvertTo-SecureString $($configXenServer.Password) -AsPlainText -Force
    $hostCredential = New-Object System.Management.Automation.PSCredential ($($configXenServer.UserName), $password)

    foreach ($testRun in $testRuns) {       
        $testRunName = $testRun.Name + ".csv"
        $remoteFile = "/root/$testRunName"
        $localFile = $tempLocation + $testRunName
        Get-SCPFile -HostName $HostName -RemoteFile $remoteFile -LocalFile $localFile -Credential $hostCredential
        
        Copy-Item -Path $localFile -Destination $testRun.FullName
        Remove-Item -Path $localFile -Confirm:$false
    }
}

Function Collect-NvidiaData {
    ##############################
    #.SYNOPSIS
    #Collects nvidia performance data from host
    #
    #.DESCRIPTION
    #Downloads the nvidia perfomance data from the specified hypervisor
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TestName
    #Name of the test
    #
    #.PARAMETER Share
    #Location of the Login VSI share
    #
    #.EXAMPLE
    #Collect-NvidiaData -HostName "VAL-TARGET3" -TestName "WIN10_x64_Test" -Share "\\VAL-FS03\VSIShare"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################   
    Param(
        [string]$HostName,
        [string]$TestName,
        [string]$Share
    )
    try 
    {
        Write-Host (Get-Date) ": Collect all NVIDIA performance data from hypervisor."
        
        $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json


        $tempLocation = "$env:Temp\"

        $testNameFilter = $TestName + "_run"
        $testRuns = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($testNameFilter)}

        $password = ConvertTo-SecureString $($configXenServer.Password) -AsPlainText -Force
        $hostCredential = New-Object System.Management.Automation.PSCredential ($($configXenServer.UserName), $password)

        foreach ($testRun in $testRuns) {       
            $testRunName = $testRun.Name + ".nvidia.csv"
            $remoteFile = "/root/$testRunName"
            $localFile = $tempLocation + $testRunName
            
            Get-SCPFile -HostName $HostName -RemoteFile $remoteFile -LocalFile $localFile -Credential $hostCredential
            
            $data = @()
            $data += "timestamp,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free,temperature.gpu,power.draw,clocks.current.graphics,clocks.current.sm,clocks.current.memory,clocks.current.video"
            $data += Get-Content -Path $localFile
            Set-Content -Path $localFile -Value $data
            
            Copy-Item -Path $localFile -Destination $testRun.FullName
            Remove-Item -Path $localFile -Confirm:$false
        }
    }
    catch
    {
        Write-Host "Failed to get NVIDIA data with reason: $_"
    }
}
Function Wait-RemotePosh
{
	Param
	(
		$VMName,
		[switch]$CheckHostname = $true,
		$VMHost	
	)
    
    $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json

    Import-Module -Name XenServerPSModule

    Connect-XenServer -Server $VMHost -UserName $($configXenServer.UserName) -Password $($configXenServer.Password) -NoWarnNewCertificates -SetDefaultSession
    

	$OuterLoopcount = 0
	$OuterLoopMaxcount = 3
	$OuterLoopRetry = $true
	$OuterLoopReason = $null
	Write-Verbose "$($VMName) - Checking remote powershell connectivity..."
	while ($OuterLoopRetry -eq $true)
	{
		try
		{
			$OuterLoopcount++
				

			$count = 0
			$maxcount = 100
			$retry = $true
			$reason = $null
			while ($retry -eq $true)
			{
				$count = $count + 1
				try
				{
                    #Write-Host "$(Get-Date) Waiting for ip address"
					$vmip = Get-VMIPaddress -VMName $VMName -VMHost $VMHost
					#Write-Host "$(Get-Date) Waiting for remote posh"
					# Henk - 20-1-2017 - #138024263: Added SEE_MASK_NOZONECHECKS system variable, to prevent those security dialogs from popping up					
					$TargetHostName = Invoke-Command -ComputerName $vmip -Credential $global:localcredential -ea Stop {[System.Environment]::SetEnvironmentVariable("SEE_MASK_NOZONECHECKS","1","Machine");(gci env:computername).value}					
					If ($CheckHostname)
					{
						If ($TargetHostName -ne $($vmname))
						{
							throw "$($VMName) - TargetHostName was: $TargetHostName but expected $($VMName)"
						}
						else
						{
							$OuterLoopRetry = $false
							$retry = $false
						}
					}
					else
					{
						$OuterLoopRetry = $false
						$retry = $false
					}
				}
				catch
				{
					#Write-Warning $_
					$reason = $_
					$retry = $true
					#(get-vm $vm.name -CimSession $global:ClusterName -ErrorAction SilentlyContinue) | Stop-VM -Force -TurnOff
					#(get-vm $vm.name -CimSession $global:ClusterName -ErrorAction SilentlyContinue) | Start-VM			
					Start-Sleep -Seconds 3
				}
				
				
				if ($count -ge $maxcount)
				{						
					throw $reason
				}
			}
		}
		catch
		{										
			Write-Warning "$($VMName) - Failed to use remote powershell with reason: $_, rebooting machine and retrying $($OuterLoopMaxcount - $OuterLoopcount) more times..."
			$reason = $_
			$OuterLoopRetry = $true
            
			Get-XenVM -Name $VMName | Invoke-XenVM -XenAction CleanShutdown
			Get-XenVM -Name $VMName | Invoke-XenVM -XenAction Start
			Start-Sleep -Seconds 30
		}
		if ($OuterLoopcount -ge $OuterLoopMaxcount)
		{						
			throw "$($VMName) - Failed to get Powershell remoting to work, rebooted machine $OuterLoopMaxcount times"
		}
	}
}


Function Get-VMIPAddress
{
	Param
	(
		$VMName,
		$VMHost
	)
    
 $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json
    
    Import-Module -Name XenServerPSModule

    Connect-XenServer -Server $VMHost -UserName $($configXenServer.UserName) -Password $($configXenServer.Password) -NoWarnNewCertificates -SetDefaultSession
    

	$retry = $true
	while ($retry -eq $true)
	{
		try
		{

            $VM = Get-XenVM -Name $VMName
			$IP = (Get-XenVMProperty -VM $VM -XenProperty GuestMetrics).networks["0/ip"]
			If (-not ([string]::IsNullOrEmpty($ip)))
			{
				$retry = $false
				return $IP
			}
		}
		catch {
            Write-Warning $_
            $retry = $true
        }
	}
}

function Initialize-TargetVMS
{
    Param
    (
        $config
    )

    $configXenServer = Get-Content -Path "$PSScriptRoot\config.XenServer.json" -Raw | ConvertFrom-Json
    Import-Module -Name XenServerPSModule        
    Connect-XenServer -Server $config.TargetHost -UserName $($configXenServer.UserName) -Password $($configXenServer.Password) -NoWarnNewCertificates -SetDefaultSession
   
   write-host "Removing existing VMs from Target"
   try
   { 
		$ExistingVMs = Get-XenVM -Name "$($config.Environment)-*" 
		Foreach ($ExistingVM in $ExistingVMs)
		{
			 If ($ExistingVM.power_state -eq "Running")
				{
					
					$ExistingVM | Invoke-XenVM -XenAction HardShutdown
				}
				$ExistingVM.VBDs | % { Get-XenVBD $_.opaque_ref | Where-Object {$_.type -notlike "CD"} } | % {Get-XenVDI -Ref $_.VDI | Remove-XenVDI }                            
				$ExistingVM | Remove-XenVM -Confirm:$false               
		}
	}
	Catch
	{
		write-warning $_
	}
	
	
    For ($i=1;$i -le $config.TargetAmount;$i++)
    {       
        
        $iFormatted = "{0:d3}" -f $i
        $VMName = $config.Environment + "-" + $iFormatted        
          
        
       
        # Create the VM
        Write-Progress -Id 1 -Activity "Creating VMs" -Status "Creating VM: $VMName" -PercentComplete ([math]::Round($i/$($config.TargetAmount)*100))
        Write-Host "$(Get-Date) Creating VM $VMName"

        $TargetVM = Get-XenVM -Name $config.TargetTemplate
        Invoke-XenVM -NewName $VMName -VM $TargetVM -XenAction Clone
        
        $VM = Get-XenVM -Name $VMName
        $VM | Set-XenVM -Memory ($config.TargetMemoryGB * 1GB) -VCPUsAtStartup $config.TargetvCPU
        $retry = $true
        $count = 0
        $maxcount = 10
        while ($retry -eq $true)
        {
            $count++
            try
            {
                $VM | Invoke-XenVM -XenAction Start
                $retry = $false
            }
            catch
            {
                $retry = $true
                Start-Sleep -Seconds 10   
                $reason = $_
            }
            if ($count -ge $maxcount)
            {
                $retry = $false
                throw $reason
            }
        }
        #Remove DNS record
        $Mac = (Get-XenVMProperty -VM $VM -XenProperty VIFs)[0].MAC
        $Lease = $null
        $Lease = Get-dhcpServerV4Lease -ScopeId 10.50.0.0 -CimSession val-dc01 | ? {$_.hostname -like "$VMName.*"}
        $Lease | Remove-DHCPServerv4Lease
        $DNS = $null
        $DNS = Get-DnsServerResourceRecord -CimSession VAL-DC01 -Name $VMName -ZoneName $config.DomainName -ErrorAction SilentlyContinue
        if ($DNS -ne $null)
        {
            $DNS | Remove-DnsServerResourceRecord -Force -Confirm:$false -ZoneName $config.DomainName
        }
        djoin.exe /provision /domain $config.DomainName /machine $VMName /machineOU $config.TargetOUPath /savefile "$($config.BlobFolder)\$VMName.txt" /REUSE | out-Null
        $ADObj = Get-ADComputer $VMName
        
        $guidString = "00000000-0000-0000-0000-" + $mac.Replace(":","")
        
        Set-ADComputer -identity $ADObj -Replace @{'netbootGUID' = ([System.Guid]::Parse($guidString)).ToByteArray()} -Confirm:$false
        

    }
    Write-Progress -Id 1 -Activity "Creating VMs" -PercentComplete 100 -Completed

}