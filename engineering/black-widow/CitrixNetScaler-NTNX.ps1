
Param(
    $ConfigFile = ".\ExampleConfig.jsonc",
    [switch]$Force
)

If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
write-host "PSScript Root: $($PSScriptRoot)"

# Build module path and import all the PSM1 files
Remove-Module Citrix* -ErrorAction silentlycontinue
Remove-Module General* -ErrorAction silentlycontinue
Remove-Module Nutanix* -ErrorAction silentlycontinue

$ModulePath = Join-Path -Path $ScriptRoot -ChildPath "\modules\*.psm1"
$Modules = get-childitem -Path $ModulePath
foreach($module in $modules){ Write-Host "Importing - $module." ; import-module $module }

# Load test configuation file
if(test-path -path $ConfigFile){
    $RawConfig = Get-Content -Path $ConfigFile
    $SanitizedConfig = $RawConfig -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
    $TestConfig = $SanitizedConfig | ConvertFrom-Json
    write-progress -message "Config file $($ConfigFile) loaded"
} else {
    write-error -message "Configuration file not found, quitting"
    break
}

# Install Posh-SSH module. Required to connect to the NetScaler using SSH.
If ( -not (Get-InstalledModule Posh-SSH -ErrorAction silentlycontinue )) {
    write-progress -message "Installing Posh-SSH"
    Install-Module -Name Posh-SSH -RequiredVersion 2.3.0 -Confirm:$false -Force
    Import-Module Posh-SSH
} else {
    write-progress -message "Posh-SSH already installed"
    Import-Module Posh-SSH
}

# Validate connectivity and Black Widow presence on NetScaler
if(Initialize-NetScaler -IP $TestConfig.NetScaler.BlackWidowIP -UserName $TestConfig.NetScaler.BlackWidowUserName -Password $TestConfig.NetScaler.BlackWidowPassword){
    if(Get-BlackWidow -IP $TestConfig.NetScaler.BlackWidowIP -UserName $TestConfig.NetScaler.BlackWidowUserName -Password $TestConfig.NetScaler.BlackWidowPassword){
        write-good -message "Validated Black Widow on the NetScaler $($TestConfig.NetScaler.BlackWidowIP)"
        $BlackWidowNetScaler = $true
    } else {
        write-error -message "Validate Black Widow on the NetScaler and re-run test"
    }
} else {
    write-error -message "Validate connectivity to the NetScaler and re-run test"
}

# Validate connectivity and Target NetScaler
if(Initialize-NetScaler -IP $TestConfig.NetScaler.TargetIP -UserName $TestConfig.NetScaler.TargetUserName -Password $TestConfig.NetScaler.TargetPassword){
    write-good -message "Validated connectivity to the NetScaler $($TestConfig.NetScaler.TargetIP)"
    $TargetNetScaler = $true
} else {
    write-error -message "Validate connectivity to the Target NetScaler and re-run test"
}

if($BlackWidowNetScaler -and $TargetNetScaler){
    write-good -message "All pre-reqs in place, starting Black Widow test"

    # Get Test Duration
    $TestDuration = $TestConfig.General.TestDuration

    # Get Nutanix Information
    $NutanixInfrastructure = Get-NutanixInfo -Config $TestConfig
    $NetScalerHardware = Get-NetScalerHardware -Hostname $TestConfig.NetScaler.TargetIP -UserName $TestConfig.NetScaler.TargetUserName -Password $TestConfig.NetScaler.TargetPassword
    
    # Get a new Test ID 
    $TestId = New-TestId
    $Comment = $TestConfig.Test.Comment -Replace(" ", "_")
    $TestId = "$($TestId)_$($Comment)"
    write-progress -message "Test ID: $($TestId)"

    # Get the output folder
    $FolderName = "$($TestID)"
    $OutputFolder = Join-Path -Path $ScriptRoot -ChildPath "\results\$FolderName"
    write-progress -message "Output Folder: $($OutputFolder)"

    # Slack update
    $SlackMessage = "New Black Widow test started by $($TestConfig.General.ClusterUserName) on Cluster $($TestConfig.General.ClusterIP). Testname: $($TestId). Workload Type: $($TestConfig.BlackWidow.TestType), Threads: $($TestConfig.BlackWidow.Threads), Parallel Connections: $($TestConfig.BlackWidow.ParallelConnections)"
    Update-VSISlack -Message $SlackMessage -Slack $($TestConfig.General.Slack)

    # Start Test Monitoring Jobs
    $MonitoringDuration = $TestDuration + 1
    $NetScalerMonitoring = Start-NetScalerMonitoring -OutputFolder $OutputFolder -DurationInMinutes $MonitoringDuration -Path $Scriptroot -AsJob -NSIP $TestConfig.NetScaler.TargetIP -NSUserName $TestConfig.NetScaler.TargetUserName -NSPassword $TestConfig.NetScaler.TargetPassword -NSCollectionInterval $TestConfig.General.CollectionInterval 
    $VMMonitoring = Start-VMMonitoring -OutputFolder $OutputFolder -DurationInMinutes $MonitoringDuration -Path $Scriptroot -AsJob -IP $TestConfig.General.ClusterIP -UserName $TestConfig.General.ClusterUserName -Password $TestConfig.General.ClusterPassword -CollectionInterval $TestConfig.General.CollectionInterval -TargetVMIP $TestConfig.NetScaler.TargetIP

    write-progress -message "Waiting 60 seconds to begin test"
    start-sleep -seconds 60

    if(Start-BlackWidowServer -IP $TestConfig.NetScaler.BlackWidowIP -UserName $TestConfig.NetScaler.BlackWidowUserName -Password $TestConfig.NetScaler.BlackWidowPassword -BWServerIP $TestConfig.BlackWidow.ServerIP){
        write-good -message "Black Widow Server running on IP $($TestConfig.BlackWidow.ServerIP)"
        if(Start-BlackWidowClient -Config $TestConfig -IP $TestConfig.NetScaler.BlackWidowIP -UserName $TestConfig.NetScaler.BlackWidowUserName -Password $TestConfig.NetScaler.BlackWidowPassword -BWTargetIP $TestConfig.BlackWidow.TargetvServerIP){
            write-good -message "Black Widow Client is running targetting $($TestConfig.BlackWidow.TargetvServerIP)"
            write-good -message "Load Test $($TestId) Started for a duration of $($TestConfig.General.TestDuration) minutes"

            # Get test start time
            $StartTime = Get-Date
            
            [int]$CollectionInterval = $TestConfig.General.CollectionInterval 
            $TestFinished = $false   

            while(!($TestFinished -eq $true)){
                $CurrentTime = Get-Date
                $ElapsedTime = $CurrentTime - $StartTime
                if(!($ElapsedTime.TotalMinutes -ge $TestDuration)){
                    $Minutes = [math]::Round($ElapsedTime.TotalMinutes)
                    write-progress -message "$($TestId): $($Minutes) minutes of $($TestDuration) executed" -Update
                } else {
                    write-progress -message "Test Complete"
                    write-good -message "Test: $($TestId): finished"
                    $TestFinished = $true
                }
                Start-sleep -Seconds $CollectionInterval
            }

            if(Stop-BlackWidowClient -IP $TestConfig.NetScaler.BlackWidowIP -UserName $TestConfig.NetScaler.BlackWidowUserName -Password $TestConfig.NetScaler.BlackWidowPassword){
                write-good -message "Black Widow Client stopped on $($TestConfig.NetScaler.BlackWidowIP)"
                if(Stop-BlackWidowServer -IP $TestConfig.NetScaler.BlackWidowIP -UserName $TestConfig.NetScaler.BlackWidowUserName -Password $TestConfig.NetScaler.BlackWidowPassword){
                    write-good -message "Black Widow Server stopped on IP $($TestConfig.BlackWidow.ServerIP)"
                } else {
                    write-error -message "Could not stop the Black Widow Server"
                }
            } else {
                write-error -message "Could not stop the Black Widow Client"
            }

            # Stop Monitoring Jobs
            $NetScalerMonitoring | Stop-Job | Remove-Job  
            $VMMonitoring | Stop-Job | Remove-Job  

            # Update JSON with Test Information
            $NutanixInfrastructure.TestInfra.TestName = $TestId
            $NutanixInfrastructure.NetScalerData.Host = $NetScalerHardware.host
            $NutanixInfrastructure.NetScalerData.UUID = $NetScalerHardware.netscaleruuid
            $NutanixInfrastructure.NetScalerData.Description = $NetScalerHardware.hwdescription
            $Version = ($NetScalerHardware.version).Split(",")
            $NutanixInfrastructure.NetScalerData.Version = $Version[0]

            # Output TestConfig.json
            $NutanixInfrastructure | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputFolder\Testconfig.json -Force  
            
            # Upload Data
            write-progress -message "Uploading results to Influx DB"
            # Upload Config to Influx
            if($TestConfig.Test.UploadResults) {
                Start-InfluxUpload -influxDbUrl $TestConfig.General.InfluxDBurl -ResultsPath $OutputFolder -Token $TestConfig.General.InfluxToken
            }

            # Update Slack
            $SlackMessage = "Black Widow Test: $($TestId) finished on Cluster $($TestConfig.General.ClusterIP)."
            Update-VSISlack -Message $SlackMessage -Slack $($TestConfig.General.Slack)

            $FileName = Get-VSIGraphs -TestConfig $TestConfig -OutputFolder $OutputFolder -TestName $TestId
            if(test-path -path $Filename) {
                Update-VSISlackImage -ImageURL $FileName -SlackToken $TestConfig.General.SlackToken -SlackChannel $TestConfig.General.SlackChannel -SlackTitle "$($TestConfig.Test.Comment)" -SlackComment "Black Widows Results of $($TestConfig.Test.Comment)"
            }

            # Update Console
            write-good -message "Test $($TestId) Finished"
            write-good -message "Results can be found here: $($OutputFolder)"

        } else {
            write-error -message "Could not start Black Widow Client"
        }
    } else {
        write-error -message "Could not start Black Widow Server"
    }
} else {
    write-error -message "There was an error validating the environment for the Black Widow test run"
    write-error -message "Please resolve errors and re-run test"
}