function Remove-NutanixFilesData {
    <#
    .SYNOPSIS
    Clean Data from a list of shares (Delete)

    .DESCRIPTION
    Clean data after a test run from a list of Nutanix Files Shares

    .PARAMETER Shares
    A list of shares to delete data from

    .PARAMETER Mode
    Execute or Validate. Use Validate to confirm access to share. Use Execute to execute the deletion of the share

    .PARAMETER ContinueOnFail
    Defines if the script should exit if failure to delete data has occured. Defaults to True

    .PARAMETER DummyFolder
    The Folder to create as part of the Validation Mode. Defaults to a dummy folder called "Folder_To_Delete" which will be created and deteled to ensure permissions are OK.

    .EXAMPLE
    PS> Remove-NutanixFilesData -Shares ""\\Server1\Share1","\\Server2\Share2" -Mode Validate
    Will Validate that the Shares \\Server1\Share and \\Server2\Share are accessible by creating a dummy directory named Folder_To_Delete and then deleting the directory. Will Terminate on Failure without the ability to override.

    .EXAMPLE
    PS> Remove-NutanixFilesData -Shares ""\\Server1\Share1","\\Server2\Share2" -Mode Execute
    Will action the execution of data in \\Server1\Share and \\Server2\Share. Will continue on Failure

    .EXAMPLE
    PS> Remove-NutanixFilesData -Shares ""\\Server1\Share1","\\Server2\Share2" -Mode Execute -ContinueOnFailure $False
    Will action the execution of data in \\Server1\Share and \\Server2\Share. Will Terminate on Failure to Delete Data

#>
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][Array]$Shares,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][ValidateSet("Execute", "Validate")][String]$Mode,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][bool]$ContinueOnFail = $true,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $False)][String]$DummyFolder = "Folder_To_Delete"
    )

    # Process code for the function
    foreach ($Share in $Shares) {
        Write-Log -Message "Processing Share $($Share)" -Level Info
        if (Test-Path $Share -PathType Container) {
            Write-Log -Message "Sucessfully Connected to $($Share)" -Level Info
            try {
                $RootDirectoryData = Get-ChildItem -Path $Share -Directory -ErrorAction Stop
                Write-Log -Message "There are $(($RootDirectoryData | Measure-Object).Count) root directories to delete on $($Share)" -Level Info
            }
            catch {
                Write-Log $_ -Level Error
                Exit 1
            }

            if ($Mode -eq "Validate") {
                Write-Log -Message "Processing Share $($Share) in Validation Mode" -Level Info

                # Create Dummy Data
                try {
                    $null = New-Item -Path $Share -Name $DummyFolder -ItemType Directory -Force -ErrorAction Stop
                    Write-Log -Message "Created dummy directory $($DummyFolder) on $($Share). Sleeping for 10 seconds" -Level Info
                    Start-Sleep 10
                }
                catch {
                    Write-Log -Message "Failed to Create directory on $($Share)" -Level Error
                    Write-Log -Message $_ -Level Error
                    Exit 1
                }

                # Delete Dummy Data
                try {
                    Remove-Item -Path (Join-Path $Share -ChildPath $DummyFolder) -Recurse -Force -ErrorAction Stop
                    Write-Log -Message "Deleted dummy directory $($DummyFolder) on $($Share)" -Level Info
                    Write-Log -Message "Validated $($Share) Successfully" -Level Info
                }
                catch {
                    Write-Log -Message "Failed to delete directory $($DummyFolder) on $($Share). Trying again in 10 seconds" -Level Warn
                    Write-Log -Message $_ -Level Warn
                    Start-Sleep 10
                    try {
                        Remove-Item -Path (Join-Path $Share -ChildPath $DummyFolder) -Recurse -Force -ErrorAction Stop
                        Write-Log -Message "Deleted dummy directory $($DummyFolder) on $($Share)" -Level Info
                    }
                    catch {
                        Write-Log -Message "Failed to delete Directory $($DummyFolder) on $($Share)." -Level Error
                        Write-Log -Message $_ -Level Error
                        Exit 1
                    }
                }

            }

            if ($Mode -eq "Execute") {
                Write-Log -Message "Processing Share $($Share) in Execute Mode" -Level Info
                Write-Log -Message "Deleting contents of $($Share)" -Level Info
                try {
                    Remove-Item -Path $Share\* -Recurse -Force -ErrorAction Stop
                    $RootDirectoryData = Get-ChildItem -Path $Share -Directory -ErrorAction Stop
                    Write-Log -Message "There are now $(($RootDirectoryData | Measure-Object).Count) Root Directories on $($Share)" -Level Info
                }
                catch {
                    Write-Log -Message "Failed to Delete Contents of $($Share)" -Level Error
                    Write-Log -Message $_ -Level Error
                    if ($ContinueOnFail) {
                        Write-Log -Message "Continue on Failure is present. Proceeding without confirmed deletion of Nutanix Files Data" -Level Warn
                    }
                    else {
                        Write-Log -Message "Continue on Failure is not present. Exiting Script" -Level 
                        Exit 1
                    }
                }
            }
        }
        else {
            if ($Mode -eq "Execute" -and $ContinueOnFail) {
                Write-Log -Message "Share $($Share) does not exist. Please check configuration." -Level Warn
                Write-Log -Message "Continue on Failure is present. Proceeding without confirmed deletion of Nutanix Files Data" -Level Warn
            }
            else {
                Write-Log -Message "Share $($Share) does not exist. Please check configuration. Exiting Script" -Level Error
                Exit 1
            }
        }
    }

}
