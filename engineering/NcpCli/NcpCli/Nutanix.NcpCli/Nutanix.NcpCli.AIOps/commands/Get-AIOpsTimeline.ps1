function Get-AIOpsTimeline {

<#
    .SYNOPSIS
    Gets the AI Ops Timeline Data from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the AI Ops Timeline Data available.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .PARAMETER SourceExtID
    Specifies the Source ExtID of the Entity you wish to return the timeline data for

    .PARAMETER EntityExtID
    Specifies the Entity ExtID of the Entity you wish to return the timeline data for

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns an object with the query result and either the data from the query or the error message

    .EXAMPLE
    PS> Get-AIOpsTimeline -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -SourceExtID $SourceExtID -EntityExtID $EntityExtID
    Gets the current AIOps Timeline from the Prism Central Appliance with Source and Entity ExtID's.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-AIOpsTimeline.md
#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$SourceExtID,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$EntityExtID,
        $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        try {
            
            # Build Api Reference
            write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api Reference"
            $ApiData = (Get-NutanixApiPath -NameSpace "AIOps.Timeline")
            $ApiPath1 = $ApiData.Replace("{SourceExtID}", "$($SourceUUID)")
            $ApiPath = $ApiPath1.Replace("{EntityExtID}", "$($EntityExtID)")
            write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Api: $($ApiPath)"

            # Execute Api Call
            write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query targetting $($PrismIP)"
            Invoke-NutanixApiCall -PrismIP $PrismIP -PrismUserName $PrismUserName -PrismPassword $PrismPassword -ApiPath $ApiPath

        } catch {

            # Api call failed - output the error
            write-warning "$($PSCmdlet.MyInvocation.MyCommand.Name) - Api call failed: $_"

        }

    } # process

    end {} # end

}
