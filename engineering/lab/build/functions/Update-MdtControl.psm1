<#
.Synopsis
    Update the MDT Control File
.DESCRIPTION
    Update the MDT Control File
.EXAMPLE
    Update-MdtControl -Name "VM" -TaskSequenceID "WSRV-BASE" -VMMAC "12:23:34:45:56:67"
.INPUTS
    TaskSequenceID - The Task Sequence Name
    VMMAC - The VM MAC Address
    Name - The VM Name
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Update the MDT Control File
#>

function Update-MdtControl
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
        $Name,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $VMMAC,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $TaskSequenceID
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Update-MdtControl'" 
    }

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
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Update-MdtControl'" 
    }
}