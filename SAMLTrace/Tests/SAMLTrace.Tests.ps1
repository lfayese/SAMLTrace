
Describe 'SAMLTrace Analyzer Script Tests' {
    It 'Should have the aadsts_error_map.json file available' {
        Test-Path "$PSScriptRoot/../aadsts_error_map.json" | Should -Be $true
    }

    It 'Should be able to read and parse the JSON map' {
        $json = Get-Content "$PSScriptRoot/../aadsts_error_map.json" -Raw | ConvertFrom-Json
        $json.Count | Should -BeGreaterThan 0
    }

    It 'Should load the analyzer script without errors' {
        { . "$PSScriptRoot/../SAMLTraceAnalyzer.ps1" } | Should -Not -Throw
    }
}


Describe "Get-AADSTSErrorDescription" {
    It "Returns known description for AADSTS50076" {
        $desc = Get-AADSTSErrorDescription -ErrorCode "AADSTS50076"
        $desc | Should -Match "multi-factor authentication"
    }

    It "Returns fallback message for unknown code" {
        $desc = Get-AADSTSErrorDescription -ErrorCode "AADSTS99999"
        $desc | Should -Match "No description found"
    }

    It "Warns when JSON path is missing" {
        $desc = Get-AADSTSErrorDescription -ErrorCode "AADSTS50076" -MapPath "invalid_path.json"
        $desc | Should -BeNullOrEmpty
    }
}
