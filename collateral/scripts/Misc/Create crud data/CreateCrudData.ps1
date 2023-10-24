
<#
.SYNOPSIS
    Creates crud data in the users profile to allow for container compaction testing
.DESCRIPTION
    Creates crud data in the users profile to allow for container compaction testing
.PARAMETER LogPath
    Path for log output. Defaults to C:\Logs\CrudDataCreation.log
.PARAMETER LogRollover
    Number of days before logfiles are rolled over. Default is 5
.PARAMETER CrudPath
    Path to create crud data. default is C:\Users\%Username%\AppData\Roaming\CrudData
.PARAMETER Mode
    Create or Delete mode. Cannot be used with AutoCreateAndClean
.PARAMETER AutoCreateAndClean
    Automatically creates, sleeps, and deletes data. cannot be used with Mode parameter
.PARAMETER AutoCreateAndCleanRestTime
    Amount of time to sleep between creation and deletion in AutoCreateAndClean mode. Defaults to 20 seconds
.PARAMETER FileSetSizeinGb
    Predefined amount of data to create. Offers 5, 10, 15, 30 or 45 Gb options. Defaults to 15Gb.
.PARAMETER IsContainer
    For FSLogix Containers, creates a basic file copy of a file (System.IO.FileStream doesn't appear to grow the container)
.EXAMPLE
    .\CreateCrudData.ps1 -Mode Create
    Will create data in C:\Users\%Username%\AppData\Roaming\CrudData
.EXAMPLE
    .\CreateCrudData.ps1 -Mode Create -CrudPath "MoreCrudThanCrud"
    Will create data in C:\Users\%Username%\AppData\Roaming\MoreCrudThanCrud
.EXAMPLE
    .\CreateCrudData.ps1 -Mode Delete
    Will delete data in C:\Users\%Username%\AppData\Roaming\CrudData
.EXAMPLE
    .\CreateCrudData.ps1 -Mode Delete -CrudPath "MoreCrudThanCrud"
    Will delete data in C:\Users\%Username%\AppData\Roaming\MoreCrudThanCrud
.EXAMPLE
    .\CreateCrudData.ps1 -AutoCreateAndClean
    Will create and delete data in C:\Users\%Username%\AppData\Roaming\CrudData, wait the default 20 seconds between creation and deletion and use the default 15 GiB file set
.EXAMPLE
    .\CreateCrudData.ps1 -AutoCreateAndClean -AutoCreateAndCleanRestTime 30
    Will create and delete data in C:\Users\%Username%\AppData\Roaming\CrudData, wait 30 seconds between creation and deletion and use the default 15 GiB file set
.EXAMPLE
    .\CreateCrudData.ps1 -AutoCreateAndClean -FileSetSizeinGb 30 -CrudPath "MoreCrudThanCrud"
    Will create and delete data in C:\Users\%Username%\AppData\Roaming\MoreCrudThanCrud, wait default 20 seconds between creation and deletion and use the default 30 GiB file set
.EXAMPLE
    .\CreateCrudData.ps1 -AutoCreateAndClean -FileSetSizeinGb 30 -CrudPath "MoreCrudThanCrud" -IsContainerData
    Will create and delete data in C:\Users\%Username%\AppData\Roaming\MoreCrudThanCrud, wait default 20 seconds between creation and deletion and use the default 30 GiB file set. This will use a file copy approach based on the default "C:\Windows\System32\WindowsCodecsRaw.dll" File
.NOTES 
    Author: James Kindon, Nutanix
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\CrudDataCreation.log", 

    [Parameter(Mandatory = $false)]
    [int]$LogRollover = 5, # number of days before logfile rollover occurs
    
    [Parameter(Mandatory = $false)]
    [string]$CrudPath = "CrudData",

    [Parameter(Mandatory = $false, ParameterSetName = "CreateDeleteSelection")]
    [ValidateSet("Create","Delete")]
    [String]$Mode,

    [Parameter(Mandatory = $false, ParameterSetName = "CreateDeleteAuto")]
    [Switch]$AutoCreateAndClean,

    [Parameter(Mandatory = $false, ParameterSetName = "CreateDeleteAuto")]
    [int]$AutoCreateAndCleanRestTime = 20,

    [Parameter(Mandatory = $false)]
    [ValidateSet(5,10,15,30,45)]
    [int]$FileSetSizeinGb = 15,

    [Parameter(Mandatory = $false, ParameterSetName = "CreateDeleteSelection")]
    [Parameter(ParameterSetName = "CreateDeleteAuto")]
    [Switch]$IsContainerData

)
#endregion

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

function Convert-SizeToBytes {
    param (
        [string]$size
    )

    $size = $size -replace "(?i)[^\d.mgk]", ""

    if ($size -match '(\d+(\.\d+)?)\s*(k|kb|m|mb|g|gb)$') {
        $numericPart = [double]::Parse($matches[1])
        $unit = $matches[3].ToLower()

        if ($unit -eq 'k' -or $unit -eq 'kb') {
            $sizeInBytes = $numericPart * 1KB
        }
        elseif ($unit -eq 'm' -or $unit -eq 'mb') {
            $sizeInBytes = $numericPart * 1MB
        }
        elseif ($unit -eq 'g' -or $unit -eq 'gb') {
            $sizeInBytes = $numericPart * 1GB
        }
        else {
            $sizeInBytes = $numericPart
        }

        return [int64]$sizeInBytes
    }

    throw "Invalid size format"
}

function CreateCrudData {
    Write-Log -Message "Creating crud data in $($FilePath)" -Level Info
    if (!(Test-Path $FilePath)) {
        New-Item -Path $FilePath -ItemType Directory | Out-Null
    }

    if ($IsContainerData) {
        # Loop to create copies of the source file
        for ($i = 1; $i -le $fileCopyCount; $i++) {
            $destinationFile = Join-Path $filepath ("file$i.txt")
            Copy-Item -Path $sourceFile -Destination $destinationFile
        }
    }
    else {
        try {
            foreach ($_ in $FilesToCreate.keys) {
                $FileName = $_
                $FileSize = $FilesToCreate[$_]
                $FileCreatePath = $FilePath + "\" + $FileName
                $file = New-Object System.IO.FileStream $FileCreatePath, Create, ReadWrite -ErrorAction Stop
            
                if ($PSVersionTable.PSVersion.Major -lt 7) {
                    # Do this is powershell 5, need to convert to bytes first
                    $fileSizeInBytes = Convert-SizeToBytes -size $fileSize
                    $file.SetLength($fileSizeInBytes)
                }
                else {
                    $file.SetLength($FileSize)
                }
                $file.Close()
            }

            try {
                Write-Log -Message "Getting folder statistics for: $($FilePath)" -Level Info
                $FolderSize = (Get-ChildItem $FilePath -ErrorAction Stop | Measure-Object -Property Length -sum).sum / 1Gb
                Write-Log -Message "Created $($FolderSize)Gb in: $($FilePath)" -Level Info
            }
            catch {
                Write-Log -Message "Failed to get Folder size for: $($FilePath)" -Level Warn
                Write-Log -Message $_ -Level Warn
            }

            Write-Log -Message "Successfully created crud data in: $($FilePath)" -Level Info
        }
        catch {
            Write-Log -Message "Failed to create crud data from: $($FilePath)" -Level Warn
            Write-Log -Message $_ -Level Warn
        }
    }
}

function DeleteCrudData {
    Write-Log -Message "Deleting crud data in: $($FilePath)" -Level Info
    if (Test-Path $FilePath) {
        # get folder statistics
        try {
            Write-Log -Message "Getting folder statistics for: $($FilePath)" -Level Info
            $FolderSize = (Get-ChildItem $FilePath -ErrorAction Stop | Measure-Object -Property Length -sum).sum / 1Gb
            Write-Log -Message "Data size to delete is: $($FolderSize)Gb"
        }
        catch {
            Write-Log -Message "Failed to get Folder size for: $($FilePath)" -Level Warn
            Write-Log -Message $_ -Level Warn
        }
        # delete data
        try {
            Remove-Item -Path $FilePath -recurse -Force -ErrorAction Stop
            Write-Log -Message "Successfully deleted crud data from: $($FilePath)" -Level Info
        }
        catch {
            Write-Log -Message "Failed to delete crud data from: $($FilePath)" -Level Warn
            Write-Log -Message $_ -Level Warn
        }
    }
    else {
        Write-Log -Message "Failed to find $($FilePath)" -level Info
    }
}
#endregion

#region Variables
# ============================================================================
# Variables
# ============================================================================
$FilePath = $env:APPDATA + "\" + $CrudPath
$SourceFile = "C:\Windows\System32\WindowsCodecsRaw.dll"

# 5GiB iteration
$FilesToCreate5 = @{
    "Crud1" = "1Gb"
    "Crud2" = "500Mb"
    "Crud3" = "500Mb"
    "Crud4" = "900Mb"
    "Crud5" = "100Mb"
    "Crud6" = "2Gb"
}
# 10GiB iteration
$FilesToCreate10 = @{
    "Crud1" = "1Gb"
    "Crud2" = "500Mb"
    "Crud3" = "500Mb"
    "Crud4" = "900Mb"
    "Crud5" = "100Mb"
    "Crud6" = "2Gb"
    "Crud7" = "1Gb"
    "Crud8" = "500Mb"
    "Crud9" = "500Mb"
    "Crud10" = "900Mb"
    "Crud11" = "100Mb"
    "Crud12" = "2Gb"
}
# 15GiB iteration
$FilesToCreate15 = @{
    "Crud1" = "1kb"
    "Crud2" = "1Mb"
    "Crud3" = "1Gb"
    "Crud4" = "5Gb"
    "Crud5" = "10Mb"
    "Crud6" = "100Mb"
    "Crud7" = "50Mb"
    "Crud8" = "500Mb"
    "Crud9" = "900Mb"
    "Crud10" = "1Gb"
    "Crud11" = "2Gb"
    "Crud12" = "1Gb"
    "Crud13" = "4Gb"
}
# 30GiB iteration
$FilesToCreate30 = @{
    "Crud1" = "1kb"
    "Crud2" = "1Mb"
    "Crud3" = "1Gb"
    "Crud4" = "5Gb"
    "Crud5" = "10Mb"
    "Crud6" = "100Mb"
    "Crud7" = "50Mb"
    "Crud8" = "500Mb"
    "Crud9" = "900Mb"
    "Crud10" = "1Gb"
    "Crud11" = "2Gb"
    "Crud12" = "1Gb"
    "Crud13" = "4Gb"
    "Crud14" = "1kb"
    "Crud15" = "1Mb"
    "Crud16" = "1Gb"
    "Crud17" = "5Gb"
    "Crud18" = "10Mb"
    "Crud19" = "100Mb"
    "Crud20" = "50Mb"
    "Crud21" = "500Mb"
    "Crud22" = "900Mb"
    "Crud23" = "1Gb"
    "Crud24" = "2Gb"
    "Crud25" = "1Gb"
    "Crud26" = "4Gb"
}
# 45GiB iteration
$FilesToCreate45 = @{
    "Crud1" = "1kb"
    "Crud2" = "1Mb"
    "Crud3" = "1Gb"
    "Crud4" = "5Gb"
    "Crud5" = "10Mb"
    "Crud6" = "100Mb"
    "Crud7" = "50Mb"
    "Crud8" = "500Mb"
    "Crud9" = "900Mb"
    "Crud10" = "1Gb"
    "Crud11" = "2Gb"
    "Crud12" = "1Gb"
    "Crud13" = "4Gb"
    "Crud14" = "1kb"
    "Crud15" = "1Mb"
    "Crud16" = "1Gb"
    "Crud17" = "5Gb"
    "Crud18" = "10Mb"
    "Crud19" = "100Mb"
    "Crud20" = "50Mb"
    "Crud21" = "500Mb"
    "Crud22" = "900Mb"
    "Crud23" = "1Gb"
    "Crud24" = "2Gb"
    "Crud25" = "1Gb"
    "Crud26" = "4Gb"
    "Crud27" = "1kb"
    "Crud28" = "1Mb"
    "Crud29" = "1Gb"
    "Crud30" = "5Gb"
    "Crud31" = "10Mb"
    "Crud32" = "100Mb"
    "Crud33" = "50Mb"
    "Crud34" = "500Mb"
    "Crud35" = "900Mb"
    "Crud36" = "1Gb"
    "Crud37" = "2Gb"
    "Crud38" = "1Gb"
    "Crud39" = "4Gb"
}
#endregion

#region Execute
# ============================================================================
# Execute
# ============================================================================

#Set the File Set Size
Write-Log -Message "File set size selected is $($FileSetSizeinGb)Gb" -Level Info
switch ($FileSetSizeinGb) {
    5 { $FilesToCreate = $FilesToCreate5 }
    10 { $FilesToCreate = $FilesToCreate10 }
    15 { $FilesToCreate = $FilesToCreate15 }
    30 { $FilesToCreate = $FilesToCreate30 }
    45 { $FilesToCreate = $FilesToCreate45 }
}

if ($Mode -ne "Create" -or $Mode -ne "Delete" -and $AutoCreateAndClean -eq "false") {
    Write-Log -Message "You must specify an operational mode. Either Create or Delete" -Level Info
    Exit 1
}

if ($IsContainerData) {
    if (Test-Path $sourceFile -PathType Leaf) {
        $SourceFileSize = (Get-Item -Path $sourceFile).Length
     
        $DataSetInBytes =  1073741824 * $FileSetSizeinGb # convert to bytes
        $FileCopyCount = $DataSetInBytes / $SourceFileSize
        $FileCopyCount = [System.Math]::Ceiling($FileCopyCount)

        Write-Log -Message "Will copy $($FileCopyCount) iterations of $sourceFile" -level Info
    }
    else {
        Write-Log -Message "Source File: $($sourceFile) does not exist. Cannot copy" -Level Warn
        Exit 1
    }
}

if ($Mode -eq "Create") {
    Write-Log -Message "Script operating in Create mode" -Level Info
    CreateCrudData
}
elseif ($Mode -eq "Delete") {
    Write-Log -Message "Script operating in Delete mode" -Level Info
    DeleteCrudData
}

if ($AutoCreateAndClean.IsPresent) {
    Write-Log -Message "AutoCreateAndClean mode is enabled. Handling creation and deletion of crud data in $($FilePath)" -Level Info
    CreateCrudData
    Write-Log -Message "Sleeping for $($AutoCreateAndCleanRestTime) seconds before deleting crud data" -Level Info
    Start-Sleep $AutoCreateAndCleanRestTime
    DeleteCrudData
}

Exit 0
#endregion







