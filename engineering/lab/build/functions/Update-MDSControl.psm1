function Update-MDTControl {
<#
    .SYNOPSIS
    Updates the MDT Control File.

    .DESCRIPTION
    This function will update the MDT control file to allow for auto start of a Task Sequence.
    
    .PARAMETER TaskSequenceID
    The Nutanix Cluster IP

    .PARAMETER VMMAC
    The user name to use for connection

    .PARAMETER Name
    The password for the connection

    .EXAMPLE
    PS> Update-MDTControl -Name "VM" -TaskSequenceID "WSRV-BASE" -VMMAC "12:23:34:45:56:67"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    None

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Update-MDTControl.md

    .NOTES
    Author          Version         Date            Detail
    David Brett     v1.0.0          28/11/2022      Function creation
#>


    [CmdletBinding()]

    Param
    (
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$Name,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$VMMAC,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$TaskSequenceID
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":TaskSequenceID: $TaskSequenceID" 
        Write-Host (Get-Date)":Name: $Name" 
        Write-Host (Get-Date)":VMMAC: $VMMAC" 

        # Update the customsettings.ini file with the new VM Details to enable auto selection of the task sequence
        Write-Host (Get-Date)":Adding $Name to the MDT Control File" 
        Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "`r"
        Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "[$VMMAC]`r"
        Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "SkipWizard=YES`r"
        Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "TaskSequenceID=$TaskSequenceID`r"
        Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "ComputerName=$Name`r"
        Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "OSDComputerName=$Name`r"
        Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "SkipComputerName=YES`r"
        Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "SkipTaskSequence=YES`r"
        Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "SkipWizard=YES`r"
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # End

} # Update-MDTControl