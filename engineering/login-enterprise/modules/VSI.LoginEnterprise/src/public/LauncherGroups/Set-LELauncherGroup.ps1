function Set-LELauncherGroup {
    param(
        $LauncherGroupName,
        $NamingPattern
    )
    $ExistingLauncherGroup = Get-LELauncherGroups | Where-Object { $_.name -eq $LauncherGroupName }
    if ($null -ne $ExistingLauncherGroup) {
        Remove-LELauncherGroups -ids $ExistingLauncherGroup.id
    }
    $NamingPattern = $NamingPattern -replace "_", ""
    $launcherNames = Get-LELaunchers | Where-Object { $_.machineName -like "$($NamingPattern)*" } | Select-Object -ExpandProperty machineName
    New-LELauncherGroup -Name $LauncherGroupName -LauncherNames $LauncherNames | Out-Null
}