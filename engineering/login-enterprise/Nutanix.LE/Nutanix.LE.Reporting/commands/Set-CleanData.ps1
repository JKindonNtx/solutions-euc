function Set-CleanData {
    <#
        .SYNOPSIS
        Cleans the data ready for Grafana.
    
        .DESCRIPTION
        This function will take in data fields and clean that for Grafana.
    
        .PARAMETER Data
        The Data to clean.
    
        .INPUTS
        This function will take inputs via pipeline.
    
        .OUTPUTS
        This function will return clean data.
    
        .EXAMPLE
        PS> Set-CleanData -Data "This is some data to clean"
        Cleans the data being passed in.
    
        .LINK
        Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/Set-CleanData.md
    
        .LINK
        Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.LE
    
    #>
        [CmdletBinding()]
    
        Param (
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$Data
        )
    
        begin{
    
            # Set strict mode 
            Set-StrictMode -Version Latest
    
        }
    
        process {

            $Data = $Data -replace " ", "\ "

        } # process
    
        end {
    
            # Return data for the function
            return $Data
    
        } # end
    
    }
    