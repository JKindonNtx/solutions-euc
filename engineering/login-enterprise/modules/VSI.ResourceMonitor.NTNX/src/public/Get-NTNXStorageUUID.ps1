function Get-NTNXstorageUUID {
    Param (
        $Storage
    )
    
    $Containerinfo = Invoke-PublicApiMethodNTNX -Method "GET" -Path "storage_containers"
    $Containeritem = $Containerinfo.entities | Where-Object {$_.name -eq $Storage}
    $Response = ($Containeritem.id.split(":"))[2]
    $Response
}