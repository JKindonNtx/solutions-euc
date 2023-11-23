function Update-Slack {
<#
    .SYNOPSIS
    Updates a Slack Channel

    .DESCRIPTION
    This function will Update a slack channel with the status of the automation tasks.
    
    .PARAMETER Message
    The message to send

    .PARAMETER Slack
    The Slack Channel to update

    .EXAMPLE
    PS> Update-Slack -Message "Message" -Slack "https://slack/api"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    None

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Update-Slack.md

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
        $Slack,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        $Message
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":Message: $Message" 
        Write-Host (Get-Date)":Slack: $Slack" 

        $body = ConvertTo-Json -Depth 4 @{
            username = "LoginVSI Automation Factory"
            attachments = @(
                @{
                    fallback = "Docker Slack Integration."
                    color = "#36a64f"
                    pretext = "*Docker Slack Integration*"
                    title = "Automation Complete"
                    text = $Message  
                }
            )
        }
        $RestError = $null

      if ($PSEdition -eq "Core") {
            try {
                Invoke-RestMethod -uri $Slack -Method Post -body $body -ContentType 'application/json' -SkipCertificateCheck 
            }
            catch {
                Write-Host -Message "Error Updating Slack"
            }
        } else {
            if (-not("SSLValidator" -as [type])) {
                add-type -TypeDefinition @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class SSLValidator {
    public static bool ReturnTrue(object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }

    public static RemoteCertificateValidationCallback GetDelegate() {
        return new RemoteCertificateValidationCallback(SSLValidator.ReturnTrue);
    }
}
"@
            }

            #[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLValidator]::GetDelegate()
            try {
                Invoke-RestMethod -uri $Slack -Method Post -body $body -ContentType 'application/json'
            }
            catch {
                Write-Host -Message "Error Updating Slack"
            }
        }

    }
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # End

} # Update-Slack
