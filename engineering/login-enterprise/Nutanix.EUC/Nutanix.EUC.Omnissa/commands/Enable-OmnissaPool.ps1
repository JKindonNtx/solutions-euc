function Enable-OmnissaPool {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$CloneType,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword,
        $Affinity,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$HypervisorType,
        $ForceAlignVMToHost,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VMnameprefix,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$hosts,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Run,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$CVMsshpassword
    )

    $Boot = "" | Select-Object -Property bootstart,boottime

    if ($CloneType -eq "Manual") {
        $ExistingPool = Get-OmnissaDesktopPools -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -PoolName $PoolName
        $PoolMachines = Get-OmnissaMachinesPool -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -PoolID $ExistingPool.id
        $PoolMachineCount = $PoolMachines | Measure-Object
        $i = 1
        foreach ($VM in $PoolMachines) {
            $VmFqdn = $VM.name
            $VmSplit = $VmFqdn.Split(".")
            $VmNetbiosName = $VmSplit[0]
            $CurrentVM = Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq "$($VmNetbiosName)" }
            Write-Log -Update -Message "Reverting Machine $($i) of $($PoolMachineCount.Count) to Snapshot." -Level Info
            Revert-NTNXSnapshot -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -VmUuid $CurrentVM.uuid
            $i++
        }
    } else {
        # Placeholder for automated Omnissa Pool types
    }

    $ForceRunNumberForAffinity = 1
    if (($HypervisorType) -eq "AHV" -And ($Affinity) -and (-not $ForceAlignVMToHost)) {
        Write-Log "Hypervisortype = $HypervisorType and Single Node Affinity is set to $Affinity"
        $params = @{
            ClusterIP      = $TargetCVM
            CVMsshpassword = $CVMSSHPassword
            VMnameprefix   = $VMnameprefix
            hosts          = $hosts
            Run            = $ForceRunNumberForAffinity
        }
        $AffinityProcessed = Set-AffinitySingleNode @params
        $Params = $null
    }

    $Boot.bootstart = get-date -format o
    Start-Sleep -Seconds 10
    $BootStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Log -Message "Powering on Omnissa machines" -Level Info

    if ($CloneType -eq "Manual") {
        $i = 1
        foreach ($VM in $PoolMachines) {
            Write-Log -Update -Message "Turning On Machine $($i) of $($PoolMachineCount.Count)." -Level Info
            $VmFqdn = $VM.name
            $VmSplit = $VmFqdn.Split(".")
            $VmNetbiosName = $VmSplit[0]
            $CurrentVM = Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq "$($VmNetbiosName)" }
            $var_Power_Result = Set-VmPower -VmUuid $CurrentVM.uuid -PowerState "ON" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword
            $i++
        }

        Write-Log -Message "Waiting for VMs to register with Omnissa - Please wait" -Level Info
        do {
            Write-Log -Update -Message "Still waiting for VMs to register with Omnissa - Please wait" -Level Info
            $Unregistered = ((Get-OmnissaMachinesPool -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -PoolID $ExistingPool.id | Where-Object { $_.state -ne "AVAILABLE" }) | Measure-Object).Count
            Start-Sleep -Seconds 1
        } While ($Unregistered -ne 0)

    } else {
        # Placeholder for automated Omnissa Pool types
    }

    $BootStopwatch.stop()
    $Boot.boottime = $BootStopwatch.elapsed.totalseconds
    
    Return $boot
}