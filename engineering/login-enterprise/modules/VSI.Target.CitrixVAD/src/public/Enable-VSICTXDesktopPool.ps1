Function Enable-VSICTXDesktopPool {
    Param(
        $DesktopPoolName,
        $NumberOfVMs,
        $ADUserName,
        $ADPassword,
        $PowerOnVMs,
        $VMRegistrationTimeOutMinutes = 180,
        $DDC,
        $HypervisorType,
        $Affinity,
        $ClusterIP,
        $CVMSSHPassword,
        $VMnameprefix,
        $Hosts
    )

    $Boot = "" | Select-Object -Property bootstart,boottime

    #Power off VMs
    $desktops = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount 2500
    $totalDesktops = $desktops.Count
    Start-Sleep 2
    Write-Log "Initiate the shutdown for all the VMs."
    foreach ($desktop in $desktops) { 
        $desktop | New-BrokerHostingPowerAction -Action TurnOff | Out-Null
        #Start-Sleep 1
    }
 
    $desktops = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $totalDesktops | Where-Object {$_.PowerState -eq "On"}	
  
    $startTime = Get-Date
    $date = Get-Date
    $timeout = 180
    while ($desktops.Count -ne 0) {
        $desktops = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $totalDesktops | Where-Object {$_.PowerState -eq "On"}	
        Write-Log -Update "$($desktops.Count) of $($totalDesktops) still running."
     
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            throw "Shutdown took to long." 
        }
        Start-Sleep 10
    }
    Write-Log ""     
    Write-Log "All VMs are down."

    # End Power off VMs

    $ExistingVMCount = (Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -MaxRecordCount 2500 | Measure-Object).Count
    $NumberOfVMsToProvision = $NumberOfVMs - $ExistingVMCount
    Write-Log "Already $ExistingVMCount VM(s) in $DesktopPoolName"
    if ($NumberOfVMsToProvision -gt 0) {
        Write-Log "Starting provisioning of $NumberOfVMsToProvision VM(s) in $DesktopPoolName"
        $IdentityPool = Get-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName
        if ($IdentityPool.Lock) { Unlock-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName }
        Write-Log "Creating account(s)... "
        if ([string]::isNullOrEmpty($ADUserName)) {
            $adAccounts = New-AcctADAccount -AdminAddress $DDC -Count $NumberOfVMsToProvision -IdentityPoolUid $IdentityPool.IdentityPoolUid.Guid -ErrorAction Stop
        } else {
            $adAccounts = New-AcctADAccount -AdminAddress $DDC -Count $NumberOfVMsToProvision -IdentityPoolUid $IdentityPool.IdentityPoolUid.Guid -ADUsername $ADUserName -ADPassword (Convertto-SecureString -AsPlainText -Force -String $ADPassword) -ErrorAction Stop
        }
        
        Write-Log "Creating the virtual machine(s)... "
        #return $adAccounts
        $provTaskId = New-ProvVM -AdminAddress $DDC -AdAccountName $adAccounts.SuccessfulAccounts -ProvisioningSchemeName $DesktopPoolName -RunAsynchronously -ErrorAction Stop
        $provtask = Get-ProvTask -AdminAddress $DDC -TaskId $provTaskId
        $totalpercent = 0
        While ($provtask.Active -eq $true) {
            try {
                $totalpercent = If ($provTask.TaskProgress) { $provTask.TaskProgress } else { 0 }
            } catch {
            }
            Write-Log -Update "$totalPercent% Complete:" -percentComplete $totalpercent
            Start-Sleep 3
            $provtask = Get-ProvTask -AdminAddress $DDC -TaskId $provTaskId
        }
        Write-Log ""
        $ProvSchemeUid = (Get-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName).ProvisioningSchemeUid.Guid
        $Uid = (Get-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName).Uid
        $ProvVMS = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeUid $ProvSchemeUid -MaxRecordCount $([int]::MaxValue) | Where-Object { $_.Tag -ne "Brokered" }
        Write-Log "Assigning newly created machines to $DesktopPoolName..."
        Start-Sleep -Seconds 10 
        $count = 0
        Foreach ($VM in $ProvVMS) {            
            $count++
            $VMName = $VM.VMName
            Write-Log -Update "Adding vm $VMName ($count of $NumberOfVMsToProvision) to Catalog and DesktopPool              "            
            Lock-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -Tag "Brokered" -VMID @($VM.VMId) -ErrorAction Stop
            New-BrokerMachine -AdminAddress $DDC -Cataloguid $Uid -MachineName $VM.ADAccountSid -ErrorAction Stop | Add-BrokerMachine -DesktopGroup $DesktopPoolName -ErrorAction Stop            
            #New-BrokerMachine -Cataloguid $Uid -MachineName "LGNV\az-henk006$" -ErrorAction Stop | Add-BrokerMachine -DesktopGroup $DesktopPoolName -ErrorAction Stop
        }
        Write-Log ""
    } 
    # Set affinity to hosts
    Write-Log "Hypervisortype = $HypervisorType and Affinity is set to $Affinity"
    if (($HypervisorType) -eq "AHV" -And ($Affinity)) {
        Write-Log "Set Affinity to Host with IP $Hosts."
        # Install Posh-SSH module. Required to connect to the hosts using SSH. Used for capturing performance stats.
        if (!((Get-Module -ListAvailable *) | Where-Object {$_.Name -eq "Posh-SSH"})) {
            Write-Log "SSH module not found, installing missing module."
            Install-Module -Name Posh-SSH -RequiredVersion 2.3.0 -Confirm:$false -Force -Scope CurrentUser
        }
        # Build the command and add the vTPM using SSH
        $VMs = $VMnameprefix -Replace '#','?'
        $command = "~/bin/acli vm.affinity_set $VMs host_list=$($hosts)"
        $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
        $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200).output
        Remove-SSHSession -Name $Session | Out-Null
        Write-Log "Set Affinity Finished."
    }

    # End set affinity to hosts
    $Boot.bootstart = get-date -format o
    $BootStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Log "Powering on $PowerOnVMs machines"
    $PoweredOnVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount 2500 -SortBy MachineName | Select-Object -Last $PowerOnVMs
    $SetPowerOnVMs = $PoweredOnVMs | New-BrokerHostingPowerAction -Action TurnOn

    # Wait untill NumberOfVMs matches buffer provided
    $BrokerVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount 2500
    $RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count
    $Start = Get-Date
    Write-Log "Waiting for $PowerOnVMs VMs to be registered"
    while ($true) {
        Write-Log -Update "$RegisteredVMCount/$PowerOnVMs/$NumberOfVMs (Registered/PowerOnVMs/Total)"
        if ($RegisteredVMCount -eq $PowerOnVMs) {
            Write-Log ""
            break
        } else {          
            $BrokerVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount 2500
            $RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count
            $TS = New-TimeSpan -Start $Start -End (Get-Date)
            if ($TS.TotalMinutes -gt 15) {
                $PoweredOnVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount 2500 -SortBy MachineName | Select-Object -Last $PowerOnVMs
                $PowerOnStuckVMs = $PoweredOnVMs | Where-Object {$_.PowerState -eq "Off"} | New-BrokerHostingPowerAction -Action TurnOn
                Start-Sleep -Seconds 120
            }
            if ($TS.TotalMinutes -gt $VMRegistrationTimeOutMinutes) {
                throw "VMs failed to register within $VMRegistrationTimeOutMinutes minutes"
            }
        }
    }
    $BootStopwatch.stop()
    $Boot.boottime = $BootStopwatch.elapsed.totalseconds
    $Boot
}