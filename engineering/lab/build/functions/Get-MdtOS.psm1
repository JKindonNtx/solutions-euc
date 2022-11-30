<#
.Synopsis
    Connect to MDT Server and gether Operating Systems
.DESCRIPTION
    Connect to MDT Server and gether Operating Systems
.EXAMPLE
    Get-MdtOS -SearchString "SRV" -OSVersion "SRV"
.INPUTS
    SearchString - The search string to filter the OS Versions
    OSversion - The OS Version to build from MDT
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Connect to MDT Server and gether Operating Systems
#>

function Get-MdtOS
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
        $SearchString,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $OSversion
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Get-MdtOS'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":SearchString: $SearchString" 
        Write-Host (Get-Date)":OSversion: $OSversion" 

        Write-Host (Get-Date)":Gathering available Operating Systems" 
        $Folders = get-childitem -path "/mnt/mdt/Operating Systems"

        $MdtOSDetails = New-Object -TypeName psobject 

        $i = 1 
        $Builds = @() 
        foreach ($Folder in $Folders){
            if($folder.Name -like "*$SearchString*"){
                $OSDislpay = $folder.name
                Write-Host "$i = $OSDislpay"
                $Builds += $OSDislpay
                $i++
            }
        }

        # Ask for the specific build of Windows to install
        $n = Read-Host "Select a version (Last 4 digits represents the installed updates: YYMM)"

        # Get the Windows version selected out of the array and into a variable
        $WinVerBuild = $Builds[$n-1]

        # Generate a random 4 digit ID
        $VMId = (New-Guid).Guid.SubString(1,4)

        # Generate the new VM name from the folder name selected minus the patch version and the new random 4 digit ID
        $VName = $WinVerBuild.Substring(0,$WinVerBuild.Length-5) 
        $Name = "$VName-$VMId"

        # Set the task sequence ID to the Build Version Selected Earlier
        $TaskSequenceID = "W$OSversion-BASE"

        # Build the object to return
        $MdtOSDetails | Add-Member -MemberType NoteProperty -Name "WinVerBuild" -Value $WinVerBuild
        $MdtOSDetails | Add-Member -MemberType NoteProperty -Name "VMId" -Value $VMId
        $MdtOSDetails | Add-Member -MemberType NoteProperty -Name "VName" -Value $VName
        $MdtOSDetails | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $MdtOSDetails | Add-Member -MemberType NoteProperty -Name "TaskSequenceID" -Value $TaskSequenceID

    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Get-MdtOS'" 
        Return $MdtOSDetails
    }
}