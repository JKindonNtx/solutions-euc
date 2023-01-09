function Backup-MDTControl {
<#
    .SYNOPSIS
    Backs Up the MDT Control File.

    .DESCRIPTION
    This function will backup the MDT control file to allow for restore once the task sequence is complete.

    .EXAMPLE
    PS> Backup-MDTControl

    .INPUTS
    None

    .OUTPUTS
    The MDT Control File as an Object

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Backup-MDTControl.md

    .NOTES
    Author          Version         Date            Detail
    David Brett     v1.0.0          06/01/2023      Function creation
#>


    [CmdletBinding()]

    Param
    (
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Display Function Parameters

        # Get the customsettings.ini file into a variable
        Write-Host (Get-Date)":Reading the MDT Control File" 
        $MDTControlOriginal = Get-Content -Path "/mnt/mdt/control/CustomSettings.ini" -Raw
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $MDTControlOriginal
    } # End

} # Backup-MDTControl