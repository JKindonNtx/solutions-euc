<#
.Synopsis
    Update the MDT Task Sequence Product Key in the Unattend File
.DESCRIPTION
    Update the MDT Task Sequence Product Key in the Unattend File
.EXAMPLE
    Update-MdtTaskSequenceProductKey -TaskSequenceID "WSRV-BASE" -SearchString "SRV" -WinVerBuild "SRV"
.INPUTS
    TaskSequenceID - The Task Sequence to update
    SearchString - The OS Search String
    WinVerBuild - The windows version
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Update the MDT Task Sequence Product Key in the Unattend File
#>

function Update-MdtTaskSequenceProductKey
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                  PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [System.object[]]
        $JSON,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $SearchString,
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
        $TaskSequenceID
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Update-MdtTaskSequenceProductKey'" 
    }

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
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Update-MdtTaskSequenceProductKey'" 
    }
}