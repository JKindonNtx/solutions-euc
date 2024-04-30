<#
.SYNOPSIS
    Kill orphaned test data
.DESCRIPTION
    Cleanup dodgy test data from failed or cancelled test runs. Identifies a dodgy test by a sub folder called "Boot" and no other CSV files in the root.
.PARAMETER LogPath
    Logpath output for all operations. Default path is C:\Logs\ArchiveTestFolders.log
.PARAMETER LogRollover
    Number of days before logfiles are rolled over. Default is 5.
.PARAMETER TestSourceDirectory
    Archive Directory to move tests to for tests
.PARAMETER TestTargetDirectory
    Directory hosting tests
.PARAMETER TestResultsSourceDirectory
    Directory hosting testresults
.PARAMETER TestResultsTargetDirectory
    rchive Directory to move tests to for testsresults
.PARAMETER DaysOlderThan
    Filter for tests older than x number of days using LastWriteTime
.PARAMETER WhatifMode
    Just report, don't delete.

.EXAMPLE
& ArchiveTestData.ps1 -TestSourceDirectory "C:\devops\solutions-euc\engineering\login-enterprise\results" -TestResultsSourceDirectory "C:\devops\solutions-euc\engineering\login-enterprise\testresults" -TestTargetDirectory "\\WS-Files\Automation\Test-Archive\results" -TestResultsTargetDirectory "\\WS-Files\Automation\Test-Archive\testresults"  -DaysOlderThan 30 -WhatifMode

Will move all test data from "C:\devops\solutions-euc\engineering\login-enterprise\results" and "C:\devops\solutions-euc\engineering\login-enterprise\testresults" to "\\WS-Files\Automation\Test-Archive\results" and "\\WS-Files\Automation\Test-Archive\testresults" respectively. WhatIfMode, report only

Logs output to C:\Logs\ArchiveTestFolders.log

#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\ArchiveTestFolders.log", # Where we log to

    [Parameter(Mandatory = $false)]
    [int]$LogRollover = 5, # Number of days before logfile rollover occurs

    [Parameter(Mandatory = $false)]
    [string]$TestSourceDirectory = "C:\devops\solutions-euc\engineering\login-enterprise\results",

    [Parameter(Mandatory = $false)]
    [string]$TestTargetDirectory = "\\WS-Files\Automation\Test-Archive\results",

    [Parameter(Mandatory = $false)]
    [string]$TestResultsSourceDirectory = "C:\devops\solutions-euc\engineering\login-enterprise\testresults",

    [Parameter(Mandatory = $false)]
    [string]$TestResultsTargetDirectory = "\\WS-Files\Automation\Test-Archive\testresults",

    [Parameter(Mandatory = $true)]
    [int]$DaysOlderThan = 30,

    [Parameter(Mandatory = $false)]
    [switch]$WhatifMode
)
#endregion Params

#region Functions
# ============================================================================
# Functions
# ============================================================================
function Write-Log {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [Alias('LogPath')]
        [string]$Path = $LogPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoClobber
    )

    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process {
        
        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
        }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
        }

        else {
            # Nothing to see here yet.
        }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
            }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
            }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
            }
        }
        
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End {
    }
}

function Start-Stopwatch {
    Write-Log -Message "Starting Timer" -Level Info
    $Global:StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
}

function Stop-Stopwatch {
    Write-Log -Message "Stopping Timer" -Level Info
    $StopWatch.Stop()
    if ($StopWatch.Elapsed.TotalSeconds -le 1) {
        Write-Log -Message "Script processing took $($StopWatch.Elapsed.TotalMilliseconds) ms to complete." -Level Info
    }
    else {
        Write-Log -Message "Script processing took $($StopWatch.Elapsed.TotalSeconds) seconds to complete." -Level Info
    }
}

function RollOverlog {
    $LogFile = $LogPath
    $LogOld = Test-Path $LogFile -OlderThan (Get-Date).AddDays(-$LogRollover)
    $RolloverDate = (Get-Date -Format "dd-MM-yyyy")
    if ($LogOld) {
        Write-Log -Message "$LogFile is older than $LogRollover days, rolling over" -Level Info
        $NewName = [io.path]::GetFileNameWithoutExtension($LogFile)
        $NewName = $NewName + "_$RolloverDate.log"
        Rename-Item -Path $LogFile -NewName $NewName
        Write-Log -Message "Old logfile name is now $NewName" -Level Info
    }    
}

function StartIteration {
    Write-Log -Message "--------Starting Iteration--------" -Level Info
    RollOverlog
    Start-Stopwatch
}

function StopIteration {
    Stop-Stopwatch
    Write-Log -Message "--------Finished Iteration--------" -Level Info
}

#endregion

#Region Execute
# ============================================================================
# Execute
# ============================================================================
StartIteration

Write-Log -Message "Logfile Path is $($LogPath)" -Level Info

if ($WhatifMode) {
    Write-Log -Message "Processing in Whatif Mode. Will not delete any data" -Level Info
}

Write-Log -Message "Processing Tests Folder: $($TestSourceDirectory)" -Level Info

# Get folders older than x days
try {
    $TestsToMove = Get-ChildItem -Path $TestSourceDirectory -Directory -ErrorAction Stop | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOlderThan) } #| Where-Object {$_.FullName -like "*Amaste*"}
}
catch {
    Write-Log -Message "$_" -Level Error
    Exit 1
}

# Output the list of filtered directories
Write-Log -Message "There are $(($TestsToMove | Measure-Object).Count) Directories to archive" -Level Info

foreach ($dir in $TestsToMove) {

    $destinationPath = Join-Path -Path $TestTargetDirectory -ChildPath $dir.Name
    
    if (-not $WhatifMode) {
        try {
            # Move the directory to the destination
            Move-Item -Path $dir.FullName -Destination $destinationPath -ErrorAction Stop
            Write-Log -Message "Directory $($dir.FullName) moved to $destinationPath." -Level Info
        }
        catch {
            Write-Log -Message "$_" -Level warning
            Continue
        }
    } else {
        Write-Log -Message "WHATIF: Directory $($dir.FullName) would be archived to $destinationPath." -Level Info
    }
}

Write-Log -Message "Processing Testresults Folder: $($TestResultsSourceDirectory)" -Level Info

$TestsToMove = $null

# Get folders older than x days
try {
    $TestsToMove = Get-ChildItem -Path $TestResultsSourceDirectory -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOlderThan) } #| Where-Object {$_.FullName -like "*Amaste*"}
}
catch {
    Write-Log -Message "$_" -Level Error
    Exit 1
}

# Output the list of filtered directories
Write-Log -Message "There are $(($TestsToMove | Measure-Object).Count) Directories to archive" -Level Info

foreach ($dir in $TestsToMove) {

    $destinationPath = Join-Path -Path $TestResultsTargetDirectory -ChildPath $dir.Name
    
    if (-not $WhatifMode) {
        try {
            # Move the directory to the destination
            Move-Item -Path $dir.FullName -Destination $destinationPath -ErrorAction Stop
            Write-Log -Message "Directory $($dir.FullName) moved to $destinationPath." -Level Info
        }
        catch {
            Write-Log -Message "$_" -Level warning
            Continue
        }

    } else {
        Write-Log -Message "WHATIF: Directory $($dir.FullName) would be archived to $destinationPath." -Level Info
    }
}

StopIteration
Exit 0
#endregion