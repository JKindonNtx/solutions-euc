function Get-LEAccountGroups {

    [CmdletBinding()]

    Param (
        [Parameter(mandatory = $false)][string]$orderBy = "name",
        [Parameter(mandatory = $false)][string]$Direction = "asc",
        [Parameter(mandatory = $false)][Int32]$Count = 10000,
        [Parameter(mandatory = $false)][string]$Include = "none"
    )

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include
    }

    try {
        $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/account-groups" -Body $Body -ErrorAction Stop
        $Response.items
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }

}
