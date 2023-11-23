function Get-NTNXHostIPMI {
    Param (
        $NTNXHost
    )
    
    $NTNXHosts = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts"
    $Hostitem = $NTNXHosts.entities | Where-Object {$_.name -eq $NTNXHost}
    $Response2 = $Hostitem.ipmi_address
    $Response2
}