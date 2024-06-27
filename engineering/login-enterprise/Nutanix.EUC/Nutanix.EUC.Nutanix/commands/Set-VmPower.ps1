function Set-VmPower {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VmUuid,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PowerState,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword
    )

    $Body = "{ `
            ""transition"": """ + $PowerState + """ `
        }"

    try {
        if ($TargetCVM) {
            $NTNXPower = Invoke-PublicApiMethodNTNX -Method "POST" -Path "vms/$($VmUuid)/set_power_state" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -Body $Body -ErrorAction Stop
        }
        else {
            $NTNXPower = Invoke-PublicApiMethodNTNX -Method "POST" -Path "vms/$($VmUuid)/set_power_state" -Body $Body -ErrorAction Stop
        }
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        #Break
    }
    
    return $NTNXPower
}