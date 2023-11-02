function Get-AIOpsMetadata {

<#
    .SYNOPSIS
    Gets the AIOps Metadata from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the AIOps Metadata available.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .PARAMETER SourceExtID
    Specifies the Source ExtID of the Entity you wish to return the metadata for

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns an object with the query result and either the data from the query or the error message

    .EXAMPLE
    PS> Get-AIOpsMetadata -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -SourceExtID "db293e8a-5770-c3c7-4213-85dbbc1d3679"
    Gets the AIOps MetaData from the Prism Central Appliance for SourceExtID db293e8a-5770-c3c7-4213-85dbbc1d3679.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-AIOpsMetadata.md
#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$SourceExtID,
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
            $ApiData = (Get-NutanixApiPath -NameSpace "AIOps.Metadata")
            $ApiPath = $ApiData.Replace("{SourceExtID}", "$($SourceExtID)")
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
