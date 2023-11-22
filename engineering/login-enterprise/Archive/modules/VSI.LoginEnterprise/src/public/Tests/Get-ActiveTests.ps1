Function Get-LEActiveTests {
    Invoke-PublicApiMethod -Path "v6/test-diagnostics" -Method Get
}