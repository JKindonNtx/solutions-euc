function Add-LEApplicationGroupStep {
    param(
        $ApplicationGroupName,
        $type,
        $applicationId,
        $runOnce,
        $leaveRunning,
        $isEnabled
    )
    $appGroup = Get-LEApplicationGroups -include "steps" | Where-Object { $_.Name -eq $ApplicationGroupName }

    $Body = @(@{
            type          = $type
            applicationId = $applicationId
            runOnce       = $runOnce
            leaveRunning  = $leaveRunning
            isEnabled     = $isEnabled
        }) | ConvertTo-Json

    $Response = Invoke-PublicApiMethod -Method "POST" -Path "v6/application-groups/$($appGroup.id)/steps" -Body $Body
    $Response.items
}