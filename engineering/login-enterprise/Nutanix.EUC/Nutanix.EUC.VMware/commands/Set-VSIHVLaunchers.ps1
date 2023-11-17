function Set-VSIHVLaunchers {
    param(
        $Amount,
        $vCenterServer,
        $vCenterUser,
        $vCenterPass,
        $CustomizationSpec,
        $ParentVM,
        $Snapshot,
        $VMHost,
        $Datastore,
        $NamingPattern = "Launcher_",
        [switch]$Force
    )

    Write-Log -Message "Setting up launchers" -Level Info
    $vCenter = VMware.VimAutomation.Core\Connect-VIServer -Server $vCenterServer -User $vCenterUser -Password $vCenterPass
    

    $TemplateVM = VMware.VimAutomation.Core\Get-VM -Name $ParentVM
    $Snapshot = VMware.VimAutomation.Core\Get-Snapshot -VM $TemplateVM -Name $Snapshot
    
    $ExistingLaunchers = VMware.VimAutomation.Core\Get-VM -Name "$($namingPattern)*" | Where-Object { $_.VMHost.Name -eq $VMHost }
    $ExistingLauncherCount = ($ExistingLaunchers | Measure-Object).Count

    if ($Force) {
        Foreach ($vm in $ExistingLaunchers) {
            $vm | VMware.VimAutomation.Core\Stop-VM -Kill -Confirm:$false -ErrorAction Ignore | Out-Null
            $vm | VMware.VimAutomation.Core\Remove-VM -DeletePermanently -Confirm:$false | Out-Null
        }
        $ExistingLauncherCount = 0
    }
    
    if ($ExistingLauncherCount -lt $Amount) {
        for ($i = $ExistingLauncherCount + 1; $i -le $Amount; $i++) {
            $VM = VMware.VimAutomation.Core\New-VM -LinkedClone -Name "$($NamingPattern)$i" -VMHost (VMware.VimAutomation.Core\Get-VMHost $VMHost) -Datastore (VMware.VimAutomation.Core\Get-Datastore -Name $Datastore) -ReferenceSnapshot $Snapshot -VM $TemplateVM -OSCustomizationSpec (VMware.VimAutomation.Core\Get-OSCustomizationSpec -Name $CustomizationSpec)
            #$VM | VMware.VimAutomation.Core\Start-VM -Confirm:$False | Out-Null
        }
    }
    elseif ($ExistingLauncherCount -gt $Amount) {
        for ($i = $ExistingLauncherCount; $i -gt $Amount; $i--) {
            $vm = $null
            $vm = VMware.VimAutomation.Core\Get-VM -Name "$($NamingPattern)$i" -ErrorAction SilentlyContinue
            if ($null -ne $vm) {
                $res = $vm | VMware.VimAutomation.Core\Stop-VM -Kill -Confirm:$false -ErrorAction Ignore
                $res = $vm | VMware.VimAutomation.Core\Remove-VM -DeletePermanently -Confirm:$false
            }
        }
    }
    
    $VMS = VMware.VimAutomation.Core\Get-VM -Name "$($NamingPattern)*" -ErrorAction SilentlyContinue
    $VMS | VMware.VimAutomation.Core\Stop-VM -Kill -Confirm:$false -ErrorAction Ignore -WarningAction SilentlyContinue | Out-Null
    $VMS | VMware.VimAutomation.Core\Start-VM -Confirm:$false -ErrorAction Ignore -WarningAction SilentlyContinue | Out-Null
}