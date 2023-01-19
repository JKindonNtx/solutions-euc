function Remove-LEApplications {
    Param (
        [Parameter(Mandatory = $true)]
        $ids
    )

    $Body = ConvertTo-Json @($ids) 
    $Response = Invoke-PublicApiMethod -Method "DELETE" -Path "v6/applications" -Body $Body
    $Response.id
}