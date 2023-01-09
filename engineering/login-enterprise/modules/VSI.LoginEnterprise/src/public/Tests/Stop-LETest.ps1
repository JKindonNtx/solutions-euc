function Stop-LETest {
    Param (
        $testId
    )

    $Response = Invoke-PublicApiMethod -Method "PUT" -Path "v6/tests/$testId/stop" 
    $Response
}