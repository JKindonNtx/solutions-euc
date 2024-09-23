function Merge-JSONFilesForTestConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][string]$TestSpecificJSONPath,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][array]$AdditionalJsonFilePaths,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][string]$OutputFilePath # if not defined, We don't export the object to a file and we return the object and not the path
    )
    
    begin {
        $JSONMergeErrorCount = 0
        
        # Test if the Test Specific JSON path exists
        if (-not (Test-Path -Path $TestSpecificJSONPath)) {
            Write-Log -Message "Test Specific JSON file not found: $TestSpecificJSONPath" -Level Error
            Break #replace with Exit 1
        }

        # Test if each Additional JSON path exists
        foreach ($JSONPath in $AdditionalJsonFilePaths) {
            if (-not (Test-Path -Path $JSONPath)) {
                Write-Log -Message "Additional JSON file not found: $JSONPath" -Level Error
                Break #replace with Exit 1
            }
        }

        Write-Log -Message "All JSON paths verified" -Level Info
        
    }
    
    process {
        # Initialize the combined JSON object with the Test Specific JSON content
        $combinedJson = [PSCustomObject]@{}

        # Load the Test Specific JSON file
        $TestSpecificJSON = Get-Content -Path $TestSpecificJSONPath -ErrorAction Stop
        $TestSpecificJSON = $TestSpecificJSON -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
        $TestSpecificJSON = $TestSpecificJSON | ConvertFrom-Json -ErrorAction Stop

        # Add properties from the Test Specific JSON object
        $TestSpecificJSON.PSObject.Properties | ForEach-Object {
            $combinedJson | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
        }

        # Loop through additional JSON files
        foreach ($JSON in $AdditionalJsonFilePaths) {
            $AdditionalJSON = Get-Content -Path $JSON -ErrorAction Stop
            $AdditionalJSON = $AdditionalJSON -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
            $AdditionalJSON = $AdditionalJSON | ConvertFrom-Json -ErrorAction Stop

            # Add properties from the Additional JSON object
            $AdditionalJSON.PSObject.Properties | ForEach-Object {
                if ($combinedJson.PSObject.Properties[$_.Name]) {
                    # Property exists, check the values
                    $existingValue = $combinedJson.PSObject.Properties[$_.Name].Value
                    $newValue = $_.Value
            
                    if ($existingValue -is [PSCustomObject] -and $newValue -is [PSCustomObject]) {
                        # If both values are objects, merge them
                        $mergedValue = [PSCustomObject]@{}

                        $existingValue.PSObject.Properties | ForEach-Object {
                            try {
                                $mergedValue | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value -ErrorAction Stop
                            }
                            catch {
                                Write-Log -Message "Duplicate value found for property value '$($existingValue.PSObject.Properties.Name)' in $($JSON)" -Level Error
                                $JSONMergeErrorCount ++
                            } 
                        }
                        $newValue.PSObject.Properties | ForEach-Object {
                            try {
                                $mergedValue | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value -ErrorAction Stop 
                            }
                            catch {
                                Write-Log -Message "$_.Exception.Message" -Level Error
                                $JSONMergeErrorCount ++
                            } 
                        }
                        $combinedJson.PSObject.Properties[$_.Name].Value = $mergedValue
                    }

                }
                else {
                    # Property does not exist, add it
                    $combinedJson | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
                }
            }
        }

        if ($JSONMergeErrorCount -gt 0) {
            Write-Log -Message "There were $($JSONMergeErrorCount) errors during the JSON merge process. Script will not continue." -Level Error
            Break # Replace with Exit 1
        }

        # Convert the combined object back to JSON
        $combinedJson = $combinedJson | ConvertTo-Json -Depth 10

        # Export the JSON to a file
        if (-not [string]::IsNullOrEmpty($OutputFilePath)) {
            $combinedJson | Set-Content -Path $OutputFilePath -Force #if we decide to pass the object back, then this can be klled off
        }

    }
    
    end {
        if (-not [string]::IsNullOrEmpty($OutputFilePath)) {
            return $OutputFilePath #This might need to be just returning the path so we can use it in the next function which is Get-ValidJSON.
        } else {
            return $combinedJson #return $combinedJson #this object could be passed directly to the Get-ValidJSON function
        }
    }
}
