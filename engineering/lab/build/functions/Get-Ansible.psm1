<#
.Synopsis
    Gather a list of available Ansible Playbooks
.DESCRIPTION
    Gather a list of available Ansible Playbooks
.EXAMPLE
    Get-Ansible -SearchString "SRV" -OSVersion "SRV"
.INPUTS
    SearchString - The search string to filter the OS Versions
    AnsiblePath - The path to the Ansible Playbooks
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Gather a list of available Ansible Playbooks
#>

function Get-Ansible
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
        $AnsiblePath
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Get-Ansible'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":SearchString: $SearchString" 
        Write-Host (Get-Date)":AnsiblePath: $AnsiblePath" 

        Write-Host (Get-Date)":Gathering available Ansible Playbooks" 
        $PlaybookPath = $AnsiblePath + "*.yml"
        $PlaybooksAvailable = get-childitem -Path $PlaybookPath

        $AnsibleDetails = New-Object -TypeName psobject 

        # Loop through the Playbooks and display only those relevant to the operating system selected
        $i = 1 
        $Playbooks = @() 
        foreach ($Playbook in $PlaybooksAvailable){
            $PlaybookName = $Playbook.name
            if(($SearchString -eq "SRV") -and ($PlaybookName -like "server_*")){
                Write-Host $i " = " $PlaybookName.substring(7)
                $Playbooks += $PlaybookName
                $i++
            } elseif (($SearchString -like "W*") -and ($PlaybookName -like "workstation_*")) {
                Write-Host $i " = " $PlaybookName.substring(12)
                $Playbooks += $PlaybookName
                $i++
            }
        }

        # Ask for the specific playbook to run
        $p = Read-Host "Select a playbook you would like to run post OS install"

        # Get the Windows version selected out of the array and into a variable
        $PlaybookToRun = $Playbooks[$p-1]

        # Build the object to return
        $AnsibleDetails | Add-Member -MemberType NoteProperty -Name "PlaybookToRun" -Value $PlaybookToRun

    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Get-Ansible'" 
        Return $AnsibleDetails
    }
}