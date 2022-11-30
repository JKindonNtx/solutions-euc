<#
.Synopsis
    Connect to MDT Server and gather Operating System GUID
.DESCRIPTION
    Connect to MDT Server and gather Operating System GUID
.EXAMPLE
    Get-MdtOSGuid -SearchString "SRV" -OSVersion "SRV"
.INPUTS
    WinVerBuild - The search string to filter the OS Versions
    OSversion - The OS Version to build from MDT
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Connect to MDT Server and gather Operating System GUID
#>

function Get-MdtOSGuid
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
        $WinVerBuild,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $OSversion
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Get-MdtOSGuid'" 
    }

    Process
    {
        # Display Functionå Parameters
        Write-Host (Get-Date)":WinVerBuild: $WinVerBuild" 
        Write-Host (Get-Date)":OSversion: $OSversion" 

        Write-Host (Get-Date) ":Getting available operating systems..."
        [xml]$OperatingSystems = Get-Content -path "/mnt/mdt/control/operatingsystems.xml"

        $MdtOSGuid = New-Object -TypeName psobject 

        # Search XML file for matching Operating System
        foreach($OperatingSystem in $OperatingSystems.oss.os){
            $OS = $OperatingSystem.Name
            if($OSversion -eq "SRV"){
                # Server based operating system
                if($OS -like "*$WinVerBuild*") {
                    if(($OS -like "*ServerDataCenter*") -and ($OS -notlike "*ServerDataCenterCore*")){
                        Write-Host (Get-Date) ":Operating System selected - $os."
                        $MdtOSGuid | Add-Member -MemberType NoteProperty -Name "Guid" -Value $OperatingSystem.guid
                        Write-Host (Get-Date) ":Operating system GUID - $($MdtOSGuid.Guid)"
                    }
                }
            } else {
                # Desktop based operating system
                if($OS -like "*$WinVerBuild*") {
                    if(($OS -like "*Enterprise*") -and ($OS -notlike "*Enterprise N*")){
                        Write-Host (Get-Date) ":Operating System selected - $os"
                        $MdtOSGuid | Add-Member -MemberType NoteProperty -Name "Guid" -Value $OperatingSystem.guid
                        Write-Host (Get-Date) ":Operating system GUID - $($MdtOSGuid.Guid)"
                    }
                }
            }
        }
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Get-MdtOSGuid'" 
        Return $MdtOSGuid
    }
}