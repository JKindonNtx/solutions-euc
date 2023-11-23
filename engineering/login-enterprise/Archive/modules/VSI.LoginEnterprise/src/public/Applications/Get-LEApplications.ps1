function Get-LEApplications {

    $Body = @{
        orderBy   = "name"
        direction = "asc"
        count     = 10000
        include   = "none"
    }

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/applications" -Body $Body
    $Response.items
}