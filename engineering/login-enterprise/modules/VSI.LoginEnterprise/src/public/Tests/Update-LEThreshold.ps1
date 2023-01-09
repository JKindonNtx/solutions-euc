function Update-LEThreshold {
    Param (
        $TestId,
        $Threshold,
        $NewThreshold
    )
 

    if ($Threshold.'$type' -eq "AppThreshold") {
        $Body = [ordered]@{
            applicationId = $Threshold.applicationId
            timer         = $Threshold.timer
            isEnabled     = $Threshold.isEnabled
            value         = $Threshold.value
        } | ConvertTo-Json

        $Response = Invoke-PublicApiMethod -Method "POST" -Path "v6/tests/$TestId/thresholds" -Body $Body

    }

    if ($Threshold.'$type' -eq "SessionThreshold") {

        $NewThreshold = (Get-LETests | Where-Object { $_.id -eq $NewTestId }).thresholds | Where-Object { $_.type -eq $Threshold.type }

        $Body = [ordered]@{
            isEnabled = $Threshold.isEnabled
            value     = $Threshold.value
        } | ConvertTo-Json

        $Response = Invoke-PublicApiMethod -Method "PUT" -Path "v6/tests/$TestId/thresholds/$($NewThreshold.id)" -Body $Body

    }


    $Response.id
}