function Get-LEApplicationGroups {

    [CmdletBinding()]

    Param (
        $include = "none"
    )

    $Body = @{
        orderBy   = "Name"
        direction = "Asc"
        count     = "5000"
        include   = $include
    }
        
    try {
        $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/application-groups" -Body $Body
        $Response.items
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }
        
}
