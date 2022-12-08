function Update-MDTTaskSequence {
<#
    .SYNOPSIS
    Updates the MDT Task Sequence.

    .DESCRIPTION
    This function will update the MDT Task Sequence with the new OS to install.
    
    .PARAMETER TaskSequenceID
    The Nutanix Cluster IP

    .PARAMETER GUID
    The OS GUID to Install

    .EXAMPLE
    PS> Update-MdtTaskSequence -TaskSequenceID "WSRV-BASE" -Guid "{1-2-3-4-5-6-7-8}"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    None

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Update-MDTTaskSequence.md

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
        [system.string[]]$TaskSequenceID,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$Guid
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
        Write-Host (Get-Date)":Guid: $Guid" 

        # Update the Guid in the Task Sequence
        Write-Host (Get-Date) ":Reading Task Sequence - $TaskSequenceID"
        $TSPath = "/mnt/mdt/control/$($TaskSequenceID)/ts.xml"
        $TSXML = [xml](Get-Content $TSPath)
        $TSXML.sequence.globalVarList.variable | Where-Object {$_.name -eq "OSGUID"} | ForEach-Object {$_."#text" = $Guid}
        $TSXML.sequence.group | Where-Object {$_.Name -eq "Install"} | ForEach-Object {$_.step} | Where-Object {$_.Name -eq "Install Operating System"} | ForEach-Object {$_.defaultVarList.variable} | Where-Object {$_.name -eq "OSGUID"} | ForEach-Object {$_."#text" = $Guid}
        $TSXML.Save($TSPath)
        Write-Host (Get-Date) ":Updated Task Sequence - $TaskSequenceID with new OS GUID $Guid"
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # End

} # Update-MDTTaskSequence