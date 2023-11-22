function Get-ValidJSON {
    <#
.SYNOPSIS
Makes a pretty write-host output for logging to console

.DESCRIPTION
Makes a pretty write-host output for logging to console

.PARAMETER Message
The message used for logging output. Mandatory

.PARAMETER Update
If specified, nonewline is used on write host

.PARAMETER Level
Info, Warning or Error. Defaults to Info

.INPUTS
This function will take inputs via pipeline.

.OUTPUTS
What the function returns.

.EXAMPLE
PS> Write-Log -Message "hello" -Level Info
Writes an Info Output to the console

#>
    [CmdletBinding()]

    Param (
        $JSON
    )

    begin{
        $Return = $false
    }

    process{

        # Validate the JSON Entries
        $JSONPass = $false

        if($JSONPass){
            $Return = $true
        }
    }

    end {
        Return $Return
    }
}
