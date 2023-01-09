Function Enable-VSICTXDesktopPool {
    Param(
        $DesktopPoolName,
        $NumberOfVMs,
        $ADUserName,
        $ADPassword,
        $PowerOnVMs,
        $VMRegistrationTimeOutMinutes = 20,
        $DDC
    )
    
    $ExistingVMCount = (Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName | Measure-Object).Count
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
    Write-Log "Powering on $PowerOnVMs machines"
    $PoweredOnVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount 2000 | Select-Object -Last $PowerOnVMs | New-BrokerHostingPowerAction -Action TurnOn

    # Wait untill NumberOfVMs matches buffer provided
    $BrokerVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName
    $RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count
    $Start = Get-Date
    Write-Log "Waiting for $PowerOnVMs VMs to be registered"
    while ($true) {
        Write-Log -Update "$RegisteredVMCount/$PowerOnVMs/$NumberOfVMs (Registered/PowerOnVMs/Total)"
        if ($RegisteredVMCount -eq $PowerOnVMs) {
            Write-Log ""
            break
        } else {          
            $BrokerVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName
            $RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count
            $TS = New-TimeSpan -Start $Start -End (Get-Date)
            if ($TS.TotalMinutes -gt $VMRegistrationTimeOutMinutes) {
                throw "VMs failed to register within $VMRegistrationTimeOutMinutes minutes"
            }
        }
    }
}