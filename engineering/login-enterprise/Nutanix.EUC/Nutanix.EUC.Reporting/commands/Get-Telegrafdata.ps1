function Get-Telegrafdata {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$TestStarttime,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$TestFinishtime,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$influxdburl,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$Token,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$TelegrafBucket,
        [Parameter(Mandatory = $true)][string]$OutputFolder
    )

    $influxdburl = $influxdburl.replace("&precision=s","").replace("write","query")
    $starttime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date -Date $TestStarttime).ToUniversalTime())).TotalSeconds)
    $endTime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date -Date $TestFinishtime).ToUniversalTime())).TotalSeconds)
    
    #region Getting Telegraf data
    
    Write-Log -Message "[DATA EXPORT] Getting data from Telegraf" -Level Info
    # start a timer for gathering session metrics
    $TelegrafGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

    $OutputCsvPath = "$($OutputFolder)\Telegraf-data.csv"

    #region Get Data From Influx

    Write-Log -Message "[DATA EXPORT] Gathering Test Data" -Level Info
    # Build the Influx DB Web Headers
    $WebHeaders = @{
        Authorization  = "Token $Token"
        "Accept"       = "application/csv"
        "Content-Type" = "application/vnd.flux"
    }
    # Remove the extra closing curly brace
    Write-Log -Message "[DATA EXPORT] Build Body Payload based on Uri Variables" -Level Info

        $Body = @"
from(bucket: "$TelegrafBucket")
|> range(start:  $starttime, stop: $endTime)
|> group(columns: ["_measurement", "host", "_field", "objectname", "instance"])
|> aggregateWindow(every: 30s, fn: mean, createEmpty: false)
|> map(fn: (r) => ({timestamp: r._time, tg_measurement: r._measurement, tg_host: r.host, tg_field: r._field, tg_objectname: r.objectname, tg_instance: r.instance, "value": r._value}))
"@

    # Get the test details table from Influx and Split into individual lines
    try {
        Write-Log -Message "[DATA EXPORT] Get Test Details from Influx API" -Level Info
        $TestDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $Body -ErrorAction Stop
    } catch {
        Write-Log -Message "[DATA EXPORT] Error Getting Test Details from Influx API" -Level Error
        break
    }

    $csvLines = $TestDetails -split "`n"
    Write-Log -Message "[DATA EXPORT] CSV Response received. Total lines: $($csvLines.Length)" -Level Info
   
    # Initialize variables
    $outputData = [System.Collections.ArrayList] @()             # To store processed data
    $headerProcessed = $false     # To track whether the header has been processed
    $headerColumns = [System.Collections.ArrayList] @()          # Array for the header columns

    # Loop through each line and process it
    foreach ($line in $csvLines) {
        # Skip empty or whitespace-only lines
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # Split the line into columns based on commas
        $columns = $line -split ","

        # Process the header row once
        if (-not $headerProcessed) {
            # Get the header columns, excluding unwanted columns
            $headerColumns = $columns
            $headerProcessed = $true
            continue
        }

        # Ensure the number of columns matches the header, otherwise skip
        if ($headerColumns.Length -ne $columns.Length) {
            #Write-Log -Message "Skipping row due to column mismatch." -Level Warn
            continue
        }

        # Create an object for each data row based on the header columns
        $rowObject = New-Object PSObject
        for ($i = 3; $i -lt $headerColumns.Length; $i++) {
            $headerName = $headerColumns[$i].Trim()
            $value = if ([string]::IsNullOrWhiteSpace($columns[$i])) { "NA" } else { $columns[$i] }  # Replace empty values with "NA"
            $rowObject | Add-Member -MemberType NoteProperty -Name $headerName -Value $value
        }

        # Add the row to the output data collection
        #$outputData += $rowObject
        $null = $outputData.Add($rowObject)
    }

    # Check if outputData contains anything
    if ($outputData.Count -eq 0) {
        Write-Log -Message "[DATA EXPORT] No data processed. OutputData is empty." -Level Warn
    }
    else {
        Write-Log -Message "[DATA EXPORT] Processed $($outputData.Count) rows." -Level Info
    }

    # Step 8: Write the cleaned data to the CSV file
    $outputData | Export-Csv -Path $OutputCsvPath -NoTypeInformation

    Write-Log -Message "[DATA EXPORT] Data successfully written to $OutputCsvPath" -Level Info

    # stop the timer for gathering session metrics
    $TelegrafGatheringStopWatch.stop()
    $ElapsedTime = [math]::Round($TelegrafGatheringStopWatch.Elapsed.TotalSeconds, 2)
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull metrics from Telegraf" -Level Info
   
}