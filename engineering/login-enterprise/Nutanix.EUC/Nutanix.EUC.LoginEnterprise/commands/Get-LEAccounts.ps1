function Get-LEAccounts {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$orderBy = "Username",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Direction = "asc",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][int32]$Count = 10000,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Include = "none"
    )

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include
    }
    try {
        $Response = Invoke-PublicApiMethod -Path 'v6/accounts' -Method 'GET' -Body $Body -ErrorAction Stop
        $Response.items
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }
        
    $Response.items

}
