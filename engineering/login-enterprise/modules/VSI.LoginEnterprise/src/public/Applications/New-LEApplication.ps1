function New-LEApplication {
    Param (
        [string]$commandline,
        [string]$name,
        [string]$description
    )

    $Body = @{
        type        = "WindowsApp"
        commandline = $commandline
        id          = New-Guid
        name        = $name
        description = $description
    } | ConvertTo-Json


    $Response = Invoke-PublicApiMethod -Method "POST" -Path "v6/applications" -Body $Body
    $Response.id
}