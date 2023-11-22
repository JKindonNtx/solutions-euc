function Get-LEApplicationGroups {
    param(
        $include = "none"
    )

    $Body = @{
        orderBy   = "Name"
        direction = "Asc"
        count     = "5000"
        include   = $include
    }

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/application-groups" -Body $Body
    $Response.items
}