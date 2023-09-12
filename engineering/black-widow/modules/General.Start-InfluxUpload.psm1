function Start-InfluxUpload {
    param(
        [Parameter(Mandatory = $true)] [string]$influxDbUrl,
        [Parameter(Mandatory = $true)] [string]$ResultsPath,
        [Parameter(Mandatory = $true)] [string]$Token
    )

    # Read in JSON File
    $JSONFile = Join-Path -path $ResultsPath -childpath "TestConfig.json"
    $JSON = Get-Content -Path $JSONFile -Raw | ConvertFrom-Json

    $MeasurementName = $($JSON.TestInfra.TestName)

    $WebHeaders = @{
                        Authorization = "Token $Token"
                }

    ## set fixed start date
    ## calc time diff with measurement start date
    ## Subtract time diff from timestamp
    $StartDate = [DateTime] "01/01/2023 1:00 AM"
    $UnixStartedDate = Get-Date -Date $StartDate -UFormat %s
    $NewStartDate = $UnixStartedDate.Split(".")
    $FormattedStartDate = $NewStartDate[0]


    $Files = Get-ChildItem "$($ResultsPath)\*.csv"
    $NetScalerResult = Import-CSV "$($ResultsPath)\NetScaler RAW.csv"
    $Started = $NetScalerResult[0].TimeStamp
    $BucketName = $($JSON.Test.BucketName)

    $UnixStarted = Get-Date -Date $Started -UFormat %s
    $NewStarted = $UnixStarted.Split(".")
    $FormattedStarted = $NewStarted[0]
    $DeltaTime = $FormattedStarted - $FormattedStartDate
    
    $influxDbUrl = $influxDbUrl + "&bucket=$($BucketName)"
    
    $CurrentYear = get-date -Format yyyy
    $CurrentMonth = get-date -Format MM

    foreach($File in $Files){
        if(($File.Name -like "NetScaler Raw*") -or ($File.Name -like "VM Raw*")){
            $TopLevelTag = $File.BaseName
            $Tag = ("DataType=$($TopLevelTag)," +
                    "Year=$($CurrentYear)," +
                    "Month=$($CurrentMonth)," +
                    "DocumentName=$($JSON.Test.DocumentName)," +
                    "Comment=$($JSON.Test.Comment)," +
                    "HostGPUs=$($JSON.TestInfra.HostGPUs)," +
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
                    "NetScalerHost=$($JSON.NetScalerData.Host)," +
                    "NetScalerUUID=$($JSON.NetScalerData.UUID)," +
                    "NetScalerDescription=$($JSON.NetScalerData.Description)," +
                    "NetScalerVersion=$($JSON.NetScalerData.Version)," +
                    "NetScalervCPU=$($JSON.NetScalerData.vCPU)," +
                    "NetScalerMemory=$($JSON.NetScalerData.Memory)," +
                    "Threads=$($JSON.BlackWidow.Threads)," +
                    "ParallelConnections=$($JSON.BlackWidow.ParallelConnections)," +
                    "TestType=$($JSON.BlackWidow.TestType)"
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
                        $Data = $($line.$($Header))
                        $Fields = $Fields + "$($Header)=$($Data),"
                    }
                }
                $Fields = $Fields.TrimEnd(",")
                $Fields = $Fields.Replace('null', '0')
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