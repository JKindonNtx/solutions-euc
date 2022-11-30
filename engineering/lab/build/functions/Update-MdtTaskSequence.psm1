<#
.Synopsis
    Update the MDT Task Sequence with the new OS GUID
.DESCRIPTION
    Update the MDT Task Sequence with the new OS GUID
.EXAMPLE
    Update-MdtTaskSequence -TaskSequenceID "WSRV-BASE" -Guid "{1-2-3-4-5-6-7-8}"
.INPUTS
    TaskSequenceID - The Task Sequence to update
    Guid - The OS Guid
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Update the MDT Task Sequence with the new OS GUID
#>

function Update-MdtTaskSequence
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                  PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $TaskSequenceID,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $Guid
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Update-MdtTaskSequence'" 
    }

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
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Update-MdtTaskSequence'" 
    }
}