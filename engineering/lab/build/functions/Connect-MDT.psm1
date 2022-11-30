<#
.Synopsis
    Connect to MDT Server
.DESCRIPTION
    This function will create a local mount point then mount a connection to a Microsoft Deployment Server
.EXAMPLE
    Connect-MDT -Username "User" -Password "passw0rd1!" -Domain "domain" -MdtServerIP "10.11.12.13" -ShareName "MDT$" -Directory "mdt"
.INPUTS
    Username - The user name to mount the drive as
    Password - The password for the user
    Domain - The domain for the user account
    MdtServerIP - The IP address of the MDT server
    ShareName - The share name to map to
    Directory - The local directory to use as the mount point
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    This is used to create a connection between a container and a MDT server in order to manipulate source files on teh remote server
#>

function Connect-MDT
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
        $UserName,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $Password,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $Domain,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $MdtServerIP,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $ShareName,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $Directory
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Connect-MDT'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":Username: $UserName" 
        Write-Host (Get-Date)":Password: <Not Displayed>" 
        Write-Host (Get-Date)":Domain: $Domain" 
        Write-Host (Get-Date)":MDT Server IP: $MdtServerIP" 
        Write-Host (Get-Date)":Share Name: $ShareName" 
        Write-Host (Get-Date)":Directory: $Directory" 

        # Build Commands and Map Drive to MDT Server
        $Command = "sudo"
        $LocalPath = "/mnt/mdt"
        if(Test-Path -Path $LocalPath){
            Write-Host (Get-Date)":Directory $LocalPath exists" 
        } else {
            Write-Host (Get-Date)":Directory $LocalPath does not exist - creating" 
            $Arguments = " mkdir /mnt/mdt"
            Start-Process -filepath $Command -argumentlist $Arguments -passthru -wait
            $Arguments = " chmod 777 " + $LocalPath
            Write-Host (Get-Date)":Settings rights on $LocalPath" 
            Start-Process -filepath $Command -argumentlist $Arguments -passthru -wait
            $Arguments = "mount -t cifs -o rw,file_mode=0117,dir_mode=0177,username=" + $UserName + ",password=" + $Password + ",domain=" + $Domain + " //" + $MDTServerIP + "/" + $ShareName + " " + $LocalPath
            Write-Host (Get-Date)":Mounting drive to $LocalPath" 
            Start-Process -filepath $Command -argumentlist $Arguments -wait
        }
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Connect-MDT'" 

        # Validate Drive Mapped ok and return True or False
        $Mounted = $LocalPath + "/Control"
        if(Test-Path -Path $Mounted){ return $true } else { return $False }
    }
}