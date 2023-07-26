Function Update-VSISlackresults {
    ##############################
    #.SYNOPSIS
    #Send results to Slack
    #
    #.DESCRIPTION
    #Send results to Slack 
    #
    #.PARAMETER TestName
    #Defines the used testname
    #
    #.PARAMETER Share
    #Location of the Login VSI share
    #
    #.PARAMETER Workload
    #Configured Login VSI workload
    #
    #.EXAMPLE
    #Update-VSISlackesults -TestName "Testname" -Path $Path
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$TestName,
        [string]$Path
    )
    $configfile = "$($Path)\Testconfig.json"
    $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
    $body = ConvertTo-Json -Depth 4 @{
        username = "LoginVSI - $($config.TestInfra.Datacenter)"
        attachments = @(
            @{
                fallback = "Test results from test $TestName are in!"
                color = "#36a64f"
                pretext = "Test results from test *$TestName* on hardware type $($config.TestInfra.hardwareType):"
                fields = @(
                    @{
                        title = "Cluster Name"
                        value = "$($config.TestInfra.ClusterName)"
                        short = "true"
                        }
                    @{
                            title = "Number of nodes"
                            value = "$($config.Target.NodeCount)"
                            short = "true"
                        }
                    @{
                            title = "CPU Type"
                            value = "$($config.TestInfra.CPUBrand) $($config.TestInfra.CPUType)"
                            short = "true"
                        }
                    @{
                        title = "Broker"
                        value = "$($config.Target.DeliveryType)"
                        short = "true"
                        }
                    @{
                            title = "Target OS"
                            value = "$($Config.Target.ImagesToTest.TargetOS) $($Config.Target.ImagesToTest.TargetOSVersion)"
                            short = "true"
                        }
                    @{
                        title = "Comment"
                        value = "$($Config.Target.ImagesToTest.Comment)"
                        short = "true"
                        }
                    $Finalresults = import-csv "$($Path)\testresults\$TestName\VSI-results.csv" | Sort-Object started
                    $averageVsiMax = $Finalresults.vsiMax | Where-Object { $_ -ne "" } | ForEach-Object { $_.Replace(" ","") } | Measure-Object -Average
                    $averageEUX = $($Finalresults."EUX score") | Measure-Object -Average
                    ForEach ($result in $Finalresults){
                        $Testrun = $($result.Comment)
                        $Testrun = $Testrun -replace "-$($Config.Target.ImagesToTest.Comment)"
                        $EUXBase = (Import-Csv -path "$($Path)\results\$Testrun\EUX-score.csv").EUXScore[1]
                        $Testrun = $Testrun -replace "$TestName" -replace "_"
                        $VSIMax = $($result.vsiMax)
                        if ($VSIMax -eq $null) {
                            $VSIMax = "Not reached"
                        }
                        $VSIMaxState = $($result."vsiMax state")
                        $EUX = $($result."EUX score")
                        $ActiveSessions = $($result.activesessionCount)
                        $TotalLogins = $($result."login total")
                      @{
                        title = "$Testrun-VSIMax"
                        value = $VSIMax
                        short = "true"
                        }
                      @{
                        title = "$Testrun-VSIMax state"
                        value = $VSIMaxState
                        short = 'true'
                        }
                      @{
                        title = "$Testrun-EUXBase"
                        value = $EUXBase
                        short = 'true'
                        }
                      @{
                        title = "$Testrun-EUX"
                        value = $EUX
                        short = 'true'
                        }
                      @{
                        title = "$Testrun-Active Sessions"
                        value = $ActiveSessions
                        short = "true"
                        }
                      @{
                        title = "$Testrun-Total Logins"
                        value = $TotalLogins
                        short = 'true'
                        }
                    }
                    @{
                        title = "Average - VSImax"
                        value = "$($averageVsiMax.Average)"
                        short = 'true'
                    }
                    @{
                        title = "Average - EUX"
                        value = "$($averageEUX.Average)"
                        short = 'true'
                    }
                )
            }
        )
    
    }
   
    $RestError = $null
    Try {
        Invoke-RestMethod -uri $($config.TestInfra.Slack) -Method Post -body $body -ContentType 'application/json' | Out-Null
    } Catch {
    $RestError = $_
    }
}