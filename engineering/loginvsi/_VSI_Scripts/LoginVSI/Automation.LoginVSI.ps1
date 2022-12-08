Function Start-Test {
    ##############################
    #.SYNOPSIS
    #Starts Login VSI test
    #
    #.DESCRIPTION
    #Starts the Login VSI test
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
    #Start-Test -TestName "Win10_x64_run_1" -Share "\\VAL-FS03\VSIShare" -Workload "KnowledgeWorker"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$TestName,
        [string]$Share,
        [string]$Workload

    )

    Write-Host (Get-Date) ": Starting Login VSI test."

    $testPath = "$Share\_VSI_Logfiles\$TestName"

	New-Item -Path "$Share\_VSI_Logfiles\" -name $TestName -itemtype Directory | Out-Null
	Copy-Item -Path "$Share\_VSI_Configuration\_CurrentTest\*" -Destination $testPath
	
    $OfficalWorkloadPath = "$Share\_VSI_Workloads\Official Workloads\$Workload.txt"
    $CustomWorkloadPath = "$Share\_VSI_Workloads\Custom Workloads\$Workload.txt"

	if (Test-Path -Path $OfficalWorkloadPath) {
		Copy-Item -Path $OfficalWorkloadPath -Destination "$testPath\$Workload.txt"
	} elseif (Test-Path -Path $CustomWorkloadPath) {
		Copy-Item -Path $CustomWorkloadPath -Destination "$testPath\$Workload.txt"
	} else {
        Write-Error "Cannot find the configured workload named: $Workload"
    }
	
    Remove-Item "$($Share)\*.IsActiveTest" -Force
	$ActiveTest = "!!!_" + $TestName + ".IsActiveTest" 
	New-Item -Path $Share -Name $ActiveTest -itemtype File | Out-Null
	Set-Content "$Share\$ActiveTest" ([Guid]::NewGuid().Guid)

    Write-Host (Get-Date) ": Login VSI test started." 
}

Function Monitor-Test {
    ##############################
    #.SYNOPSIS
    #Monitors the test
    #
    #.DESCRIPTION
    #Monitors the active Login VSI test
    #
    #.PARAMETER TestName
    #Testname of the test to monitor
    #
    #.PARAMETER Share
    #The Login VSI Share location
    #
    #.PARAMETER Sessions
    #The maximium amount of sessions to be launched
    #
    #.EXAMPLE
    #Monitor-Test -TestName "Win10_x64_run_1" -Share "\\VAL-FS03\VSIShare" -Sessions 200
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$TestName,
        [string]$Share,
        [int]$Sessions,
        [int]$LogoffTimeout
    )

    Write-Host (Get-Date) ": Monitor Login VSI test."
    
    $timeoutTime = 75
    $startTime = Get-Date
    $timeout = $false

    $monitorPath = "$Share\_VSI_LogFiles\$TestName\Monitor\LaunchedSessions"

    while (!(Test-Path -Path $monitorPath)) {
        Start-Sleep -Seconds 5

        if (((Get-Date) - $startTime).TotalMinutes -gt $timeoutTime) {
            $timeout = $true
            break
        }
    }
	
    if (!($timeout)) {
        while((Get-ChildItem -Path $monitorPath).Count -lt $Sessions) {
            $sessionCount = (Get-ChildItem -Path $monitorPath).Count
            Write-Host (Get-Date) ": $sessionCount of $Sessions sessions launched."

            Start-Sleep -Seconds 30

            if (((Get-Date) - $startTime).TotalMinutes -gt $timeoutTime) {
                $timeout = $true
                break
            }
        }
    }

    if (!($timeout)) {
        Write-Host (Get-Date) ": All sessions launched."
        $LogofftimeMin = [math]::Round([int]$LogoffTimeout / 60)
        Write-Host (get-date) ": Waiting $($LogofftimeMin) min. for the loop to finish..."
        Start-Sleep -Seconds $LogoffTimeout
    }

    if ($timeout) {
        Write-Host (Get-Date) ": Time exceeded, stopping the test." 
    }
}

Function Finish-Test {
    ##############################
    #.SYNOPSIS
    #Finish the Login VSI test
    #
    #.DESCRIPTION
    #Finish the active Login VSI test
    #
    #.PARAMETER Share
    #The location of the share
    #
    #.EXAMPLE
    #Finish-Test -Share "\\VAL-FS03\VSIShare"
    #
    #.NOTES
    #General notes
    ##############################

    Param(
        [string]$Share
    )

    Write-Host (Get-Date) ": Finishing Login VSI test."
    Get-ChildItem -Path $Share | Where-Object { $_.Name.StartsWith("!!!_") } | Remove-Item -Force -Confirm:$false
}

Function Analyze-Tests {
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
    #Analyze-Tests -TestName "Win10_x64" -Share "\\VAL-FS03\VSIShare"
    #
    #.NOTES
    #General notes
    ##############################
    Param(
        [string]$TestName,
        [string]$Share
    )

    Write-Host (Get-Date) ": Analyzing test results."
    $testNameFilter = $TestName + "_run"
    $testDirectories = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($testNameFilter)}

    Write-Host (Get-Date) ": Found $($testDirectories.Count) tests to analyze."
    $count = 1
    $results = @()
    $results += "TestName,DataTime,BaseLine,VSIMax,Uncorrected,VSIMaxDynamic,LaunchedSessions,ActiveSessions,VSIMaxReached"

    foreach ($test in $testDirectories) {
        Write-Host (Get-Date) ": Analyzing $count of $($testDirectories.Count) tests."

        $processInfo = New-Object System.Diagnostics.ProcessStartInfo 
        $processInfo.FileName = "$Share\_VSI_Binaries\Analyzer\Login VSI Analyzer Console.exe"
        $processInfo.RedirectStandardError = $true 
        $processInfo.RedirectStandardOutput = $true 
        $processInfo.UseShellExecute = $false 
        $processInfo.Arguments = $($test.Name)
        $process = New-Object System.Diagnostics.Process 
        $process.StartInfo = $processInfo 
        $process.Start() | Out-Null 
        $process.WaitForExit() 
        $results += $process.StandardOutput.ReadToEnd().Trim()

        $count++
    }

    Set-Content -Path "$Share\$TestName.csv" -Value $results | Out-Null

    $testDirectories = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($testNameFilter)}

    foreach ($test in $testDirectories) {
        $testPath = $test.FullName

        $userLogons = @()
        $files = Get-ChildItem "$testPath\Monitor\LaunchedSessions\*.txt"
        foreach ($file in $files) {
            
            $match = $file.name.Replace(".txt","") -match '(?<=\##)(.*?)(?=_#)'
            if($match) {
                
                $userID = $Matches[0]
    
                $activeFiles = Get-ChildItem "$testPath\Monitor\ActiveSessions\$userID*.log"
    
                foreach ($fileActive in $activeFiles) {
    
                    if($fileActive.name.Split('@')[0] -eq $userID) {
    
                        $item = New-Object PSObject    
                        $item | Add-Member Noteproperty DateTime $file.LastWriteTime.ToString('MM/dd/yyyy HH:mm:ss')                       
                        $item | Add-Member Noteproperty User $userid
                        $item | Add-Member Noteproperty LogonTime ($fileActive.LastWriteTime - $file.LastWriteTime).TotalSeconds
    
                        $userLogons += $item
                    }	
                }
            }
        }
    
        $match = $test.Name -Match "(\d+)(?!.*\d)"
        $number = $matches[0]
        $name = $test.Name.TrimEnd($number) + "Logon_" + $number
        $userLogons | Sort-Object DateTime | Export-Csv "$testPath\$($name).csv" -NoTypeInformation
    }

    Start-Process -FilePath "$Share\_VSI_Tools\PPD\PPD.exe" -WorkingDirectory "$Share\_VSI_Tools\PPD\" -ArgumentList "-t `"$TestName*`"" -NoNewWindow -Wait

    New-Item -Path "$Share\_VSI_Results\" -Name $TestName -ItemType Directory -Force | Out-Null
    Get-ChildItem -Path $Share | Where-Object {$_.Name.StartsWith("$($TestName)")} | Move-Item -Destination "$Share\_VSI_Results\$TestName"
    #& $Share\_VSI_Scripts\LoginVSI\Automation.AppStarts.ps1 $Share $TestName
    Copy-Item "$Share\_VSI_Scripts\config.json" -Destination "$Share\_VSI_Results\$TestName"
    if ($($config.CaptureHostData)){
        Export-charts "$Share\_VSI_Results\$TestName\$($TestName)_run_AHV.xlsx" -outputType PNG
        try{
            Rename-Item -Path "$Share\_VSI_Results\$TestName\Charts_CPU usage.PNG" -NewName "$TestName-CPU.PNG" -Force
        }
        catch{
            Write-Host "Charts_CPU usage.PNG does not exist."
        }
    }
}

Function Analyze-SingleTest {
    ##############################
    #.SYNOPSIS
    #Analyzes a Login VSI test
    #
    #.DESCRIPTION
    #Analyzes a single Login VSI test
    #
    #.PARAMETER TestName
    #Testname to analyze
    #
    #.PARAMETER Share
    #The location of the share
    #
    #.EXAMPLE
    #Analyze-Tests -TestName "Win10_x64_run1" -Share "\\VAL-FS03\VSIShare"
    #
    #.NOTES
    #General notes
    ##############################
    Param(
        [string]$Share,
        [string]$TestNameRun
    )

    Write-Host (Get-Date) ": Analyzing test result."

    $results = @()
    $results += "TestName,DataTime,BaseLine,VSIMax,Uncorrected,VSIMaxDynamic,LaunchedSessions,ActiveSessions,VSIMaxReached"
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo 
    $processInfo.FileName = "$Share\_VSI_Binaries\Analyzer\Login VSI Analyzer Console.exe"
    $processInfo.RedirectStandardError = $true 
    $processInfo.RedirectStandardOutput = $true 
    $processInfo.UseShellExecute = $false 
    $processInfo.Arguments = "$($testNameRun) -graph $($Share)\VSIgraph.jpg"
    $process = New-Object System.Diagnostics.Process 
    $process.StartInfo = $processInfo 
    $process.Start() | Out-Null 
    $process.WaitForExit() 
    $results += $process.StandardOutput.ReadToEnd().Trim()

    Set-Content -Path "$Share\$TestNameRun.csv" -Value $results | Out-Null
    # Copy to testnamerun dir and set name to testname_VSI_runx.csv
    $VSIfilename = $testNameRun -split '_run_'
    #$newVSIfilename = "$($VSIfilename[0])_VSI_run_$($VSIfilename[1])"
    Move-Item -Path "$($Share)\$($TestNameRun).csv" -Destination "$Share\_VSI_Logfiles\$TestNameRun\VSI_Result_Run$($VSIfilename[1]).csv" -Force
    # Move graph to $share\_VSI_LogFiles\testnamerun
    Move-Item -Path "$($Share)\VSIgraph.jpg" -Destination "$Share\_VSI_Logfiles\$TestNameRun\$TestNameRun.jpg" -Force
    $sourcepath = "$Share\_VSI_Logfiles\$TestNameRun\$TestNameRun.jpg"
    $destpath = "$Share\_VSI_Logfiles\$TestNameRun\$TestNameRun.png"
    $TestnameResult = "$Share\_VSI_Logfiles\$TestNameRun\VSI_Result_Run$($VSIfilename[1]).csv"
    AddTextToImage -sourcePath $sourcepath -destpath $destpath -Testnameresult $TestnameResult
}

Function  Consolidate-Tests {
    ##############################
    #.SYNOPSIS
    #Consolidates the test result
    #
    #.DESCRIPTION
    #Consolidates the test results in a zip file
    #
    #.PARAMETER TestName
    #Base testname to analyze
    #
    #.PARAMETER Share
    #The location of the share
    #
    #.EXAMPLE
    #Consolidate-Tests -TestName "Win10_x64" -Share "\\VAL-FS03\VSIShare"
    #
    #.NOTES
    #Initial creation
    ##############################
    Param(
        [string]$TestName,
        [string]$Share
    )
    Write-Host (Get-Date) ": Consolidate results."
    $testNameFilter = $TestName + "_run"
    $testDirectories = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($testNameFilter)}

    $destination = "$($Share)\$($TestName).zip"

    if (!(Test-path -Path $destination)) {

        New-Item -Path $Share -Name $TestName -ItemType Directory | Out-Null
        $testDirectories | Copy-Item -Destination "$Share\$TestName" -Recurse

        Compress-Archive -Path "$Share\$TestName\*" -DestinationPath $destination
        
        Get-ChildItem -Path $Share -Include "*.csv", "*.xlsx" | Where-Object {$_.Name.StartsWith($TestName)} | Compress-Archive -Update -DestinationPath $destination
        Remove-Item -Path "$Share\$TestName" -Recurse -Force -Confirm:$false | Out-Null
    } 

}
function Update-VSIconfig {
    ##############################
    #.SYNOPSIS
    #Updates the configuration for LoginVSI
    #
    #.DESCRIPTION
    #
    #
    #.PARAMETER Config
    #Configfile
    #
    #
    #.EXAMPLE
    #Update-VSIconfig -Config $Config
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config
    )
 
    Install-Module -Name PsIni -RequiredVersion 2.0.0
    Import-Module PsIni
    $VSIGlobal = Get-IniContent -FilePath "$($config.Share)\_VSI_Configuration\_CurrentTest\Global.ini"
    if ($($config.TargetPlatform) -eq "Multi user") {
        $VSIGlobal["Settings"]["SBC_timer_detect"] = "1"
    }
    elseif ($($config.TargetPlatform) -eq "Single user") {
        $VSIGlobal["Settings"]["SBC_timer_detect"] = "0"
    }
    $VSIGlobal | Out-IniFile -FilePath "$($config.Share)\_VSI_Configuration\_CurrentTest\Global.ini" -Encoding "ASCII" -Force

    $VSILauncher = Get-IniContent -FilePath "$($config.Share)\_VSI_Configuration\_CurrentTest\VSILauncher.ini"
    $VSILauncher["Launcher"]["NumberOfSessions"] = "$($config.SessionCount)" 
    $VSILauncher["Launcher"]["LogoffTimeOut"] = "$($config.LogoffTimeOut)"
    $VSILauncher["Phase1"]["Sessions"] = "$($config.SessionCount)"
    if ($($config.SessionCfg) -eq "Console") {
        $VSILauncher["Launcher"]["Servername"] = "$($config.VMname){count/3}"
        $VSILauncher["Launcher_FD"]["Servername"] = "$($config.VMname){count/3}"
        $VSILauncher["Launcher"]["useCSV"] = "0"
        $VSILauncher["Launcher_FD"]["useCSV"] = "0"
        $VSILauncher["Launcher"]["CCL"] = "{VSISHARE}\_VSI_Binaries\Connectors\ConsoleConnector\DDC.exe /server {server} /user {username} /domain {domain} /password {password}#"
        $VSILauncher["Launcher_FD"]["CCL"] = "{VSISHARE}\_VSI_Binaries\Connectors\ConsoleConnector\DDC.exe /server {server} /user {username} /domain {domain} /password {password}#"
    }
    elseif ($($config.SessionCfg) -eq "Blast") {
        $Viewconfig = Get-Content -Path "$($Config.Share)\_VSI_Scripts\VMware\config.view.json" -Raw | ConvertFrom-Json
        $VSILauncher["Launcher"]["Servername"] = "$($viewconfig.ConnectionServer)"
        $VSILauncher["Launcher_FD"]["Servername"] = "$($viewconfig.ConnectionServer)"
        $VSILauncher["Launcher"]["useCSV"] = "0"
        $VSILauncher["Launcher_FD"]["useCSV"] = "0"
        $VSILauncher["Launcher"]["CCL"] = "C:\Program Files (x86)\VMware\VMware Horizon View Client\vmware-view.exe -serverURL {server} -desktopProtocol Blast -username {username} -password {password} -domainName {domain} -desktopName `"$($config.PoolName)`" -standAlone -logInAsCurrentUser False -nonInteractive#"
        $VSILauncher["Launcher_FD"]["CCL"] = "C:\Program Files (x86)\VMware\VMware Horizon View Client\vmware-view.exe -serverURL {server} -desktopProtocol Blast -username {username} -password {password} -domainName {domain} -desktopName `"$($config.PoolName)`" -standAlone -logInAsCurrentUser False -nonInteractive#"
    }  
    elseif ($($config.SessionCfg) -eq "PCoIP") {
        $Viewconfig = Get-Content -Path "$($Config.Share)\_VSI_Scripts\VMware\config.view.json" -Raw | ConvertFrom-Json
        $VSILauncher["Launcher"]["Servername"] = "$($viewconfig.ConnectionServer)"
        $VSILauncher["Launcher_FD"]["Servername"] = "$($viewconfig.ConnectionServer)"
        $VSILauncher["Launcher"]["useCSV"] = "0"
        $VSILauncher["Launcher_FD"]["useCSV"] = "0"
        $VSILauncher["Launcher"]["CCL"] = "C:\Program Files (x86)\VMware\VMware Horizon View Client\vmware-view.exe -serverURL {server} -desktopProtocol PCoIP -username {username} -password {password} -domainName {domain} -desktopName `"$($config.PoolName)`" -standAlone -logInAsCurrentUser False -nonInteractive#"
        $VSILauncher["Launcher_FD"]["CCL"] = "C:\Program Files (x86)\VMware\VMware Horizon View Client\vmware-view.exe -serverURL {server} -desktopProtocol PCoIP -username {username} -password {password} -domainName {domain} -desktopName `"$($config.PoolName)`" -standAlone -logInAsCurrentUser False -nonInteractive#"
    }  
    elseif ($($config.SessionCfg) -eq "ICA") {
        $Citrixconfig = Get-Content -Path "$($Config.Share)\_VSI_Scripts\Citrix\config.XenDesktop.json" -Raw | ConvertFrom-Json
        $VSILauncher["Launcher"]["Servername"] = "$($Citrixconfig.StoreFront)"
        $VSILauncher["Launcher_FD"]["Servername"] = "$($Citrixconfig.StoreFront)"
        $VSILauncher["Launcher"]["useCSV"] = "0"
        $VSILauncher["Launcher_FD"]["useCSV"] = "0"
        $VSILauncher["Launcher"]["CCL"] = "{VSISHARE}\_VSI_Binaries\Connectors\SFConnect.exe /url http://$($Citrixconfig.StoreFront)/Citrix/Store /user {username} /password {password} /domain {domain} /resource `"$($config.PoolName)`""
        $VSILauncher["Launcher_FD"]["CCL"] = "{VSISHARE}\_VSI_Binaries\Connectors\SFConnect.exe /url http://$($Citrixconfig.StoreFront)/Citrix/Store /user {username} /password {password} /domain {domain} /resource `"$($config.PoolName)`""
    }
    elseif ($($config.SessionCfg) -eq "Frame") {
        $Frameconfig = Get-Content -Path "$($Config.Share)\_VSI_Scripts\Nutanix\config.Frame.json" -Raw | ConvertFrom-Json
        $VSILauncher["Launcher"]["useCSV"] = "1"
        $VSILauncher["Launcher_FD"]["useCSV"] = "1"
        $VSILauncher["Launcher"]["CSV"] = "$($Frameconfig.CSV)"
        $VSILauncher["Launcher_FD"]["CSV"] = "$($Frameconfig.CSV)"
        $VSILauncher["Launcher"]["CCL"] = "powershell.exe -ExecutionPolicy ByPass -command `"{VSISHARE}\_VSI_Binaries\Connectors\FrameConnector\FrameConnector.ps1 -Count {CSV_Count} -ADuser {CSV_ADUser}  -Domain {domain} -ADpassword  {CSV_ADPassword} -TargetVM {CSV_TargetVM} -FrameToken {CSV_FrameToken}  -VSIshare {VSISHARE}`"#"
        $VSILauncher["Launcher_FD"]["CCL"] = "powershell.exe -ExecutionPolicy ByPass -command `"{VSISHARE}\_VSI_Binaries\Connectors\FrameConnector\FrameConnector.ps1 -Count {CSV_Count} -ADuser {CSV_ADUser}  -Domain {domain} -ADpassword  {CSV_ADPassword} -TargetVM {CSV_TargetVM} -FrameToken {CSV_FrameToken}  -VSIshare {VSISHARE}`"#"
    }
    $VSILauncher | Out-IniFile -FilePath "$($config.Share)\_VSI_Configuration\_CurrentTest\VSILauncher.ini" -Encoding "ASCII" -Force
}

Function AddTextToImage {
    # Orignal code from http://www.ravichaganti.com/blog/?p=1012
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][String] $sourcePath,
        [Parameter(Mandatory=$true)][String] $destPath,
        [System.Object] $TestnameResult
    )

    $Testresult = import-csv $TestnameResult
    Write-Verbose "Load System.Drawing"
    [Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
     
    Write-Verbose "Get the image from $sourcePath"
    $srcImg = [System.Drawing.Image]::FromFile($sourcePath)
     
    Write-Verbose "Create a bitmap as $destPath"
    $bmpFile = new-object System.Drawing.Bitmap([int]($srcImg.width)),([int]($srcImg.height))
 
    Write-Verbose "Intialize Graphics"
    $Image = [System.Drawing.Graphics]::FromImage($bmpFile)
    $Image.SmoothingMode = "AntiAlias"
     
    $Rectangle = New-Object Drawing.Rectangle 0, 0, $srcImg.Width, $srcImg.Height
    $Image.DrawImage($srcImg, $Rectangle, 0, 0, $srcImg.Width, $srcImg.Height, ([Drawing.GraphicsUnit]::Pixel))
 
    Write-Verbose "Draw title: LoginVSI results:"
    $Font = new-object System.Drawing.Font("Calibri", 16)
    $Brush = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 0, 0,0))
    $Image.DrawString("LoginVSI Results:", $Font, $Brush, 180, 100)
    
    Write-Verbose "Draw VSIbase: $($Testresult.Baseline)"
    $Font = New-object System.Drawing.Font("Calibri", 10)
    $Brush = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 0, 0, 0))
    $Image.DrawString("VSIbase: $($Testresult.Baseline)", $Font, $Brush, 180, 130)
 
    Write-Verbose "Draw VSImax: $($Testresult.VSIMax)"
    $Font = New-object System.Drawing.Font("Calibri", 10)
    $Brush = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 0, 0, 0))
    $Image.DrawString("VSImax: $($Testresult.VSIMax)", $Font, $Brush, 180, 140)

    Write-Verbose "Draw VSImax threshold: $($Testresult.VSIMaxDynamic)"
    $Font = New-object System.Drawing.Font("Calibri", 10)
    $Brush = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 0, 0, 0))
    $Image.DrawString("VSImax threshold: $($Testresult.VSIMaxDynamic)", $Font, $Brush, 180, 150)

    [Int]$Stucksessions = [Int]$Testresult.LaunchedSessions - [Int]$Testresult.ActiveSessions

    Write-Verbose "Draw Stuck sessions: $Stucksessions"
    $Font = New-object System.Drawing.Font("Calibri", 10)
    $Brush = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 0, 0, 0))
    $Image.DrawString("Stuck sessions: $Stucksessions", $Font, $Brush, 180, 160)

    Write-Verbose "Save and close the files"
    $bmpFile.save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpFile.Dispose()
    $srcImg.Dispose()
}

Function Export-charts {
    <# 
    .Synopsis 
        Exports the charts in an Excel spreadSheet 
    .Example 
        Export-Charts .\test,xlsx 
        Exports the charts in test.xlsx to JPEG files in the current directory. 
 
    .Example 
        Export-Charts -path .\test,xlsx -destination [System.Environment+SpecialFolder]::MyDocuments -outputType PNG -passthrough 
        Exports the charts to PNG files in MyDocuments , and returns file objects representing the newly created files 
 
#>
Param (
    #Path to the Excel file whose chars we will export. 
    $Path          = "C:\Users\public\Documents\stats.xlsx", 
    #If specified, output file objects representing the image files. 
    [switch]$passthru, 
    #Format to write - JPG by default 
    [ValidateSet("JPG","PNG","GIF")]
    $OutputType = "JPG", 
    #Folder to write image files to (defaults to same one as the Excel file is in) 
    $Destination
)

#if no output folder was specified, set destination to the folder where the Excel file came from 
if (-not $Destination) {$Destination = Split-Path -Path $path -Parent } 

#Call up Excel and tell it to open the file. 
try   { $excelApp      = New-Object -ComObject "Excel.Application" } 
catch { Write-Warning "Could not start Excel application - which usually means it is not installed."  ; return } 

$excelApp.Visible = 0

try   { $excelWorkBook = $excelApp.Workbooks.Open($path) } 
catch { Write-Warning "Could not start Excel application - which usually means it is not installed."  ; return } 


#For each worksheet, for each chart, jump to the chart, create a filename of "WorksheetName_ChartTitle.jpg", and export the file. 
foreach ($excelWorkSheet in $excelWorkBook.Worksheets) {
    #note somewhat unusual way of telling excel we want all the charts. 
    foreach ($excelchart in $excelWorkSheet.ChartObjects([System.Type]::Missing))  {
        #if you don't go to the chart the image will be zero size ! 
        $excelApp.Goto($excelchart.TopLeftCell,$true)
        $imagePath  = Join-Path -Path $Destination -ChildPath ($excelWorkSheet.Name + "_" + ($excelchart.Chart.ChartTitle.Text -split "\s\d\d:\d\d,")[0] + ".$OutputType")
        if ( $excelchart.Chart.Export($imagePath, $OutputType, $false) ) {  # Export returs true/false for success/failure 
            if ($passThru) {Get-Item -Path $imagePath }                     # when succesful return a file object (-passthru) or print a verbose message, write warning for any failures 
            else {Write-Verbose -Message "Exported $imagePath"}
        } 
        else     {Write-Warning -Message "Failure exporting $imagePath" } 
    }
}
$excelApp.ActiveWorkbook.Save()
$excelApp.Quit()
}