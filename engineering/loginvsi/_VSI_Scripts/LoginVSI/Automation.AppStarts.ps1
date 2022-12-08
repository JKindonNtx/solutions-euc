Param($vsiShare, $testName)

#$vsiShare = "\\fs-01\VSIShare"
#$guid = "cc13fd9-454a"
#$testName = "cc13fd9-454a_Win10_1809_Office_2016_x64"

Function Get-AppStart	
{
Param($AppID, $Testname, $Output)

$Output = "$Output\$AppID.csv"
$DefaultPath = "$($vsiShare)\_VSI_Logfiles\"
$Files = Get-ChildItem -Path "$Testname"

$Header = "Date & Time,ActiveSessions,StartTime"

If (!(Test-Path $Output))
{
	Write-Host (get-date) "- File not found, creating the output file"
	Add-Content $Output $Header
}

ForEach ($item in $Files)
{
	Write-Host (get-date) "$item in progress..."
	$AppData = Import-CSV $Location$Item
	$Entry = $AppData | Where-Object {$_.Label -eq $AppID}
	If ($Entry.Count -gt 1)
	{
		ForEach ($i in $Entry)
		{
			$Data = $i.DateTime + "," + $i.ActiveSessions + "," + $i.Value
			Add-Content $Output $Data
			# Write-Host "Multi: $Data"
		}
	} Else
	{
		$Data = $Entry.DateTime + "," + $Entry.ActiveSessions + "," + $Entry.Value
		If ($Data -eq ",,")
		{
			# Write-Host "No Data"
		} Else
		{
			Add-Content $Output $Data
			# Write-Host "Single: $Data"
		}
	}
}
}

# Merge Data
Function Combine-Data
{ 
Param($AppID, $vsiShare, $testName)
	
	$Overview = "$AppID.csv"

	$tests = (Get-ChildItem -Path "$($vsiShare)\_VSI_LogFiles\" -Filter $testName*  | Sort-Object)
	
	$tabName = "Overview"
	$table = New-Object system.Data.DataTable "$tabName"
    
    #Creates the amount of columns for all runs
    $MaxColumn = $Tests.Count +1
 
    #Create column for active users
    $col = New-Object system.Data.DataColumn "ActiveSessions",([string])
    $table.columns.add($col)

    $i = 1
	DO
	{
		$Run = "Run_" + $i
		$col = New-Object system.Data.DataColumn $Run,([string])
		$table.columns.add($col)
		$i ++
	} While ($i -le $MaxColumn -1)
    
    #Create column for active users
    $col = New-Object system.Data.DataColumn "Average",([string])
    $table.columns.add($col)

	[hashtable]$Data = @{}
	$i = 1
    
	ForEach ($Item in $Tests)
	{	
		
		$Path = (Get-ChildItem -Path $item.Fullname -Filter "$AppID.csv" -Recurse).FullName
		if ($Path -ne $null) {
			if ($Data.ActiveSessions -eq $null) {
				$import = (Import-CSV $Path | Sort-Object "Date & Time").ActiveSessions
				$Data.Add("ActiveSessions", $import)
			}
	
			$import = (Import-CSV $Path | Sort-Object "Date & Time").StartTime
			$Data.Add("$i", $import)
	
			$i ++
		}
	
	}
	
    $TotalRows = 1
    # Define the max amount of rows
    
    foreach ($key in $Data.Keys) {
        $hashCount = $data.$key.Count
        if ($hashCount -gt $TotalRows) {
            $TotalRows = $hashCount
        }
    }

    $i = 0
    do {
        $row = $table.NewRow()
        $ColumnName = "ActiveSessions"
        $value = $Data."ActiveSessions"[$i]
        $row."$ColumnName" = $value


        $avg = @()

        $keys = $data.Keys | Where-Object {$_ -ne "ActiveSessions"} | Sort-Object
        foreach ($key in $keys) {
            $ColumnName = "Run_" + $key
            $value = $Data.$key[$i]
            $row."$ColumnName" = $value
            $avg += $value
        }

        $ColumnName = "Average"
        $row."$ColumnName" = ($avg | Measure-Object -Average).Average

        $table.Rows.Add($row)
        $i++
    } until ($i -eq $TotalRows)


    $testPath = Test-Path -Path "$($vsiShare)\_VSI_Results\$testName\"
    if ($testPath -eq $false) {
        New-Item -Path "$($vsiShare)\_VSI_Results\$testName\" -ItemType Directory -Force
    }
    
	$table | Export-CSV "$($vsiShare)\_VSI_Results\$testName\$Overview" -Notype
}

$tests = (Get-ChildItem -Path "$($vsiShare)\_VSI_LogFiles\" -Filter $testName*  | Sort-Object).Name

foreach ($test in $tests) {
	$location  = "$($vsiShare)\_VSI_Logfiles\$test\Results\AppStart\"

	if (!(Test-Path -Path $location)) {
		Write-Host (get-date) "- AppStart not found, removing from the set."

		$tests = $tests | Where-Object {$_ -ne $test}
	}
}

ForEach ($item in $tests)
{
		
	Write-Host (get-date) "- Get AppStart from: $item"
	$location  = "$($vsiShare)\_VSI_Logfiles\$item\Results\AppStart\"
	$output = "$($vsiShare)\_VSI_Logfiles\$item"

	
	
	If (!(Test-Path $output))
	{
		Write-Host (get-date) "- Creating dir for AppStart"
		New-Item -Path $output -Type Directory
	}
	
	Get-AppStart "Freemind1" "$location" "$output"
	Get-AppStart "Excel1" "$location" "$output"
	Get-AppStart "Outlook" "$location" "$output"
	Get-AppStart "WinWord1Office" "$location" "$output"
	Get-AppStart "WinWord2Office" "$location" "$output"
	Get-AppStart "PowerPoint1Office" "$location" "$output"
	Get-AppStart "Adobe1" "$location" "$output"
	Get-AppStart "Adobe2" "$location" "$output"
	Get-AppStart "PhotoViewer" "$location" "$output"

}

Combine-Data "Freemind1" $vsiShare $testName
Combine-Data "Excel1" $vsiShare $testName
Combine-Data "Outlook" $vsiShare $testName
Combine-Data "WinWord1Office" $vsiShare $testName
Combine-Data "WinWord2Office" $vsiShare $testName
Combine-Data "PowerPoint1Office" $vsiShare $testName
Combine-Data "Adobe1" $vsiShare $testName
Combine-Data "Adobe2" $vsiShare $testName
Combine-Data "PhotoViewer" $vsiShare $testName
