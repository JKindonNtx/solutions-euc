function Get-NTNXHostIPMI {
    
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$NTNXHost,
        [Parameter(Mandatory = $false)][String]$TargetCVM,
        [Parameter(Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(Mandatory = $false)][String]$TargetCVMPassword
    )

    try {
        if ($TargetCVM) {
            $NTNXHosts = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -ErrorAction Stop
        }
        else {
            $NTNXHosts = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts" -ErrorAction Stop
        }
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }
        
    $Hostitem = $NTNXHosts.entities | Where-Object { $_.name -eq $NTNXHost }
    $Response2 = $Hostitem.ipmi_address
    $Response2
}
