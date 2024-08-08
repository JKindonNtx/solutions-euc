Here is a small part of our enhancements whilst you lot have been laying on beaches. There are some lessons and code snippets included for learning. Enjoy.

TL/DR

- We reduced data export and manipulation times from Login Enterprise from over 9 hours to around 27 minutes.
- We reduced the data ingestion time from CSV to Influx from 70 minutes to 7 minutes.
- We improved logging functionality so that we now have full logging to file for every test, and we have a load more verbose logging output across the data egress and ingress components.
- We removed non-useful scripts and functions. Remove-TestData-API.ps1 now deletes full test sets in a few minutes, Invoke-TestUpload.ps1 also benefits from all code changes below.
- SH - Dashboards
- SH - Prometheus
- SH - Align Time

## Optimization of data egress from Login Enterprise

This is really a brutal lesson in understanding how arrays work in PowerShell and the dangers of looping.

When we create Arrays in PowerShell using a `$NewArray = @()` layout or simply pulling data into an array by getting a return such as `$DataArray = Get-Item -Path "c:\some_path\" -recurse` you are creating a fixed size basic array. This is an immutable object.

Why does this matter? When you then choose to "add" to that array, you aren't really adding anything. You are asking PowerShell, in memory, to delete and recreate the array with new values. Specifically, this sort of code `$Array += $Item`. The more items you have in the source array, the more tax it is to delete and recreate with a new item. A terrible model to scale with.

We should be using `ArrayLists`. These are defined as `$NewArray = [System.Collections.ArrayList] @()`. These are a non-fixed array meaning you can add or remove data. For example:

-  `$NewArray.Add($Item)` would add the item `$Item` to the `$NewArray`.
-  `$NewArray.Remove($Item)` would remove the `$item` from the `$NewArray`.
-  `$NewArray.AddRange($NewArrayBatch)` would add the entire existing `$NewArrayBatch` to the `NewArray`. This can be handy when you get a return of a fixed Array, and you want to cast it to an `ArrayList` instead.
 
Not using ArrayLists, but instead using basic Arrays, is a problem that shows its face at scale. For small datasets, it's fine, but for large datasets, the problems get worse the more data you add.

Rule of thumb. If you go to type `+=` in your code, think about if you should be using Arrays or ArrayLists? My suggestion is going to be ArrayLists for all the things.

Let's look at an example of what using bad basic arrays and bad loops can look like and the impacts on our environment.

### Example Problem: Export-LEMeasurements.ps1

This function is designed to go and pull data from Login Enterprise via its API. We then sort the data and export it to CSV files which we ingest into Influx (more on that later).

Here is a code block that hurts big time. There are multiple failures, we will break them down.

```
$SessionMetricMeasurements = Get-LESessionMetricMeasurements -testRunId $testRun.Id -orderBy timestamp

if (($SessionMetricMeasurements | Measure-Object).Count -gt 0) {
            
    $SessionMetricMeasurements = $SessionMetricMeasurements | Select-Object displayName,instance,fieldName,timestamp,userSessionKey,@{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } },measurement
    
    if (($SessionMetricMeasurements | Measure-Object).Count -eq 10000) {
        $FileEnded = $false
        while (-not $FileEnded){
            [int]$OffSet = $SessionMetricMeasurements.count + 1
            $SessionMetricMeasurementsAdditional = Get-LESessionMetricMeasurements -testRunId $testRun.Id -orderBy timestamp -OffSet $OffSet
            $SessionMetricMeasurementsAdditional = $SessionMetricMeasurementsAdditional | Select-Object displayName,instance,fieldName,timestamp,userSessionKey,@{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } },measurement
            $SessionMetricMeasurements = $SessionMetricMeasurements + $SessionMetricMeasurementsAdditional
            if (($SessionMetricMeasurementsAdditional | Measure-Object).count -lt 10000){
                $FileEnded = $true
            }
        }
    }

    # Open an Object to capture the update info prior to export
    $SessionMetricMeasurementsWithHost = @()

    # Loop through each unique session and go learn about the host host they lived on
    foreach ($userSessionKey in ($SessionMetricMeasurements.userSessionKey | Select-Object -Unique)) {
        $SessionHostName = ((Get-LESessionDetails -testRunId $testRun.Id -userSessionId $userSessionKey).Properties | Where-Object {$_.propertyId -eq "TargetHost"}).value
        # now we need to inject the SessionHostName value into the Data used for CSV Export - we need to only do this where the record in the existing data set contains the matching userSessionKey
        foreach ($Item in $SessionMetricMeasurements | Where-Object {$_.userSessionKey -eq $userSessionKey}) {
            $SessionMetricMeasurementsWithHostresult = New-Object PSObject
            $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "timestamp" -Value $item.timestamp
            $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "userSessionKey" -Value $item.userSessionKey
            $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "displayName" -Value $item.displayName
            $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "measurement" -Value $item.measurement
            $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "fieldName" -Value $item.fieldName
            $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "instance" -Value $item.instance
            $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "hostName" -Value $SessionHostName

            $SessionMetricMeasurementsWithHost += $SessionMetricMeasurementsWithHostresult
        }
    }
    # Set the Data set ready for export
    $SessionMetricMeasurements = $SessionMetricMeasurementsWithHost

    $SessionMetricMeasurements | Export-Csv -Path "$($Folder)\VM Perf Metrics.csv" -NoTypeInformation
}
```

**Problem 1:** The use of Basic Arrays in a loop function

This code used the following logic

-  Go and get the first set of Session Metric Measurements. Put them into a basic Array called `$SessionMetrics`.
-  We know that the maximum number we can pull back in a single API call is 10,000, so we do a check to see if there is more to come down. We know there is more because the item count is 10,000, if there were none left, we wouldn't have 10,000 as the count. This is fine.
-  We loop through multiple times until we get all the data. Each time we loop, we update our basic array using `$SessionMetricMeasurements = $SessionMetricMeasurements + $SessionMetricMeasurementsAdditional` with 10000 records. This is not updating anything, it's creating a new array in memory each loop, and each loop is creating a bigger array that PowerShell needs to handle. Uh oh. Not good when you have let's say, 520,000 records (that is what we often collect - and this is just Session Metrics).
-  Now we have all the Session Metrics, we need to do something with them. Here comes the double-tap problem number 2.
 
**Problem 2:** Naughty loops and more naughty basic Arrays

Now that we have the data set, we need to add the hostName record to each record because we need to be able to wrap it up in influx. Login Enterprise doesn't return this record with the Session Metrics, so we have to go and learn some detail, and then create a custom object, and append. Here is what the bad code block is doing to handle this

-  It creates a new basic Array (uh oh) called `$SessionMetricMeasurementsWithHost = @()` The idea is this will house the final updated data.
-  It now looks to identify each unique user session which is what we use to go and learn some host details from Login Enterprise `foreach ($userSessionKey in ($SessionMetricMeasurements.userSessionKey | Select-Object -Unique))`
-  Now for each of those (hello loop number 1), it goes and learns the VM name `$SessionHostName = ((Get-LESessionDetails -testRunId $testRun.Id -userSessionId $userSessionKey).Properties | Where-Object {$_.propertyId -eq "TargetHost"}).value`
-  And here lies the second massive failure: from here, we loop through every single item that is in the initial `SessionMetricMeasurements` basic array (over half a million) and we match the appropriate values so we know the host name `foreach ($Item in $SessionMetricMeasurements | Where-Object {$_.userSessionKey -eq $userSessionKey})`.
-  From there, for each item that is matched, we create a new PS object and then start our 3rd failure `$SessionMetricMeasurementsWithHost += $SessionMetricMeasurementsWithHostresult`. Yes, another basic array recreation job.

What does this mean? Let's take a look at the math. We have a test that monitors 20 sessions via LE. On average, with the perfmon counters we are using (and this is a problem that gets worse with each counter we add), we would pull back over half a million records. So let's use a round number of 500,000 records for this example:

-  We iterate through the records, pulling back 10,000 items at a time. That is 50 batch calls to Login Enterprise, and 50 basic array recreates, each time compounding the memory usage and time spent by 10,000 records. So the last bit of work that PowerShell has to do on this logic is handle the recreation of a basic Array that already has 490,000 records and create a new one with 50,0000. Ouch.
-  We monitor 20 sessions, so we need to go and learn about those 20 sessions and get the VM that the session was associated with. In the bad code block above:
  -  We start our loop with session 1, and we ultimately repeat this top-level loop 20 times
  -  We then loop through 500,000 records to identify the matching records, and when they match, we add them to a basic Array, that means for 20 sessions (loops!) we loop through and compare 10,000,000 (10 million) records, ultimately matching 500,000 records. In. Memory.
  -  We are adding 500,000 custom objects to that basic Array, or more concisely, we are recreating that basic array 500,000 times, each time, having one more record to add. The memory and time this takes is a monster
-  Once we have performed this lovely piece of looping, we export to CSV, and then guess what, we move to the next block of LE metrics which does the exact same thing, albeit on a smaller scale.

The time it took to handle test monitoring 20 sessions, to get the data out to CSV is over 9 hrs and a staggering PowerShell memory footprint of over 10GiB. That is just to get the data into CSV. And the time is all in the looping of data and recreation of basic arrays.

![Example of a busted run](image.png)

How should we be handling this compounding problem?

- `Always` log the output of long-running components so we know what is taking the time. It offers us a chance to optimize code.
- Use `ArrayLists` - these are way better for handing bulk code.
- Watch out for negligent loops - these can kill your script.
- Get rid of useless data alterations when they are not needed. We had for example, an OffSet value where we had to do a Get-Date command 500,000 times. That field is never used.

Here is an updated code example based on the above bad example:

```
# start a timer for gathering session metrics
$SessionMetricGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

# Use an Array List for better data handling
$SessionMetricMeasurements = [System.Collections.ArrayList] @()

$SessionMetricMeasurementsBatch = Get-LESessionMetricMeasurements -testRunId $testRun.Id -orderBy timestamp

if (($SessionMetricMeasurementsBatch | Measure-Object).Count -gt 0) {

    $SessionMetricMeasurementsBatch = $SessionMetricMeasurementsBatch | Select-Object displayName, instance, fieldName, timestamp, userSessionKey, measurement

    # Add the SessionMetricMeasurementsBatch to the SessionMetricMeasurements ArrayList
    $SessionMetricMeasurements.AddRange($SessionMetricMeasurementsBatch)

    if (($SessionMetricMeasurements | Measure-Object).Count -eq 10000) {
        $FileEnded = $false
        while (-not $FileEnded) {
            [int]$OffSet = $SessionMetricMeasurements.count + 1
            Write-Log -Message "[DATA EXPORT] Pulling additional metrics from Login Enterprise with an offset of $($OffSet)" -Update -Level Info
            $SessionMetricMeasurementsAdditional = Get-LESessionMetricMeasurements -testRunId $testRun.Id -orderBy timestamp -OffSet $OffSet
            $SessionMetricMeasurementsAdditional = $SessionMetricMeasurementsAdditional | Select-Object displayName, instance, fieldName, timestamp, userSessionKey, measurement
            # Add the SessionMetricMeasurementsAdditional to the SessionMetricMeasurements ArrayList
            $SessionMetricMeasurements.AddRange($SessionMetricMeasurementsAdditional)
            if (($SessionMetricMeasurementsAdditional | Measure-Object).count -lt 10000) {
                $FileEnded = $true
            }
        }
    }
    # stop the timer for gathering session metrics
    $SessionMetricGatheringStopWatch.Stop()
    $ElapsedTime = [math]::Round($SessionMetricGatheringStopWatch.Elapsed.TotalSeconds, 2)
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull $($SessionMetricMeasurements.Count) metrics from Login Enterprise" -Level Info

    Write-Log -Message "[DATA EXPORT] Identifying userSessions to hostName details from Login Enterprise" -Level Info
    #Create the Session HostName Map Array List
    $SessionHostNameMap = [System.Collections.ArrayList] @()

    # start a timer for gathering vmHost details
    $SessionHostNameMapStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

    foreach ($userSessionKey in ($SessionMetricMeasurements.userSessionKey | Select-Object -Unique)) {
        $SessionHostRecord = New-Object PSObject
        $SessionHostRecord | Add-Member -MemberType NoteProperty -Name "userSessionKey" -Value $userSessionKey
        $SessionHostRecord | Add-Member -MemberType NoteProperty -Name "hostName" -Value ((Get-LESessionDetails -testRunId $testRun.Id -userSessionId $userSessionKey).Properties | Where-Object { $_.propertyId -eq "TargetHost" }).value
        $null = $SessionHostNameMap.Add($SessionHostRecord)
    }

    # stop the timer for gathering vmHost details
    $SessionHostNameMapStopWatch.Stop()
    $ElapsedTime = [math]::Round($SessionHostNameMapStopWatch.Elapsed.TotalSeconds, 2)

    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to identify userSessions to HostName from Login Enterprise" -Level Info
    
    if ($null -eq $SessionHostNameMap) {
        Write-Log -Message "[DATA EXPORT] No records were found in the session HostName Map" -Level Warn
        Continue
    }

    # Open an Arraylist to capture the update info prior to export
    $SessionMetricMeasurementsWithHost = [System.Collections.ArrayList] @()

    Write-Log -Message "[DATA EXPORT] Altering session Metrics with HostName details from Login Enterprise" -Level Info
    # start a timer for procesing Session Metrics with HostName
    $ItemProcessingStopWatch = [System.Diagnostics.Stopwatch]::StartNew()

    $SessionMetricMeasurementsCount = $SessionMetricMeasurements.Count # for tracking output only

    $ProcessedData = 0
    foreach ($item in $SessionMetricMeasurements) {
        $SessionMetricMeasurementsWithHostresult = New-Object PSObject
        $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "timestamp" -Value $item.timestamp
        $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "userSessionKey" -Value $item.userSessionKey
        $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "displayName" -Value $item.displayName
        $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "measurement" -Value $item.measurement
        $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "fieldName" -Value $item.fieldName
        $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "instance" -Value $item.instance
        $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "hostName" -Value ($SessionHostNameMap | Where-Object { $_.userSessionKey -eq $item.userSessionKey }).hostName

        # Add the SessionMetricMeasurementsWithHostresult to the SessionMetricMeasurementsWithHost ArrayList
        $null = $SessionMetricMeasurementsWithHost.Add($SessionMetricMeasurementsWithHostresult)
        $ProcessedData ++ # Append a processed count for tracking output

        # for tracking output only, write an output for every 50000 records processed
        if ($ProcessedData % 50000 -eq 0 -and $ProcessedData -ne $SessionMetricMeasurementsCount) { 
            Write-Log -Message "[DATA EXPORT] Processed $($ProcessedData) items out of $($SessionMetricMeasurementsCount)" -Update -Level Info
        }
        elseif ($ProcessedData -eq $SessionMetricMeasurementsCount) {
            Write-Log -Message "[DATA EXPORT] Processed $($ProcessedData) items out of $($SessionMetricMeasurementsCount)" -Update -Level Info
        }
    } 

    # stop the timer for procesing Session Metrics with HostName
    $ItemProcessingStopWatch.Stop()
    $ElapsedTime = [math]::Round($ItemProcessingStopWatch.Elapsed.TotalMinutes, 2)
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) Minutes to alter $($SessionMetricMeasurementsWithHost.Count) records with HostName" -Level Info

    # Set the Data set ready for export
    if ($SessionMetricMeasurements.Count -eq $SessionMetricMeasurementsWithHost.Count) {
        Write-Log -Message "[DATA EXPORT] No Records were lost in the process" -Level Info
    }
    else {
        Write-Log -Message "[DATA EXPORT] Lost $(($SessionMetricMeasurements.Count - $SessionMetricMeasurementsWithHost.Count)) records in the process" -Level Warn
    }

    # Rest the SessionMetricMeasurements to the SessionMetricMeasurementsWithHost ready for export
    $SessionMetricMeasurements = $SessionMetricMeasurementsWithHost

    $SessionMetricMeasurements | Export-Csv -Path "$($Folder)\VM Perf Metrics.csv" -NoTypeInformation
}

```

The code block looks longer, but it is doing a lot more efficient processing, it now does the following:

-  Starts and stops timers during each phase so that output can be reviewed properly for each component.
-  Uses ArrayLists to handle data `$SessionMetricMeasurements = [System.Collections.ArrayList] @()`. Each time we poll LE to learn about the records (the same logic applies, 10,000 item batches), we cast the result into the ArrayList. No recreations here, just additions `$SessionMetricMeasurements.AddRange($SessionMetricMeasurementsAdditional)`.
-  20 sessions are being monitored, so we do a nice quick loop outside of the data processing loop, to go and learn about unique sessions (20) and what their corresponding VM names are (also 20). We put those records into another ArrayList which we can reference `$SessionHostNameMap = [System.Collections.ArrayList] @()`. This logic alone means that we remove 20 loops of 500,000 record comparisons.
-  We open a new ArrayList to handle our final data set `$SessionMetricMeasurementsWithHost = [System.Collections.ArrayList] @()`
-  Now we process the original `$SessionMetricMeasurements` ArrayList which holds 500,000 records, and for each item, we go and compare against our nice new `$SessionHostNameMap` ArrayList - no more calls out to LE, no more crazy looping, just compare to that ArrayList which is already in memory.
   -  Where we match, we create a new PS object (no change in logic here) and then add that to the `$SessionMetricMeasurementsWithHost` ArrayList `$null = $SessionMetricMeasurementsWithHost.Add($SessionMetricMeasurementsWithHostresult)`
   -  Because we want to understand processing times and status, we are outputting batch statuses to the console in blocks of 50,000. This helps us understand where things are at. User-friendly more than functional.
-  We are done now, so we export to CSV.
-  We now use this same logic for the rest of the data pulled from Login Enterprise.

The difference here? We now go to 27 minutes on the same data set, and we have a full awareness of each piece of output.

![Example of a good run](image-1.png)


## Optimization of data ingress to InfluxDB

### Example Problem: Start-InfluxUpload.ps1

This example is nowhere near as punishing as the above, however still nets some significant wins. It is also an example of scale thinking. What we do at low scale, doesn't mean it's great for large scale.

This function ingests our CSV files and manipulates the data ready for Influx ingestion. There are quite a few things that it does here, what it does is not the problem, in what sequence it does things is more the challenge.

The script code effectively ingests a CSV, which let's say has 500,000 records. It then manipulates each of these records and sends them to influx. One at a time. The redacted set of the relevant code is shown below.

```
foreach ($line in $csvData) {
    # Build the body
    $Body = "$measurementName,$tag $fields $FormattedDate"

    # Upload the data to Influx
    Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $Body -ErrorAction Stop
}
```

There are some challenges with this approach, as whilst functional, it's slow. It's also throwing a staggering 500,000 API calls at Influx for one CSV file.

Influx allows for [batch writing of data points](https://docs.influxdata.com/influxdb/v1/guides/write_data/#writing-multiple-points), so it's easy enough to alter the logic in the upload functions to use batch. This requires a few slight changes, outlined below:

```
$batch_data_to_process = [System.Collections.ArrayList] @()

foreach ($line in $csvData) {
    # Do some stuff that's not relevant for doco

    # Build the body
    $Body = "$measurementName,$tag $fields $FormattedDate"

    $null = $batch_data_to_process.Add($Body)
}

#upload the data to Influx
# this is now sorting the data in the arraylist to ensure that the data is formatted properly

$batchSize = 1000
$numberOfBatches = [math]::Ceiling($batch_data_to_process.Count / $batchSize)
$CurrentBatch = 1

for ($i = 0; $i -lt $numberOfBatches; $i++) {
    $start = $i * $batchSize
    $end = $start + $batchSize - 1

    # If $end is greater than the last index of the array, set $end to the last index
    if ($end -gt $batch_data_to_process.Count - 1) {
        $end = $batch_data_to_process.Count - 1
    }

    $batch = $batch_data_to_process[$start..$end]
    Write-Log -Message "[DATA UPLOAD] Processing Batch $($CurrentBatch) of $($numberOfBatches) with $($Batch.Count) records (Total records: $($batch_data_to_process.Count))" -Level Info -Update

    #Process the batch

    $Body = $batch -join "`n"

    try {
        Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $Body -ErrorAction Stop
    }
    catch {
        $ErrorMessage = $_
        $UpdatedErrorMessage = $ErrorMessage | ConvertFrom-Json
        Write-Log -Message "[DATA UPLOAD] Error Uploading Data: $UpdatedErrorMessage" -Level Warn
        # Try 5 times to re upload the data and then write an error message to the log
        $RetryIntervalSeconds = 15 # how long to sleep between attempts
        $RetryCountTotal = 5 # how many times to retry
        $RetryCount = 0 # the current iteration of retries
        
        while ($RetryCount -lt $RetryCountTotal) {
            $RetryCount ++
            Write-Log -Message "[DATA UPLOAD] Upload Failure Retry. Attempt $($RetryCount) of $($RetryCountTotal). Sleeping $($RetryIntervalSeconds) seconds before trying again" -Level Warn
            Start-Sleep -Seconds $RetryIntervalSeconds
            try {
                Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $Body -ErrorAction Stop
                Write-Log -Message "[DATA UPLOAD] Upload Failure Retry Successful. Data Uploaded for batch $($CurrentBatch)" -Level Info
                $FailState = $false #we are no longer failing!
            }
            catch {
                $ErrorMessage = $_
                Write-Log -Message "[DATA UPLOAD] Error Uploading Data: $ErrorMessage" -Level Warn
                $FailState = $true # we are still failing
            }
            #Break out of the while loop if $failstate is $false
            if ($FailState -eq $false) {
                break # Exit this loop as we are ok to move on
            }
        }
        if ($FailState -eq $true) {
            Write-Log -Message "[DATA UPLOAD] Upload Failure Retry Limit Reached. Data Upload Failed for batch $($CurrentBatch) Consider uploading test again." -Level Error
        }
    }

    $CurrentBatch ++

}

```

The script now uses the following logic

-  Uses a nice Arraylist to house all body records ready for influx.
-  Breaks the the upload portion into batches of 1000 records (datapoints) at a time. We could send more in each request, but we wouldn't gain any efficiencies by doing so outside of less API calls (we are still making 500 calls here for one CSV dataset). The time is in the data sorting.
-  Sends the batches into influx, and error handles failure states to cater for timeouts and reuploads.
-  Tracks the progress the whole way through.

And the result? A reduction of upload time from 70 minutes down to just over 7 minutes.

![Batch Processing](image-2.png)
