function Get-MdtOSLatest {
<#
    .SYNOPSIS
    Connect to MDT Server and gather Operating Systems.

    .DESCRIPTION
    This function will connect to a MDT server and obtain a list of all the operating systems available using the directories in the OS folder of the MDT share.
    
    .PARAMETER SearchString
    The search string to filter the OS Versions

    .PARAMETER OSversion
    The OS version to use for the MDT build

    .EXAMPLE
    PS> Get-MdtOS -SearchString "SRV" -OSVersion "SRV"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    PSCustomObject containing the details of the Operating Systems available

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Get-MdtOS.md

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
        [system.string[]]$SearchString,

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
        Write-Host (Get-Date)":SearchString: $SearchString" 
        Write-Host (Get-Date)":OSversion: $OSversion" 

        # Get available operating systems from MDT Server
        Write-Host (Get-Date)":Gathering available Operating Systems" 
        $Folders = get-childitem -path "/mnt/mdt/Operating Systems"

        # Create empty Custom PS Object
        $MdtOSDetails = New-Object -TypeName psobject 

        # Loop through folders and check SearchString
        # If applicable add to OSArray
        $i = 1 
        $Builds = @() 
        foreach ($Folder in $Folders){
            if($folder.Name -like "*$SearchString*"){
                $OSDislpay = $folder.name
                #Write-Host "$i = $OSDislpay"
                $Builds += $OSDislpay
                $i++
            }
        }

        # Ask for the specific build of Windows to install
        #$n = Read-Host "Select a version (Last 4 digits represents the installed updates: YYMM)"

        # Get the Windows version selected out of the array and into a variable
        $WinVerBuild = $Builds[$i-2]

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

    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $MdtOSDetails
    } # End

} # Get-MdtOS