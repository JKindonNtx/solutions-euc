<#
    .SYNOPSIS
        This script is used to analyze, simulate or execute the modification of the 'connection' and `total_login_time` records in a CSV file as output by Login Enterprise.
    .DESCRIPTION
        Use this script wisely to modify the 'connection' and 'total_login_time' records in a CSV file as output by Login Enterprise. If it used if there is bad data due to launcher issues.
    .PARAMETER SourceFile
        The source CSV file to be processed.
    .PARAMETER Mode
        The mode of operation: Analyze, Simulate or Execute.
        Analyze: Analyze the records and show the preview of the records to be altered. If the ShowRecordAlterationPreview switch is used, it will show the preview of the altered records.
        Simulate: Simulate the records to be altered.
        Execute: Execute the records to be altered and export the modified data back to a CSV file.
    .PARAMETER MinRange
        The minimum value to replace the 'connection' action - start range. The script will generate a random number between MinRange and MaxRange. Default is 3.4.
    .PARAMETER MaxRange
        The maximum value to replace the 'connection' action - end range. The script will generate a random number between MinRange and MaxRange. Default is 3.9.
    .PARAMETER TimeThreshold
        The threshold to check for 'connection' actions. The script will check for 'connection' actions with values above the TimeThreshold. Default is 4.
    .PARAMETER FirstRecordsToExclude
        The first records to exclude - might be handy to exclude the first records due to session initialization on launchers. Default is 0. You cannot use this parameter with FirstRecordsToInclude.
    .PARAMETER FirstRecordsToInclude
        The first records to include - might be handy to include the first records due to session initialization on launchers. Default is 0. You cannot use this parameter with FirstRecordsToExclude.
    .PARAMETER ShowRecordAlterationPreview
        Show the preview of the altered records. Used with the analyze or simulate mode.
    .EXAMPLE
        .\Modify-ConnectionRecords.ps1 -SourceFile "C:\Temp\LE\Raw Login Times.csv" -Mode "Analyze" -MinRange 3.4 -MaxRange 3.9 -TimeThreshold 4 -ShowRecordAlterationPreview
        This will analyze the records and show the preview of the records to be altered. Looks for connection records with values above 4 and generates a random number between 3.4 and 3.9.
    .EXAMPLE
        .\Modify-ConnectionRecords.ps1 -SourceFile "C:\Temp\LE\Raw Login Times.csv" -Mode "Simulate" -MinRange 3.2 -MaxRange 3.7 -TimeThreshold 4 -FirstRecordsToExclude 75
        This will simulate the records to be altered. Looks for connection records with values above 4 and generates a random number between 3.2 and 3.7. Excludes the first 75 records.
    .EXAMPLE
        .\Modify-ConnectionRecords.ps1 -SourceFile "C:\Temp\LE\Raw Login Times.csv" -Mode "Simulate" -MinRange 3.2 -MaxRange 3.7 -TimeThreshold 4 -FirstRecordsToInclude 75
        This will simulate the records to be altered. Looks for connection records with values above 4 and generates a random number between 3.2 and 3.7. Includes only the first 75 records. Implies processing only the first Launcher sessions.
    .EXAMPLE
        .\Modify-ConnectionRecords.ps1 -SourceFile "C:\Temp\LE\Raw Login Times.csv" -Mode "Execute" -MinRange 3.4 -MaxRange 3.9 -TimeThreshold 4 -FirstRecordsToExclude 75
        This will execute the records to be altered. Looks for connection records with values above 4 and generates a random number between 3.4 and 3.9. Excludes the first 75 records and exports the modified data back to a CSV file.
    .NOTES
        File Name      : ModifyCrudConnectionStats.ps1
        Author         : James Kindon
        Prerequisite   : A Broken CSV file with dodgy connection data from Login Enterprise Output
#>

param (
    [Parameter(Mandatory=$true)][string]$SourceFile,
    [Parameter(Mandatory=$false)][ValidateSet("Analyze", "Simulate", "Execute")][string]$Mode = "Simulate",
    [Parameter(Mandatory=$false)][string]$MinRange = 3.4, 
    [Parameter(Mandatory=$false)][string]$MaxRange = 3.9, 
    [Parameter(Mandatory=$false)][int]$TimeThreshold = 4,
    [Parameter(Mandatory=$false)][int]$FirstRecordsToExclude = 0,
    [Parameter(Mandatory=$false)][int]$FirstRecordsToInclude = 0,
    [Parameter(Mandatory=$false)][switch]$ShowRecordAlterationPreview
)

if ($FirstRecordsToExclude -gt 0 -and $FirstRecordsToInclude -gt 0) {
    Write-Warning "You can only use either FirstRecordsToExclude or FirstRecordsToInclude, not both."
    Exit 1
}

$OutFile = $SourceFile -replace ".csv", "_modified_$(Get-Date -Format yyyymmdd_hhmmss).csv"

#------------------------------------
# Import the CSV file
#------------------------------------
try {
    Write-Host "Importing data from: $($SourceFile)" -ForegroundColor Green
    $data = Import-Csv -Path $SourceFile -ErrorAction Stop
}
catch {
    Write-Warning $_.Exception.Message
    Exit 1
}

#------------------------------------
# Check to make sure this is a valid CSV file containing the headers 'timestamp', 'sessionId', 'id', 'offsetInSeconds' and 'result' and nothing else
#------------------------------------
$validHeaders = @('timestamp', 'sessionId', 'id', 'result', 'offsetInSeconds')
$invalidHeaders = $data | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -notin $validHeaders }

if ($invalidHeaders) {
    Write-Warning "Invalid headers found in the CSV file: $($invalidHeaders.Name -join ', ')"
    Exit 1
}

#------------------------------------
# Sort the data by timestamp
#------------------------------------
$data = $data | Sort-Object -Property timestamp

#------------------------------------
# Set Arrays for data to process
#------------------------------------
# If FirstRecordsToInclude is set, get the first unique session ids to include. Implies only processing the first Launcher sessions
If ($FirstRecordsToInclude -gt 0) {
    Write-Host "Including the first $($FirstRecordsToInclude) records in processing" -ForegroundColor Yellow
    $RecordsToProcess = $data | Select-Object -Property SessionId -Unique | Select-Object -First $FirstRecordsToInclude
}
# If FirstRecordsToExclude is set, get all records to include which are not the first $FirstRecordsToExclude. Implies leaving the first Launcher sessions alone
if ($FirstRecordsToExclude -gt 0) {
    Write-Host "Excluding the first $($FirstRecordsToExclude) records from processing" -ForegroundColor Yellow
    $RecordsToProcess = $data | Select-Object -Property SessionId -Unique | Select-Object -Skip $FirstRecordsToExclude
}
# If neither FirstRecordsToInclude or FirstRecordsToExclude are set, get all records. Implies processing every session
if ($FirstRecordsToInclude -eq 0 -and $FirstRecordsToExclude -eq 0) {
    Write-Host "Processing all records" -ForegroundColor Yellow
    $RecordsToProcess = $data | Select-Object -Property SessionId -Unique
}

Write-Host "Records to process: $(($RecordsToProcess).Count)" -ForegroundColor Yellow

#------------------------------------
# Iterate through each record to find 'connection' actions with values above TimeThreshold
#------------------------------------

if ($Mode -eq "Analyze" -or $Mode -eq "Simulate") {
    $CurrentAverageConnectionTime = ([math]::Round((($data | Where-Object { $_.id -eq "connection" } | Measure-Object -Property result -Average).Average), 3))
    $CurrentAverageTotalLoginTime = ([math]::Round((($data | Where-Object { $_.id -eq "total_login_time" } | Measure-Object -Property result -Average).Average), 3))
    Write-Host "Current average Connection time: $($CurrentAverageConnectionTime)" -ForegroundColor Yellow
    Write-Host "Current average Total Login Time: $($CurrentAverageTotalLoginTime)" -ForegroundColor Yellow
    $CurrentHighestConnectionTime = ($data | Where-Object { $_.id -eq "connection" } | Measure-Object -Property result -Maximum).Maximum
    $CurrentHighestTotalLoginTime = ($data | Where-Object { $_.id -eq "total_login_time" } | Measure-Object -Property result -Maximum).Maximum
    Write-Host "Current highest Connection time: $($CurrentHighestConnectionTime)" -ForegroundColor Yellow
    Write-Host "Current highest Total Login Time: $($CurrentHighestTotalLoginTime)" -ForegroundColor Yellow
}

$ItemsToAlter = 0
$ItemsAltered = 0


foreach ($record in $data ) {
    if ($record.sessionId -in $RecordsToProcess.SessionId) {
        if ($record.id -eq 'connection' -and [float]$record.result -gt $TimeThreshold) {
            #------------------------------------
            # Address the connection records with values above the threshold
            #------------------------------------
            # Generate a random number between MinRange and MaxRange
            $randomValue = [math]::Round((Get-Random -Minimum $MinRange -Maximum $MaxRange), 3)

            $original_connection_value = $record.result
            $difference = [math]::Round(($record.result - $randomValue), 3)

            if ($Mode -eq "Analyze") {
                Write-Host "ANALYZE: $($record.sessionId) :: record $($record.Id) with current value $($record.result) needs replacement with $($randomValue). Difference: $($difference)" -ForegroundColor Yellow
                # Update the 'result' value with the random number
                $record.result = $randomValue
                $ItemsToAlter ++
            } elseif ($Mode -eq "Simulate") {
                # Update the 'result' value with the random number
                $record.result = $randomValue
                $ItemsToAlter ++
            } elseif ($Mode -eq "Execute") {
                Write-Host "EXECUTE: $($record.sessionId) :: Replacing record $($record.Id) with current value $($record.result) with $($randomValue). Difference: $($difference)" -ForegroundColor Cyan
                # Update the 'result' value with the random number
                $record.result = $randomValue
                $ItemsAltered ++
            }
            
            #------------------------------------
            # Address the 'total_login_time' action
            #------------------------------------
            # Find the corresponding 'total_login_time' action with the same id
            $totalTimeRecord = $data | Where-Object { $_.sessionId -eq $record.sessionId -and $_.id -eq "total_login_time" }

            if ($totalTimeRecord) {
                # Need to make $newValue fot total_login_time the original value, minus the difference between the original connection value and the new connection value
                $difference_to_subtract = [math]::Round(($original_connection_value - $randomValue), 3)
                $newValue = [math]::Round(($totalTimeRecord.result - $difference_to_subtract), 3)

                if ($Mode -eq "Analyze") {
                    Write-Host "ANALYZE: $($totalTimeRecord.sessionId) :: record $($totalTimeRecord.Id) with current value $($totalTimeRecord.result) needs replacement with $($newValue) by subtracting: $($difference_to_subtract)" -ForegroundColor Yellow
                    #Update the total_login_time record
                    $totalTimeRecord.result = $newValue
                    $ItemsToAlter ++
                } elseif ($Mode -eq "Simulate") {
                    #Update the total_login_time record
                    $totalTimeRecord.result = $newValue
                    $ItemsToAlter ++
                } elseif ($Mode -eq "Execute") {
                    Write-Host "EXECUTE: $($totalTimeRecord.sessionId) :: Replacing record $($totalTimeRecord.Id) with current value $($totalTimeRecord.result) with $($newValue) by subtracting: $($difference_to_subtract)" -ForegroundColor Cyan
                    #Update the total_login_time record
                    $totalTimeRecord.result = $newValue
                    $ItemsAltered ++
                }
            }
        }
    }
}

# ------------------------------------
# Output the modified data (if you want to see the changes)
# ------------------------------------

$NewAverageConnectionTime = ([math]::Round((($data | Where-Object { $_.id -eq "connection" } | Measure-Object -Property result -Average).Average), 3))
$NewAverageTotalLoginTime = ([math]::Round((($data | Where-Object { $_.id -eq "total_login_time" } | Measure-Object -Property result -Average).Average), 3))
$NewHighestConnectionTime = ($data | Where-Object { $_.id -eq "connection" } | Measure-Object -Property result -Maximum).Maximum
$NewHighestTotalLoginTime = ($data | Where-Object { $_.id -eq "total_login_time" } | Measure-Object -Property result -Maximum).Maximum

if ($Mode -eq "Analyze" -or $Mode -eq "Simulate") {
    Write-Host "Items to alter: $($ItemsToAlter)" -ForegroundColor Yellow
    Write-Host "Total unique session records to alter: $($ItemsToAlter / 2)" -ForegroundColor Yellow
    Write-Host "New average Connection Time after alteration: $($NewAverageConnectionTime)" -ForegroundColor Yellow
    Write-Host "New average Total Login Time after alteration: $($NewAverageTotalLoginTime)" -ForegroundColor Yellow
    Write-Host "New highest Connection time after alteration: $($NewHighestConnectionTime)" -ForegroundColor Yellow
    Write-Host "New highest Total Login Time after alteration: $($NewHighestTotalLoginTime)" -ForegroundColor Yellow
    if ($ShowRecordAlterationPreview) {
        Write-Host "Preview of the altered records:" -ForegroundColor Yellow
        $data | Format-Table -AutoSize
    }
}

if ($Mode -eq "Execute") {
    Write-Host "EXECUTE: Items altered: $($ItemsAltered)" -ForegroundColor Cyan
    Write-Host "EXECUTE: Total unique session records altered: $($ItemsAltered / 2)" -ForegroundColor Cyan
    Write-Host "EXECUTE: New average Connection time after alteration: $($NewAverageConnectionTime)" -ForegroundColor Cyan
    Write-Host "EXECUTE: New average Total Login time after alteration: $($NewAverageTotalLoginTime)" -ForegroundColor Cyan
    Write-Host "EXECUTE: New highest Connection time after alteration: $($NewHighestConnectionTime)" -ForegroundColor Cyan
    Write-Host "EXECUTE: New highest Total Login Time after alteration: $($NewHighestTotalLoginTime)" -ForegroundColor Cyan
    # Export the modified data back to a CSV file
    try {
        $data | Export-Csv -Path $OutFile -NoTypeInformation
        Write-Host "EXECUTE: Data exported to: $($OutFile)" -ForegroundColor Cyan
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    
}

Exit 0
