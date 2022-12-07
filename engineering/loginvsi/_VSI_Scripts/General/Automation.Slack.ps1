Function Slack-Start {
    ##############################
    #.SYNOPSIS
    #Send update to Slack
    #
    #.DESCRIPTION
    #Send update to Slack 
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
    #Slack-Start -Config $Config -VsiWorkload $vsiWorkload -VsiSessions $vsiSessions
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config,
        [string]$VsiWorkload,
        [string]$VsiSessions

    )

    $vsiWorkload = $vsiWorkload.Replace("_", "\_")
    $testName = $($config.TestName).Replace("_", "\_")


    $body = ConvertTo-Json -Depth 4 @{
        username = "LoginVSI - $($config.Datacenter)"
        attachments = @(
            @{
                fallback = "New test initiated on $($config.TargetHost)."
                color = "#36a64f"
                pretext = "New test initiated on $($config.TargetHost)"
                fields = @(
                    @{
                        title = "Testname"
                        value = $testName
                    }
                    @{
                        title = "Hardware Type"
                        value = $($config.HardwareType)
                        short = "true"
                    }
                    @{
                        title = "CPU Type"
                        value = $($config.CPUType)
                        short = "true"
                    }
                    @{
                        title = "Number of runs configured"
                        value = $($config.Runs)
                        short = "true"
                    }
                    @{
                        title = "Node count"
                        value = $($config.NodeCount)
                        short = "true"
                    }
                    @{
                        title = "Target OS"
                        value = $($config.TargetOS)
                        short = "true"
                    }
                    @{
                        title = "Number of sessions"
                        value = $vsiSessions
                        short = "true"
                    }
                    @{
                        title = "Hypervisor type"
                        value = $($config.HostingType)
                        short = "true"
                    }
                    @{
                        title = "CVM present on the host"
                        value = "$($config.CVMpresent)"
                        short = "true"
                    }
                    @{
                        title = "VSI Workload"
                        value = $vsiWorkload
                        short = "true"
                    }
                    @{
                        title = "CVM disabled during test?"
                        value = "$($config.CVMDisabled)"
                        short = "true"
                    }
                    @{
                        title = "Desktop Delivery Solution"
                        value = $($config.DeliveryType)
                        short = "true"
                    }
                    @{
                        title = "Desktop Poolname"
                        value = $($config.PoolName)
                        short = "true"
                    }
                    @{
                        title = "Capture Host data"
                        value = "$($config.CaptureHostData)"
                        short = "true"
                   }
                    @{
                        title = "Capture Launchers data"
                        value = "$($config.CaptureLaunchersData)"
                        short = "true"
                   }
                )
            }
        )
        
    }

    $RestError = $null
    Try {
        Invoke-RestMethod -uri $($config.Slack) -Method Post -body $body -ContentType 'application/json' | Out-Null
    } Catch {
      $RestError = $_
    }
}

Function Slack-Boot {
    ##############################
    #.SYNOPSIS
    #Send boottime to Slack
    #
    #.DESCRIPTION
    #Send boottime to Slack 
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
    #Slack-Boot -Config $Config -Boot $Boottime
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config,
        [string]$Boottime

    )
    
    $testName = $($config.TestName).Replace("_", "\_")
    $body = ConvertTo-Json @{
        username = "LoginVSI - $($config.Datacenter)"
        attachments = @(
            @{
                fallback = "Reporting boottime."
                color = "#36a64f"
                pretext = "*Reporting boottime*"
                title = $testName
                text = "Boottime was $($boottime)"  
            }
        )
    }
    $RestError = $null
    Try {
        Invoke-RestMethod -uri $($config.Slack) -Method Post -body $body -ContentType 'application/json' | Out-Null
    } Catch {
      $RestError = $_
    }
}

Function Slack-Update {
    ##############################
    #.SYNOPSIS
    #Send update to Slack
    #
    #.DESCRIPTION
    #Send update to Slack 
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
    #Slack-Update -Config $Config -Run $run
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config,
        [string]$Run

    )
    
    $testName = $($config.TestName).Replace("_", "\_")
    $body = ConvertTo-Json @{
        username = "LoginVSI - $($config.Datacenter)"
        attachments = @(
            @{
                fallback = "Status of running test."
                color = "#36a64f"
                pretext = "*Status of running test*"
                title = $testName
                text = "Currently in run $($run) of $($config.Runs)"   
            }
        )
    }
    $RestError = $null
    Try {
        Invoke-RestMethod -uri $($config.Slack) -Method Post -body $body -ContentType 'application/json' | Out-Null
    } Catch {
      $RestError = $_
    }
}

Function Slack-Done {
    ##############################
    #.SYNOPSIS
    #Send update to Slack
    #
    #.DESCRIPTION
    #Send update to Slack 
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
    #Slack-Update -Config $Config -Run $run
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config
    )
    
    $testName = $($config.TestName).Replace("_", "\_")
    $body = ConvertTo-Json @{
        username = "LoginVSI - $($config.Datacenter)"
        attachments = @(
            @{
                fallback = "Tests are complete!"
                color = "#36a64f"
                pretext = "*Status of running test*"
                title = "$testName"
                text = "*Tests are complete!*"
            }
        )
    }
    $RestError = $null
    Try {
        Invoke-RestMethod -uri $($config.Slack) -Method Post -body $body -ContentType 'application/json' | Out-Null
    } Catch {
      $RestError = $_
    }
}

Function Slack-ResultJPG {
    ##############################
    #.SYNOPSIS
    #Send JPGresult to Slack
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
    #Slack-ResultJPG -Config $Config -testNameRun $testNameRun -Run $run
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config,
        [string]$testNameRun,
        [string]$Run
    )
    
    $testName = $($testnameRun).Replace("_", "\_")
    $VSIfilename = $testNameRun -split '_run_'
    $Testresult = import-csv "$($config.Share)\_VSI_Logfiles\$($TestnameRun)\VSI_Result_Run$($VSIfilename[1]).csv"
    $GitURL = $config.gitURL
    $body = ConvertTo-Json -Depth 4 @{
        username = "LoginVSI - $($config.Datacenter)"
        attachments = @(
            @{
                fallback = "Test result from test $TestName is in!"
                color = "#36a64f"
                pretext = "Test result from test $TestName is in:"
                fields = @(
                    @{
                        title = "CPU type"
                        value = $($config.CPUType)
                        short = "true"
                        }
                    @{
                            title = "Number of nodes"
                            value = "$($config.NodeCount)"
                            short = "true"
                        }
                    @{
                            title = "Target OS"
                            value = "$($config.TargetOS)"
                            short = "true"
                        }
                    @{
                        title = "vCPUs per VM"
                        value = "$($config.VMCPUCount)"
                        short = "true"
                        }
                    @{
                        title = "VSIMax"
                        value = $($Testresult.VSIMax)
                        short = "true"
                        }
                    @{
                        title = "VSIBase"
                        value = $($TestResult.BaseLine)
                        short = 'true'
                        }
                )
                image_url = "https://$($gitURL)/raw/main/$($TestnameRun).png"
            }
        )
    
    }
       
    $RestError = $null
    Try {
        Invoke-RestMethod -uri $($config.Slack) -Method Post -body $body -ContentType 'application/json' | Out-Null
    } Catch {
    $RestError = $_
    }
}

Function Slack-Results {
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
    #Slack-Results -Config $Config -Run $run
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config
    )
    
    $testName = $($config.TestName).Replace("_", "\_")
    $GitURL = $config.gitURL
    $body = ConvertTo-Json -Depth 4 @{
        username = "LoginVSI - $($config.Datacenter)"
        attachments = @(
            @{
                fallback = "Test results from test $TestName are in!"
                color = "#36a64f"
                pretext = "Test results from test *$TestName* on hardware type $($config.hardwaretype):"
                fields = @(
                    @{
                        title = "CPU type"
                        value = $($config.CPUType)
                        short = "true"
                        }
                    @{
                            title = "Number of nodes"
                            value = "$($config.NodeCount)"
                            short = "true"
                        }
                    @{
                            title = "Target OS"
                            value = "$($config.TargetOS)"
                            short = "true"
                        }
                    @{
                        title = "CVM powered off during test?"
                        value = "$($config.CVMDisabled)"
                        short = "true"
                        }
                    $Finalresults = import-csv "$($config.Share)\_VSI_Results\$($config.TestName)\$($config.TestName).csv" | Sort-Object VSImaxReached
                    $averageVsiMax = $Finalresults.VSImax | Measure-Object -Average
                    $averageBaseline = $Finalresults.BaseLine | Measure-Object -Average
                    ForEach ($result in $Finalresults){
                        $Testrun = $($result.TestName)
                        $Testrun = $Testrun -replace "$($Config.TestName)" -replace "_"
                        $VSIMax = $($result.VSIMax)
                        $BaseLine = $($result.BaseLine)
                      @{
                        title = "$Testrun - VSIMax"
                        value = $VSIMax
                        short = "true"
                        }
                      @{
                        title = "VSIBase"
                        value = $BaseLine
                        short = 'true'
                        }
                    }
                    @{
                        title = "Average - VSImax"
                        value = "$($averageVsiMax.Average)"
                        short = 'true'
                    }
                    @{
                        title = "Average - Baseline"
                        value = "$($averageBaseline.Average)"
                        short = 'true'
                    }
                )
                image_url = "https://$($gitURL)/raw/main/$($config.TestName)-CPU.png"
            }
        )
    
    }
   
    $RestError = $null
    Try {
        Invoke-RestMethod -uri $($config.Slack) -Method Post -body $body -ContentType 'application/json' | Out-Null
    } Catch {
    $RestError = $_
    }
}