function Get-AnsiblePlaybooks {
<#
    .SYNOPSIS
    Gathers a list of available Ansible Playbooks.

    .DESCRIPTION
    This function will gather a list of Ansible Playbooks available in the build lab repository.
    
    .PARAMETER SearchString
    The search string to filter the OS Versions

    .PARAMETER AnsiblePath
    The path to the Ansible Playbooks

    .EXAMPLE
    PS> Get-AnsiblePlaybooks -SearchString "SRV" -AnsiblePath "/ansible/"

    .EXAMPLE
    PS> Get-AnsiblePlaybooks -Search "W10" -Path "/ansible/"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    PSCustomObject containing the details of the Ansible Playbooks

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Get-AnsiblePlaybooks.md

    .NOTES
    Author          Version         Date            Detail
    David Brett     v1.0.0          28/11/2022      Function creation
    David Brett     v1.0.1          06/12/2022      Updated Parameter definition and added Alias' for SearchString and AnsiblePath
                                                    Updated function header to include MD help file
                                                    Changed Write-Host from hardcoded function name to $($PSCmdlet.MyInvocation.MyCommand.Name)

#>


    [CmdletBinding()]

    Param
    (
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [Alias('Search')]
        [System.String[]]$SearchString,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [Alias('Path')]
        [System.String[]]$AnsiblePath
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

    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $AnsibleDetails
    } # End
    
} # Get-AnsiblePlaybooks