function Connect-MDT {
<#
    .SYNOPSIS
    Connects to MDT Server.

    .DESCRIPTION
    This function will create a local mount point then mount a connection to a Microsoft Deployment Server.
    
    .PARAMETER Username
    The user name to mount the drive as

    .PARAMETER Password
    The password for the user

    .PARAMETER Domain
    The Domain for the user account

    .PARAMETER MdtServerIP
    The IP Address for the MDT Server

    .PARAMETER ShareName
    The share name on the MDT Server to map to

    .EXAMPLE
    PS> Connect-MDT -Username "User" -Password "passw0rd1!" -Domain "domain" -MdtServerIP "10.11.12.13" -ShareName "MDT$"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    Boolean value containing $true or $false based on the outcome of the mount

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Connect-MDT.md

    .NOTES
    Author          Version         Date            Detail
    David Brett     v1.0.0          28/11/2022      Function creation
    David Brett     v1.0.1          06/12/2022      Updated Parameter definition and added Alias' for UserName and Password
                                                    Updated function header to include MD help file
                                                    Updated Start-Process to pipe to $null
                                                    Changed Write-Host from hardcoded function name to $($PSCmdlet.MyInvocation.MyCommand.Name)

#>


    [CmdletBinding()]

    Param (
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [Alias('User')]
        [System.String[]]$UserName,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [Alias('Pass')]
        [System.String[]]$Password,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [System.String[]]$Domain,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [System.String[]]$MdtServerIP,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [System.String[]]$ShareName
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":Username: $UserName" 
        Write-Host (Get-Date)":Domain: $Domain" 
        Write-Host (Get-Date)":MDT Server IP: $MdtServerIP" 
        Write-Host (Get-Date)":Share Name: $ShareName" 

        # Build Commands and Map Drive to MDT Server
        $Command = "sudo"
        $LocalPath = "/mnt/mdt"

        # Test for the local directory
        if(Test-Path -Path $LocalPath){
            # Path exists
            Write-Host (Get-Date)":Directory $LocalPath exists" 
        } else {
            # Path does not exist create local directory
            Write-Host (Get-Date)":Directory $LocalPath does not exist - creating" 
            $Arguments = " mkdir /mnt/mdt"
            $null = Start-Process -filepath $Command -argumentlist $Arguments -passthru -wait

            # Change rights on local path to enable mapping
            $Arguments = " chmod 777 " + $LocalPath
            Write-Host (Get-Date)":Settings rights on $LocalPath" 
            $null = Start-Process -filepath $Command -argumentlist $Arguments -passthru -wait

            # Mount MDT server to new local path
            $Arguments = "mount -t cifs -o rw,file_mode=0117,dir_mode=0177,username=" + $UserName + ",password=" + $Password + ",domain=" + $Domain + " //" + $MDTServerIP + "/" + $ShareName + " " + $LocalPath
            Write-Host (Get-Date)":Mounting drive to $LocalPath" 
            $null = Start-Process -filepath $Command -argumentlist $Arguments -wait
        }
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 

        # Validate Drive Mapped ok and return True or False
        $Mounted = $LocalPath + "/Control"
        if(Test-Path -Path $Mounted){ 
            return $true 
        } else { 
            return $False 
        }
    } # End

} # Function Connect-MDT