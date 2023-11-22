function Get-NTNXHostUUID {
    Param (
        $NTNXHost
    )
    
    $NTNXHosts = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts"
    $Hostitem = $NTNXHosts.entities | Where-Object {$_.name -eq $NTNXHost}
    $Response = $Hostitem.uuid
    $Response
}
