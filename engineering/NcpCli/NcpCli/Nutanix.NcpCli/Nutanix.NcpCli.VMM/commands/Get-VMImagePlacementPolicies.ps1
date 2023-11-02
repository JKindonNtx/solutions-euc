function Get-VMImagePlacementPolicies {

<#
    .SYNOPSIS
    Gets the Image Placement Policies from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the Image Placement Policies for a specified image Ext ID.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .PARAMETER ImageExtID
    Specifies the Ext ID of the image you wish to obtain

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns an object with the query result and either the data from the query or the error message

    .EXAMPLE
    PS> Get-VMImagePlacementPolicies -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ImageExtID "214313412-314132-12fda324-efdsa"
    Gets the Image with Ext ID 214313412-314132-12fda324-efdsa from the Prism Central Appliance and displayed its placement policies.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-VMImagePlacementPolicies.md

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$ImageExtID,
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
            if($null -ne $ImageExtID){
                $ApiRoot = (Get-NutanixApiPath -NameSpace "VMM.VMImagePlacementPolicies")
                $ApiPath = "$($ApiRoot)/$($ImageExtID)"
            } else {
                $ApiPath = (Get-NutanixApiPath -NameSpace "VMM.VMImagePlacementPolicies")
            }
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
