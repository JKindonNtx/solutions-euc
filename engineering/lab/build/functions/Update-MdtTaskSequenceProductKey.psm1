function Update-MdtTaskSequenceProductKey {
<#
    .SYNOPSIS
    Update the MDT Task Sequence Product Key in the Unattend File.

    .DESCRIPTION
    This function will update the MDT Task Sequence Product Key in the Unattend File for Server Builds as this is a required step to have a zero touch install.
    
    .PARAMETER JSON
    The Lab Details JSON File

    .PARAMETER TaskSequenceID
    The Nutanix Cluster IP

    .PARAMETER SearchString
    The OS Search String

    .PARAMETER WinVerBuild
    The windows version

    .EXAMPLE
    PS> Update-MdtTaskSequenceProductKey -JSON $JSON -TaskSequenceID "WSRV-BASE" -SearchString "SRV" -WinVerBuild "SRV"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    None

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Update-MDTTaskSequenceProductKey.md

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
        [System.object[]]$JSON,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$SearchString,

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
        Write-Host (Get-Date)":SearchString: $SearchString" 
        Write-Host (Get-Date)":WinVerBuild: $WinVerBuild" 

        # Read the OS Product key and update if required
        Write-Host (Get-Date) ":Reading Unattended Setup File"
        if($SearchString -eq "SRV"){
            if($WinVerBuild -like "SRV-2019*"){
                $PK = "$($JSON.ProductKeys.2019)"
            } else {
                $PK = "$($JSON.ProductKeys.2022)"
            }
            $USPath = "/mnt/mdt/control/$($TaskSequenceID)/Unattend.xml"
            $USXML = [xml](Get-Content $USPath)
            $PassSettings = $USXML.unattend.settings.component | Where-Object {$_.name -eq "Microsoft-Windows-Shell-Setup"}
            foreach($Pass in $PassSettings){
                if($null -ne $Pass.ProductKey){ $pass.ProductKey = $PK } 
            }
            $USXML.Save($USPath)
            Write-Host (Get-Date) ":Updated Product Key to $PK"
        } else {
            Write-Host (Get-Date) ":Skipping Unattended Setup File - Desktop OS"
        }
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # End

} # Update-MDTTaskSequenceProductKey