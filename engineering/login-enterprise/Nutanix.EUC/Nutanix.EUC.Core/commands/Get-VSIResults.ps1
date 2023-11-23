function Get-VSIResults {
    <#
    .SYNOPSIS
    Analyzes the Login VSI tests

    .DESCRIPTION
    Analyzes all the Login VSI test results of each run

    .PARAMETER TestName
    Base testname to analyze
    
    .PARAMETER Share
    The location of the share

    .EXAMPLE
    PS> Get-VSIResults -TestName "Win10_x64" -Path $Scriptroot
    Description of the example.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/function-template.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.EUC

#>

    Param (
        $TestName,
        $Path
    )

    if (-not (Test-Path "$($Path)\testresults")) { New-Item -ItemType Directory -Path "$($Path)\testresults" | Out-Null }
    New-Item -Path "$($Path)\testresults" -Name $TestName -ItemType Directory -Force | Out-Null

    Write-Log -Message "Analyzing test results." -Level Info
    $testNameFilter = $TestName + "_Run"
    $testDirectories = Get-ChildItem -Path "$Path\results" -Directory | Where-Object { $_.Name.StartsWith($testNameFilter) }
    $TestDirMeasure = $testDirectories | Measure-Object

    Write-Log -Message "Found $($TestDirMeasure.Count) tests to analyze." -Level Info
    $count = 1
    $result = @()
    foreach ($test in $testDirectories) {
        Write-Log -Message "Analyzing $count of $($TestDirMeasure.Count) tests." -Level Info
        $data = Import-Csv "$Path\results\$($TestName)_Run$count\VSI-results.csv"
        $result += $data
        $count++
    }
    $result | Export-Csv "$($Path)\testresults\$TestName\VSI-results.csv" -NoTypeInformation
    Copy-Item "$($Path)\results\$($TestName)_Run1\Testconfig.json" -Destination "$($Path)\testresults\$TestName"
    Write-Log -Message "Getting VSI results finished" -Level Info
    $result
}
