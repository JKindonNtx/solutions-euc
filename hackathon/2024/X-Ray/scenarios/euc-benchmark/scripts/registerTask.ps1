param(
    $unixTime = 1681318691,
    [int32]$timeOffset = 28800,
    $taskPath = "\",
    $taskName = "Startworkload",
    $execute = "powershell.exe",
    $argument = "-WindowStyle Hidden -file C:\scripts\start-workload.ps1",
    $workingDirectory = "C:\Scripts\",
    $user = "nutanix"
)

$when = ((Get-Date) + ([TimeSpan]::FromSeconds(15)))
$trigger = New-ScheduledTaskTrigger -once -at $when
$action = New-ScheduledTaskAction -execute $execute -argument $argument -WorkingDirectory $workingDirectory
Register-ScheduledTask -TaskName $taskName -Trigger $trigger -User $user -Action $action -RunLevel Highest -TaskPath $taskPath