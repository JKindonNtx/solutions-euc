Function Get-VSIResults {
    ##############################
    #.SYNOPSIS
    #Analyzes the Login VSI tests
    #
    #.DESCRIPTION
    #Analyzes all the Login VSI test results of each run
    #
    #.PARAMETER TestName
    #Base testname to analyze
    #
    #.PARAMETER Share
    #The location of the share
    #
    #.EXAMPLE
    #Get-VSIResults -TestName "Win10_x64" -Path $Scriptroot
    #
    #.NOTES
    #General notes
    ##############################
    Param(
        [string]$TestName,
        [string]$Path
    )

    if (-not (Test-Path "$($Path)\testresults")) { New-Item -ItemType Directory -Path "$($Path)\testresults" | Out-Null }
    New-Item -Path "$($Path)\testresults" -Name $TestName -ItemType Directory -Force | Out-Null

    Write-Log "Analyzing test results."
    $testNameFilter = $TestName + "_Run"
    $testDirectories = Get-ChildItem -Path "$Path\results" -Directory | Where-Object {$_.Name.StartsWith($testNameFilter)}

    Write-Log "Found $($testDirectories.Count) tests to analyze."
    $count = 1
    $result = @()
    foreach ($test in $testDirectories) {
        Write-Log "Analyzing $count of $($testDirectories.Count) tests."
        $data = Import-Csv "$Path\results\$($TestName)_Run$count\VSI-results.csv"
        $result += $data
    }
    $result | Export-Csv "$($Path)\testresults\$TestName\VSI-results.csv" -NoTypeInformation
    Copy-Item "$($Path)\results\$($TestName)_Run1\Testconfig.json" -Destination "$($Path)\testresults\$TestName"
    Write-Log "Getting VSI results finished"
    $result
   
    #$Totalresults = @()
    #$results = New-Object PSObject
    #$results += "TestName,started,finished,activesessionCount,login success,login total,EUX score,vsiMax,vsiMax state,Comment"

    #$vsifiles = foreach ($test in $testDirectories) {
        # Write-Log "Analyzing $count of $($testDirectories.Count) tests."
       # Get-ChildItem "$Path\results\$($TestName)_Run$count\VSI-results.csv"
      #  $VSIresults = import-csv "$Path\results\$($TestName)_Run$count\VSI-results.csv"
      #  $results | Add-Member -MemberType NoteProperty -Name "TestName" -Value "$($TestName)_Run$count"
      #  $results | Add-Member -MemberType NoteProperty -Name "started" -Value $VSIresults.started
      #  $results | Add-Member -MemberType NoteProperty -Name "finished" -Value $VSIresults.finished
      #  $results | Add-Member -MemberType NoteProperty -Name "activesessionCount" -Value $VSIresults.activesessionCount
      #  $results | Add-Member -MemberType NoteProperty -Name "login success" -Value $($VSIresults."login success")
      #  $results | Add-Member -MemberType NoteProperty -Name "login total" -Value $($VSIresults."login total")
      #  $results | Add-Member -MemberType NoteProperty -Name "EUX score" -Value $($VSIresults."EUX score")
      #  $results | Add-Member -MemberType NoteProperty -Name "vsiMax" -Value $VSIresults.vsiMax
      #  $results | Add-Member -MemberType NoteProperty -Name "vsiMax state" -Value $($VSIresults."vsiMax state")
      #  $results | Add-Member -MemberType NoteProperty -Name "Comment" -Value $VSIresults.comment

      #  $Totalresults += $results
      #  $count++
    # }
    #Get-Content $vsifiles | Set-Content "$($Path)\testresults\$TestName\VSI-results.csv"
    # $Totalresults | Export-Csv -Path "$($Path)\testresults\$TestName\VSI-results.csv" -NoTypeInformation
    # $Totalresults
    
}

