function Get-LEApplicationGroupSteps {
    Param(
        $ApplicationGroupName
    )
    Get-LEApplicationGroups -include "steps" | Where-Object { $_.Name -eq $ApplicationGroupName }
}