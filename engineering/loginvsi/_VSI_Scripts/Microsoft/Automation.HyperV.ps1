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
    #.EXAMPLE
    #Reboot-Host -HostName "VAL-TARGET3"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param([string]$HostName)

    Import-Module -Name Hyper-V

    Write-Host (Get-Date) ": Stop all VM's on host"    
    Get-VM -ComputerName $HostName | Where-Object {$_.State -eq "Running"} | Stop-VM -Confirm:$false

    $startTime = Get-Date
    $force = $false
    while (Get-VM -ComputerName $HostName | Where-Object {$_.State -eq "Running"}) {
        
        Start-Sleep -Seconds 5
        
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt 5 -and $force -eq $false) {
            Write-Host (Get-Date) ": Frienly shutdown took to long, forcing shutdown." 
            $force = $true
            Get-VM -ComputerName $HostName | Where-Object {$_.State -eq "Running"} | Stop-VM -Force -Confirm:$false
        }
    }

    Write-Host (Get-Date) ": Rebooting hypervisor."
    Restart-Computer -ComputerName $HostName -Force -Confirm:$false -Wait -For WinRM
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

    Import-Module -Name Hyper-V

    Write-Host (Get-Date) ": Validating hypervisor."

    $startTime = Get-Date
    while (!(Test-Connection -ComputerName $HostName -BufferSize 32 -Count 1 -Quiet)) {
        Start-Sleep 5

        $date = Get-Date
        $timeout = 10
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Host $HostName not availible within $timeout minutes." 
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

    Import-Module -Name Hyper-V

    Write-Host (Get-Date) ": Validating targets."
    Get-VM -ComputerName $HostName | Where-Object {$_.State -ne "Running" -and $_.Name.StartsWith($TargetPrefix) } | Start-VM

    Write-Host (Get-Date) ": Stopping VM's which are not used for the test."
    Get-VM -ComputerName $HostName | Where-Object {$_.State -eq "Running" -and (!($_.Name.StartsWith($TargetPrefix))) } | Stop-VM -Force -Confirm:$false
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
    #.EXAMPLE
    #Capture-HostData -HostName "VAL-TARGET3" -TestName "Win10_TEST_run_1"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$HostName,
        [string]$TestName
    )

    Write-Host (Get-Date) ": Starting performance data capture on hypervisor."
    logman.exe create counter PerfMon -si 00:00:30 -f csv -c "\Hyper-V Hypervisor Logical Processor(*)\*" "\LogicalDisk(*)\*" "\Memory\*" "\Network Interface(*)\*" "\Paging File(*)\*" "\PhysicalDisk(*)\*" "\Process(*)\*" "\Redirector\*" "\Server\*" "\System\*"
    logman.exe start PerfMon
    logman.exe stop Pefmon
    #doe stufffff
}

Function Wait-RemotePosh
{
	Param
	(
		$VMName,
		[switch]$CheckHostname = $true,
		$VMHost	
	)

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
					$vmip = Get-VMIPaddress -VMName $VMName -VMHost $VMHost
					
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
					Write-Warning $_
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

			Get-VM $VMName -CimSession $VMHost | Stop-VM -force -TurnOff -CimSession $VMHost
			Get-VM $VMName -CimSession $VMHost | Start-VM -CimSession $VMHost
			Start-Sleep -Seconds 30
		}
		if ($OuterLoopcount -ge $OuterLoopMaxcount)
		{						
			throw "$($VMName) - Failed to get Powershell remoting to work, rebooted machine $OuterLoopMaxcount times"
		}
	}
}

Function Join-Domain
{
	Param
	(
		$VMName,
		$VMHost,		
		$localCredential,
		$domainCredential,
		$OUPath,
		$DomainName
	)
		
	$count  = 0
	$maxcount = 30
	$result = $false
	$retry = $true
	while ($retry -eq $true)
	{
		$count = $count + 1
		try
		{
			$vmip = Get-VMIPAddress -VMName $VMName -VMHost $VMHost
			
			# remove the computer from AD as it might (or probably) already exists in either the new or old OU
			$GetComputer = $null
			try { $GetComputer = Get-ADComputer $vmname -Credential $domainCredential } catch { } # get-adcomputer doesn't properly read/use the erroraction https://rcmtech.wordpress.com/2012/12/03/powershell-remove-computer-from-active-directory/
			if($GetComputer)
			{
				Write-Host "$(Get-Date) Computer $($VMName) found in AD, removing..."
				$CurrentADcomputer = Get-ADObject $GetComputer -Credential $domainCredential -ErrorAction SilentlyContinue 
				$CurrentADcomputer | Remove-ADObject -recursive -confirm:$false
				
			}

			# to help allviate the "new name is the same as the current name error" from Rename-Computer
			$hostname = Invoke-Command -ComputerName $vmip -Credential $localcredential -ea SilentlyContinue  -ScriptBlock { netsh advfirewall set allprofiles state off | Out-Null;return hostname }			
			if($hostname -ne $VMName)
			{
				Rename-Computer -ComputerName $vmip -Localcredential $localcredential -NewName $vmname -Force -WarningAction SilentlyContinue
			}
			Write-Host "$(Get-Date) Restarting computer..."
			Restart-Computer -Credential $localCredential -ComputerName $vmip -Wait -For Powershell 
			Write-Host "$(Get-Date) Computer restarted"			
			
						
			Add-Computer -ComputerName $vmip -LocalCredential $localCredential -DomainName $DomainName -Credential $domainCredential -OUPath $OUPath
			Stop-Computer $vmip -Force
			Write-Host "$(Get-Date) - Added $VMName to domain: $DomainName"

			$retry = $false
		}
		catch
		{
			#Write-Host $_ -foregroundcolor red
			Write-Warning "$($VMName) - Failed to join domain: $($_), retrying $($maxcount - $count) more times..."
			$reason = $_
			$retry = $true
			$GetComputer = $null
			Start-Sleep -Seconds 2
		}
		if ($count -ge $maxcount)
		{						
			throw $reason
		}
		If ($result -eq $true)
		{
			$retry = $false
		}	
	}

	#region wait for vm to have turned off and turn it on again
	$count = 0
	$maxcount = 900
	$online = $false
	$retry = $true

	while ($retry -eq $true)
	{
		$count = $count + 1
		try 
		{
			
			$vmobj = (Get-VM -Name $VMName -CimSession $VMHost)
			
			
			if ($vmobj.state -ne "off")
			{
				$online = $True
				$retry = $true
			}
			else
			{
				$online = $false
				$retry = $false
				Start-VM -VMName $VMName -CimSession $VMHost
				#get-vm $vm.name -CimSession $VMGroup.OwnerNode.Name -ErrorAction SilentlyContinue | Start-VM -Confirm:$false | Out-Null
			}
		}
		catch [exception]
		{
			Write-Warning $_
			$online = $true
			$retry = $true
		}

		if ($count -ge $maxcount)
		{
			$retry = $false
		}
		else
		{
			Start-Sleep -Seconds 1
		}
	}

	#region wait for remoteposh			
	Wait-RemotePosh -VMName $VMName -VMHost $VMHost
	Invoke-Command -ComputerName $vmip -Credential $domainCredential -ScriptBlock {Enable-PSRemoting -Force;Enable-WSManCredSSP -role Server -Force} 
	#endregion
}

Function Get-VMIPAddress
{
	Param
	(
		$VMName,
		$VMHost
	)


	$retry = $true
	while ($retry -eq $true)
	{
		try
		{
			do 
			{
				Start-Sleep -milliseconds 100			
			} 
			until ((Get-VMIntegrationService $VMName -ComputerName $VMHost -ErrorAction Stop | ?{$_.name -eq "Heartbeat"}).PrimaryStatusDescription -eq "OK")		
			$IP = (Get-VMNetworkAdapter -ComputerName $VMHost -VMName $VMName).IpAddresses[0].ToString()
			If (-not ([string]::IsNullOrEmpty($ip)))
			{
				$retry = $false
				return $IP
			}
		}
		catch {$retry = $true}
	}
}