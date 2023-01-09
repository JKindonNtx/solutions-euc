function Restore-MDTControl {
<#
    .SYNOPSIS
    Restores the MDT Control File.

    .DESCRIPTION
    This function will restore the MDT control file back to the original.

    .PARAMETER ControlFile
    The variable holding the MDT Control File

    .EXAMPLE
    PS> Restore-MDTControl -ControlFile $MDTControlOriginal

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    None

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Restore-MDTControl.md

    .NOTES
    Author          Version         Date            Detail
    David Brett     v1.0.0          06/01/2023      Function creation
#>


    [CmdletBinding()]

    Param
    (
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$ControlFile
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {

        # Get the customsettings.ini file into a variable
        Write-Host (Get-Date)":Restoring the MDT Control File" 
        $Task = $ControlFile | Out-File "/mnt/mdt/control/CustomSettings.ini"

    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # End

} # Restore-MDTControl