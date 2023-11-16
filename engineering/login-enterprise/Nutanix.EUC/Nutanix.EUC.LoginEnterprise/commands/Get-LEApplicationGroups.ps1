function Get-LEApplicationGroups {

    [CmdletBinding()]

    Param (
        $include = "none"
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting Get-LEApplicationGroups" -Level Info
    }

    process {
        $Body = @{
            orderBy   = "Name"
            direction = "Asc"
            count     = "5000"
            include   = $include
        }
        
        try {
            $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/application-groups" -Body $Body
            $Response.items
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Get-LEApplicationGroups" -Level Info
    } # end

}
