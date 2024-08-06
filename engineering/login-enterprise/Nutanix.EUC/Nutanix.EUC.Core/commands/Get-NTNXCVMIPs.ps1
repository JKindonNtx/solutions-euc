function Get-NTNXCVMIPs {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][System.Object]$Config
    )

    try {
        $HostData = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts" -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Error
        Exit 1
    }
        
    $Hosts = $Hostdata.entities
    $HostCVMips = @()

    foreach ($item in $Hosts) {
        $HostCVMips += $item.service_vmexternal_ip
        write-host $item.service_vmexternal_ip
    }

    return $HostCVMips

}
