function Get-MdtOSGuid {
<#
    .SYNOPSIS
    Connect to MDT Server and gather Operating System GUID.

    .DESCRIPTION
    This function will connect to a MDT server and obtain a list of all the operating systems available using OperatingSystems.xml file. It will then search for the selected Operating System GUID and return this.
    
    .PARAMETER WinVerBuild
    The search string for the specific windows version

    .PARAMETER OSversion
    The OS version to use for the MDT build

    .EXAMPLE
    PS> Get-MdtOSGuid -WinVerBuild "2210" -OSVersion "SRV"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    PSCustomObject containing the details of the Operating System GUID

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Get-MdtOSGuid.md

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
        [system.string[]]$WinVerBuild,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$OSversion
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":WinVerBuild: $WinVerBuild" 
        Write-Host (Get-Date)":OSversion: $OSversion" 

        # Gather a list of the available Operating Systems
        Write-Host (Get-Date) ":Getting available operating systems..."
        [xml]$OperatingSystems = Get-Content -path "/mnt/mdt/control/operatingsystems.xml"

        # Build new custom PSObject
        $MdtOSGuid = New-Object -TypeName psobject 

        # Search XML file for matching Operating System
        # Update the PSCustomObject with the OS GUID
        foreach($OperatingSystem in $OperatingSystems.oss.os){
            $OS = $OperatingSystem.Name
            if($OSversion -eq "SRV"){
                # Server based operating system
                if($OS -like "*$WinVerBuild*") {
                    if(($OS -like "*ServerDataCenter*") -and ($OS -notlike "*ServerDataCenterCore*")){
                        Write-Host (Get-Date) ":Operating System selected - $OS."
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
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $MdtOSGuid
    } # End

} # Get-MdtOSGuid