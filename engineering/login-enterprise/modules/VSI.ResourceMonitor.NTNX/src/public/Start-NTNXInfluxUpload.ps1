function Start-NTNXInfluxUpload {
    param(
        [Parameter(Mandatory = $true)] [string]$influxDbUrl,
        [Parameter(Mandatory = $true)] [string]$ResultsPath,
        [Parameter(Mandatory = $true)] [string]$Token,
        [Parameter(Mandatory = $true)] [Bool]$Boot
    )

    # Read in JSON File
    $JSONFile = Join-Path $ResultsPath "TestConfig.json"
    $JSON = Get-Content -Path $JSONFile -Raw | ConvertFrom-Json

    $MeasurementName = $($JSON.TestInfra.TestName)
    $MeasurementDetail = $MeasurementName -Split '_Run'
    $MeasurementName = $MeasurementDetail[0]

    $Run = $MeasurementDetail[1]

    $WebHeaders = @{
                        Authorization = "Token $Token"
                }

    $vsiresult = Import-CSV "$($ResultsPath)\VSI-results.csv"
    ## set fixed start date
    ## calc time diff with measurement start date
    ## Subtract time diff from timestamp
    $StartDate = [DateTime] "01/01/2023 1:00 AM"
    $UnixStartedDate = Get-Date -Date $StartDate -UFormat %s
    $NewStartDate = $UnixStartedDate.Split(".")
    $FormattedStartDate = $NewStartDate[0]


    If ($Boot -eq $true){
        $Files = Get-ChildItem "$($ResultsPath)\Boot\*.csv"
        $Started = $($JSON.TestInfra.Bootstart)
        If ($($JSON.Test.BucketName) -eq "LoginDocuments") {
            $BucketName = "BootBucket"
        } Else {
            $BucketName = "BootBucketRegression"
        }
    }
    Else {
        $Files = Get-ChildItem "$($ResultsPath)\*.csv"
        $Started = $vsiresult.started
        $BucketName = $($JSON.Test.BucketName)
    }

    $UnixStarted = Get-Date -Date $Started -UFormat %s
    $NewStarted = $UnixStarted.Split(".")
    $FormattedStarted = $NewStarted[0]
    $DeltaTime = $FormattedStarted - $FormattedStartDate
    
    $influxDbUrl = $influxDbUrl + "&bucket=$($BucketName)"
    
    $CurrentYear = get-date -Format yyyy
    $CurrentMonth = get-date -Format MM

    foreach($File in $Files){
        if(($File.Name -like "Raw Timer Results*") -or ($File.Name -like "Raw Login Times*") -or ($File.Name -like "NetScaler Raw*") -or ($File.Name -like "host raw*") -or ($File.Name -like "files raw*") -or ($File.Name -like "cluster raw*") -or ($File.Name -like "raw appmeasurements*") -or ($File.Name -like "EUX-Score*")){
            $TopLevelTag = $File.BaseName
            $Tag = ("Run=$($Run)," +
                    "DataType=$($TopLevelTag)," +
                    "Year=$($CurrentYear)," +
                    "Month=$($CurrentMonth)," +
                    "DocumentName=$($JSON.Test.DocumentName)," +
                    "DeliveryType=$($JSON.Target.DeliveryType)," +
                    "DesktopBrokerVersion=$($JSON.Target.DesktopBrokerVersion)," +
                    "DesktopBrokerAgentVersion=$($JSON.Target.DesktopBrokerAgentVersion)," +
                    "CloneType=$($JSON.Target.CloneType)," +
                    "SessionCfg=$($JSON.Target.SessionCfg)," +
                    "SessionsSupport=$($JSON.Target.SessionsSupport)," +
                    "NodeCount=$($JSON.Target.NodeCount)," +
                    "Workload=$($JSON.Target.Workload)," +
                    "NumCPUs=$($JSON.Target.ImagesToTest.NumCpus)," +
                    "NumCores=$($JSON.Target.ImagesToTest.NumCores)," +
                    "MemoryGB=$($JSON.Target.ImagesToTest.MemoryGB)," +
                    "SecureBoot=$($JSON.Target.ImagesToTest.SecureBoot)," +
                    "vTPM=$($JSON.Target.ImagesToTest.vTPM)," +
                    "CredentialGuard=$($JSON.Target.ImagesToTest.CredentialGuard)," +
                    "AutocalcVMs=$($JSON.Target.ImagesToTest.AutocalcVMs)," +
                    "Max=$($JSON.Target.ImagesToTest.Max)," +
                    "NumberOfSessions=$($JSON.Target.ImagesToTest.NumberOfSessions)," +
                    "NumberOfVMs=$($JSON.Target.ImagesToTest.NumberOfVMs)," +
                    "TargetOS=$($JSON.Target.ImagesToTest.TargetOS)," +
                    "TargetOSVersion=$($JSON.Target.ImagesToTest.TargetOSVersion)," +
                    "OfficeVersion=$($JSON.Target.ImagesToTest.OfficeVersion)," +
                    "ToolsGuestVersion=$($JSON.Target.ImagesToTest.ToolsGuestVersion)," +
                    "OptimizerVendor=$($JSON.Target.ImagesToTest.OptimizerVendor)," +
                    "OptimizationsVersion=$($JSON.Target.ImagesToTest.OptimizationsVersion)," +
                    "GPUProfile=$($JSON.Target.ImagesToTest.GPUProfile)," +
                    "Comment=$($JSON.Target.ImagesToTest.Comment)," +
                    "InfraSSDCount=$($JSON.TestInfra.SSDCount)," +
                    "InfraSingleNodeTest=$($JSON.TestInfra.SingleNodeTest)," +
                    "InfraTestName=$($JSON.TestInfra.TestName)," +
                    "InfraHardwareType=$($JSON.TestInfra.HardwareType)," +
                    "InfraFullVersion=$($JSON.TestInfra.FullVersion)," +
                    "InfraCPUBrand=$($JSON.TestInfra.CPUBrand)," +
                    "InfraCPUType=$($JSON.TestInfra.CPUType)," +
                    "InfraAOSVersion=$($JSON.TestInfra.AOSVersion)," +
                    "InfraHypervisorBrand=$($JSON.TestInfra.HypervisorBrand)," +
                    "InfraHypervisorVersion=$($JSON.TestInfra.HypervisorVersion)," +
                    "InfraHypervisorType=$($JSON.TestInfra.HypervisorType)," +
                    "InfraBIOS=$($JSON.TestInfra.BIOS)," +
                    "InfraTotalNodes=$($JSON.TestInfra.TotalNodes)," +
                    "InfraCPUCores=$($JSON.TestInfra.CPUCores)," +
                    "InfraCPUThreadCount=$($JSON.TestInfra.CPUThreadCount)," +
                    "InfraCPUSocketCount=$($JSON.TestInfra.CPUSocketCount)," +
                    "InfraCPUSpeed=$($JSON.TestInfra.CPUSpeed)," +
                    "InfraMemoryGB=$($JSON.TestInfra.MemoryGB)," +
                    "BootStart=$($JSON.TestInfra.BootStart)," +                    
                    "BootTime=$($JSON.TestInfra.Boottime)," +
                    "MaxAbsoluteActiveActions=$($JSON.TestInfra.MaxAbsoluteActiveActions)," +
                    "MaxAbsoluteNewActionsPerMinute=$($JSON.TestInfra.MaxAbsoluteNewActionsPerMinute)," +
                    "MaxPercentageActiveActions=$($JSON.TestInfra.MaxPercentageActiveActions)," +
                    "VSIproductVersion=$($vsiresult.productVersion)," +
                    "VSIEUXversion=$($vsiresult."EUX version")," +
                    "VSIactivesessionCount=$($vsiresult.activesessionCount)," +
                    "VSIEUXscore=$($vsiresult."EUX score")," +
                    "VSIEUXstate=$($vsiresult."EUX state")," +
                    "VSIvsiMax=$($vsiresult.vsiMax)," +  
                    "VSIvsiMaxstate=$($vsiresult."vsiMax state")," + 
                    "VSIvsiMaxversion=$($vsiresult."vsiMax version")"
                    )

            $basetag = $tag
            $csvFilePath = $File
            $csvData = Import-Csv $csvFilePath
            $headers = $csvData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

            foreach ($line in $csvData) {
                $fields = ""
                $tag = $basetag
                foreach($Header in $Headers){
                    if(($header -ne "Timestamp")){

                        if(($header -like "*Id*") -or ($header -like "*Name*") -or ($header -like "*timer*")){
                            $Data = $($line.$($Header))
                            $tag = $tag + ",$($Header)=$($Data)"
                        } else {
                            $Data = $($line.$($Header))
                            $Fields = $Fields + "$($Header)=$($Data),"
                        }
                    }
                }
                $Fields = $Fields.TrimEnd(",")
                $tag = $tag.replace(' ','_')
                $CSVDate = $($line.Timestamp)
                $UnixDate = Get-Date -Date $CSVDate -UFormat %s
                $NewDate = $UnixDate.Split(".")
                $FormattedDate = $newdate[0] - $DeltaTime   
                $Body = "$measurementName,$tag $fields $FormattedDate"
                $null = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $Body
            }
        }
    }
}