function Start-LETest {
    Param (
        $testId,
        $comment
    )

    $Body = [ordered]@{
        comment = $comment
    } | ConvertTo-Json
    
    Invoke-PublicApiMethod -Method "PUT" -Path "v6/tests/$testId/start" -Body $Body
    
}
