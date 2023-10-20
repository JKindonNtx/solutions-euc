#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\CrudDataCreation.log",

    [Parameter(Mandatory = $false)]
    [string]$SourceFile = "\\ws-files\Automation\Apps\Citrix\ISO\Citrix_Virtual_Apps_and_Desktops_7_2303.iso", # File to Copy

    [Parameter(Mandatory = $false)]
    [int]$Interval = 1200 #interval in seconds. Default is 20 mins

)
#endregion

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
        Write-Log -Message "File Copy took $($StopWatch.Elapsed.TotalMilliseconds) ms to complete." -Level Info
    }
    else {
        Write-Log -Message "File Copy took $($StopWatch.Elapsed.TotalSeconds) seconds to complete." -Level Info
    }
}

$CrudPath = "CrudData"
$FilePath = $env:APPDATA + "\" + $CrudPath
$FileCreatePath = $FilePath + "\" + (Split-Path $SourceFile -Leaf)

if (!(Test-Path $FilePath)) {
    New-Item -Path $FilePath -ItemType Directory | Out-Null
}

# Generate a random sleep interval between 0 and 1200 seconds (20 minutes).
Write-Log -Message "Generating Random Sleep Interval based on input: $($Interval)" -Level Info
$randomInterval = Get-Random -Minimum 0 -Maximum $Interval
# Convert the seconds to a TimeSpan.
$sleepTime = [TimeSpan]::FromSeconds($randomInterval)
Write-Log -Message "File copy will start in $($sleepTime.TotalSeconds) seconds" -Level Info
# Sleep for the generated time interval.
Start-Sleep -Seconds $sleepTime.TotalSeconds

# Copy Data
if (Test-Path $SourceFile) {
    try { 
        Start-Stopwatch
        Write-Log -Message "Copying File $($SourceFile) to target $($FilePath)" -Level Info
        Copy-Item -Path $SourceFile -Destination $FileCreatePath -Force
        Stop-Stopwatch
        Write-Log -Message "Sleeping for 5 seconds" -Level Info
        Start-Sleep 5
        Write-Log -Message "Deleting Directory $($FilePath)" -Level Info
        Remove-Item -Path $FilePath -Force -Recurse
        Write-Log -Message "Deleted Directory $($FilePath)" -Level Info
    }
    catch {
        Write-Log -Message $_ -Level Warn
    }
}

Exit 0
