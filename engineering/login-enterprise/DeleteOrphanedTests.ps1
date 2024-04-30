<#
.SYNOPSIS
    Kill orphaned test data
.DESCRIPTION
    Cleanup dodgy test data from failed or cancelled test runs. Identifies a dodgy test by a sub folder called "Boot" and no other CSV files in the root.
.PARAMETER LogPath
    Logpath output for all operations. Default path is C:\Logs\DeleteOrphanedTestFolders.log
.PARAMETER LogRollover
    Number of days before logfiles are rolled over. Default is 5.
.PARAMETER TestDirectory
    Root Directory to look for tests
.PARAMETER DaysOlderThan
    Filter for tests older than x number of days using LastWriteTime
.PARAMETER BootFolder
    Folder to identify is an orphan test. Default is Boot
.PARAMETER WhatifMode
    Just report, don't delete.

.EXAMPLE
& DeleteOrphanedTests.ps1 -TestDirectory "C:\devops\solutions-euc\engineering\login-enterprise\results" -DaysOlderThan 30

Will delete all tests in the "C:\devops\solutions-euc\engineering\login-enterprise\results" directory older than 30 days that contain a folder called "boot" and no other files in the root. This indicates a failed test. 
Logs output to C:\Logs\DeleteOrphanedTestFolders.log

& DeleteOrphanedTests.ps1 -TestDirectory "C:\devops\solutions-euc\engineering\login-enterprise\results" -DaysOlderThan 10 -BootFolder "Boot" -WhatifMode 

Will report on all tests in the "C:\devops\solutions-euc\engineering\login-enterprise\results" directory older than 10 days that contain a folder called "boot" and no other files in the root. This indicates a failed test. Whatif mode, won't Delete. 
Logs output to C:\Logs\DeleteOrphanedTestFolders.log

#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\DeleteOrphanedTestFolders.log", # Where we log to

    [Parameter(Mandatory = $false)]
    [int]$LogRollover = 5, # Number of days before logfile rollover occurs

    [Parameter(Mandatory = $false)]
    [string]$TestDirectory = "C:\devops\solutions-euc\engineering\login-enterprise\results",

    [Parameter(Mandatory = $true)]
    [int]$DaysOlderThan = 30,

    [Parameter(Mandatory = $false)]
    [string]$BootFolder = "Boot",

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

# Get all directories in the parent directory
try {
    $directories = Get-ChildItem -Path $TestDirectory -Directory -ErrorAction Stop | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOlderThan) }
}
catch {
    Write-Log -Message "$_" -Level Error
    Exit 1
}

# Filter directories where only one specific subdirectory exists and no files
$DodgyTestDirectories = foreach ($dir in $directories) {
    # Get subdirectories of the current directory
    $subdirectories = Get-ChildItem -Path $dir.FullName -Directory

    # Get files in the current directory
    $files = Get-ChildItem -Path $dir.FullName -File

    # Check if only one specific subdirectory exists and there are no files
    if ($subdirectories.Count -eq 1 -and $subdirectories.Name -contains $BootFolder -and $files.Count -eq 0) {
        $dir.FullName
    }
}

# Output the list of filtered directories
Write-Log -Message "There are $(($DodgyTestDirectories | Measure-Object).Count) Directories to delete" -Level Info

# Delete the directory
foreach ($dir in $DodgyTestDirectories ) {
    
    if (-not $WhatifMode) {
        try {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
            Write-Log -Message "Directory $($dir) deleted." -Level Info
        }
        catch {
            Write-Log -Messagae $_ -Level Error
            Continue
        }
        
    } else {
        Write-Log -Message "WHATIF: Directory $($dir) would have been deleted." -Level Info
    }
}

StopIteration
Exit 0
#endregion