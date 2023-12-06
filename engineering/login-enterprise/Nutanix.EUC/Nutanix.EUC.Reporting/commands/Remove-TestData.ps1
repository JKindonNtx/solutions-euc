function Remove-TestData {
    <#
        .SYNOPSIS
        Removes a Test Run from the influx DB.
    
        .DESCRIPTION
        This function will take a test run name and remove that data from the Influx Database.
    
        .LINK
        Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/Remove-TestData.md
    
        .LINK
        Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.LE
    
    #>
        [CmdletBinding()]
    
        Param (
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$InfluxPath,
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$HostUrl,
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$Org,
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$Bucket,
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)]$Start = "2022-12-30T00:00:00.000000000Z",
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)]$Stop = "2023-01-14T00:00:00.000000000Z",
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$Test,
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)]$Run,
            [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)]$Token
        )
    
        begin{
    
            # Build Influx EXE Location
            $InfluxEXE = Join-Path -Path $InfluxPath -ChildPath "influx.exe"

        }
    
        process {
    
            # Build Influx Config
            $ConfigCreateParams = "config create --config-name influxdb --host-url $($HostUrl) --token $($Token) --org $($Org) --active"
            $InfluxConfig = Start-Process -FilePath $InfluxEXE -Wait -ArgumentList $ConfigCreateParams -WindowStyle Minimized

            # Remove Influx Test
            if($Run){
                $Params = "delete --bucket $($Bucket) --start $($Start) --stop $($Stop) --predicate ""_measurement=\""$($Test)\"" and Run=\""$($Run)\"" "" --token $($Token)"
            } else {
                $Params = "delete --bucket $($Bucket) --start $($Start) --stop $($Stop) --predicate _measurement=\""$($Test)\"" --token $($Token)"
            }
            $InfluxTest = Start-Process -FilePath $InfluxEXE -Wait -ArgumentList $Params -WindowStyle Minimized

            # Remove Influx Config
            $ConfigRemoveParams = "config delete influxdb"
            $InfluxConfig = Start-Process -FilePath $InfluxEXE -Wait -ArgumentList $ConfigRemoveParams -WindowStyle Minimized

        } # process
    
        end {
    
            # Return data for the function
            return $true
    
        } # end
    
    }
    