function Start-LETest {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$testId,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$comment
    )

    $Body = [ordered]@{
        comment = $comment
    } | ConvertTo-Json
        
    try {
        $TestStart = Invoke-PublicApiMethod -Method "PUT" -Path "v6/tests/$testId/start" -Body $Body -ErrorAction Stop
    }
    catch {
        Write-Error -Message $_ -Level Error
        Break
    }
}
