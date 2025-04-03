@{
    RootModule        = 'SAMLTrace.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '8a48aaae5a58b898fdd21c3db642fde0'
    Author            = 'YourName'
    CompanyName       = 'YourOrg'
    Description       = 'SAMLTrace - Investigate and export SAML traces with Excel, SSO, and more.'
    PowerShellVersion = '5.1'
    RequiredModules   = @('ImportExcel')
    FunctionsToExport = @('Get-SAMLTraces', 'Get-SSOStatus', 'Register-GraphApp', 'Upload-GraphFile', 'Upload-LocalShare')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}