Function write-log {
    <#
       .Synopsis
       Write logs for debugging purposes
       
       .Description
       This function writes logs based on the message including a time stamp for debugging purposes.
    #>
    param (
        $message,
        $sev = "INFO"
    )
    if ($sev -eq "INFO") {
        write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
    }
    elseif ($sev -eq "WARN") {
        write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
    }
    elseif ($sev -eq "ERROR") {
        write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
    }
    elseif ($sev -eq "CHAPTER") {
        write-host "`n`n### $message`n`n"
    }
} 
 
# Importing MDT DB modules
#$loadedmodules = (Get-module | Select-Object name).name
#if (!($loadedmodules.Contains("*BDD*"))) {
#     Import-Module C:\Temp\Microsoft.BDD.PSSnapIn.dll -force
#    write-log -message "Loading the MDT BDD Powershell module"
#}
#else {
#    write-log -message "MDT BDD module already loaded"
#}


Import-Module C:\Temp\MicrosoftDeploymentToolkit.psd1
Add-PSSnapin "Microsoft.BDD.PSSNAPIN"

$target = "KBTestVM503"
$deploymentShare = "\\CONTMAUT001\MDTLoginVSI$"


If (!(Test-Path MDT:)) { New-PSDrive -Name MDT -Root $deploymentShare -PSProvider Microsoft.BDD.PSSNAPIN\MDTPROVIDER }


Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $target } 

Write-Host "Waiting for task sequence to complete."
If ((Test-Path variable:InProgress) -eq $True) { Remove-Variable -Name InProgress }
Do {
    $InProgress = Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $target }
    If ( $InProgress.PercentComplete -lt 100 ) {
        If ( $InProgress.StepName.Length -eq 0 ) { $StatusText = "Waiting for update" }
        Start-Sleep -Seconds 5
        }
    Else {
        Write-Progress -Activity "Task sequence complete" -Status $StatusText -PercentComplete 100
    }
    }
Until ($InProgress.CurrentStep -eq $InProgress.TotalSteps)
Write-Host "Task sequence complete."




