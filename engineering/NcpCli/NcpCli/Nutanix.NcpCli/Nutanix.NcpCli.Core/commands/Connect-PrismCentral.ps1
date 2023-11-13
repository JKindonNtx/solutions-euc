function Connect-PrismCentral {
<#
    .SYNOPSIS
    Executes an API call to connect to a Prism Central instance.

    .DESCRIPTION
    This function will run an Api call against Prism Central and authenticate the user session.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns a global variable called ntnxSession with the web session details

    .EXAMPLE
    PS> Connect-PrismCentral -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password"
    Connects to the Prism Central instance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Connect-PrismCentral.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>
    
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword
    )

    begin {

        # Build the Api Call authorization header and content variables
        $ContentType = 'application/json'
        $Method = "POST"
        $header = @{
            Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($PrismUserName) + ":" + $($PrismPassword)))
        }

        # Build the full Api Uri
        $Uri = "https://$($PrismIP):9440"

        # Build WebSession Object
        $global:ntnxSession = New-Object -TypeName PSObject
        $ntnxSession | Add-Member -NotePropertyName Endpoint -NotePropertyValue $Uri -TypeName String
        $ntnxSession | Add-Member -NotePropertyName Status -NotePropertyValue "Disconnected" -TypeName String
        $ntnxSession | Add-Member -NotePropertyName Error -NotePropertyValue "None" -TypeName String

    } # begin

    process {

        try {

                # Execute the Api query and catch any errors
                write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Connecting to Prism Central"
                try {
                    $Session = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Header -SkipCertificateCheck -SessionVariable ntnxWebSession | Out-Null
                    $ntnxSession | Add-Member -NotePropertyName WebSession -NotePropertyValue $ntnxWebSession -TypeName Microsoft.PowerShell.Commands.WebRequestSession
                    $ntnxSession.Status = "Connected"
                } catch {
                    $ErrorMessage = Get-NutanixApiError -ErrorMessage $_
                    $ntnxSession.Error = $ErrorMessage
                }
        } catch {  
            
            $ErrorMessage = Get-NutanixApiError -ErrorMessage $_
            $ntnxSession.Error = $ErrorMessage

        }
        
    } # process

    end {} # end

}