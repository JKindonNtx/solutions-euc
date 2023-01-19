function New-LEApplicationGroup {
    Param (
        [string]$name,
        [string]$description
    )

    $Body = @{
        name        = $name
        description = $description
        steps       = $null
    } | ConvertTo-Json


    $Response = Invoke-PublicApiMethod -Method "POST" -Path "v6/application-groups" -Body $Body
    $Response.id
}