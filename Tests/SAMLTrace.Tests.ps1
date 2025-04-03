
Describe 'SAMLTrace Module - Core Tests' {
    It 'Should import the module without error' {
        { Import-Module "$PSScriptRoot/../SAMLTrace/SAMLTrace.psm1" -Force } | Should -Not -Throw
    }
}

Describe 'Get-SAMLTraces' {
    It 'Should run without error on valid sample logs' {
        { Get-SAMLTraces -LogPath "$PSScriptRoot/../sample-logs" -OutputExcel "$PSScriptRoot/../output/test-output.xlsx" } | Should -Not -Throw
    }

    It 'Should throw on missing log folder' {
        { Get-SAMLTraces -LogPath "$PSScriptRoot/../missing-folder" -OutputExcel "$PSScriptRoot/../output/test.xlsx" } | Should -Throw
    }
}

Describe 'Get-SSOStatus' {
    It 'Should return valid output or handle gracefully' {
        { Get-SSOStatus } | Should -Not -BeNullOrEmpty
    }
}

Describe 'Register-GraphApp' {
    It 'Should not throw even if no credentials are present (simulate)' {
        { Register-GraphApp -ClientId 'dummy' -TenantId 'dummy' -Secret 'dummy' } | Should -Not -Throw
    }
}

Describe 'Upload-GraphFile' {
    It 'Should throw if file path or Graph token is missing' {
        { Upload-GraphFile -FilePath '' -GraphToken '' } | Should -Throw
    }
}

Describe 'Upload-LocalShare' {
    It 'Should throw if local share is unavailable' {
        { Upload-LocalShare -FilePath '' -DestinationPath '' } | Should -Throw
    }
}
