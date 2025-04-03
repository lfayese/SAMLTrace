
<#
.SYNOPSIS
    SAML Token & SSO Diagnostic Script
    - Parses SAML logs for token info and AADSTS errors
    - Maps error codes using aadsts_error_map.json
    - Authenticates using MS Graph Device Code flow (admin fallback)
    - Detects SSO type for user and machine
    - Outputs Excel via ImportExcel
    - Copies report to shared UNC if configured
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load AADSTS error map
$aadstsMapPath = Join-Path $ScriptDir 'aadsts_error_map.json'
$aadstsErrors = Get-Content $aadstsMapPath | ConvertFrom-Json

# Ensure ImportExcel is loaded
$importExcelPath = Join-Path $ScriptDir '..\Tools\ImportExcel'
Import-Module -Name $importExcelPath -Force

# Log scan targets
$logPaths = @(
    "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Network",
    "$env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles",
    "$env:TEMP", "C:\Logs"
)

$foundLogs = foreach ($path in $logPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -Include *.log, *.json, *.xml -ErrorAction SilentlyContinue
    }
}

$results = @()

foreach ($log in $foundLogs) {
    $content = Get-Content $log.FullName -Raw
    if ($content -match "SAMLRequest|SAMLResponse") {
        $matches = Select-String -InputObject $content -Pattern "SAML(Request|Response)=([^&\"'> ]+)" -AllMatches
        foreach ($match in $matches.Matches) {
            $encoded = $match.Groups[2].Value
            try {
                $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
                if ($decoded -like "*<saml*") {
                    $xml = [xml]$decoded
                    $issuer = $xml.DocumentElement.Issuer.'#text'
                    $nameId = $xml.DocumentElement.Subject.NameID.'#text'
                    $errorMatch = ($decoded -split "[\r\n ]") | Where-Object { $_ -match "AADSTS" }
                    $aadstsCode = $errorMatch -match "AADSTS\d+" | Out-Null; $matches = $Matches[0]
                    $aadstsMsg = if ($aadstsErrors[$matches]) { $aadstsErrors[$matches] } else { "Unknown error" }
                    $results += [PSCustomObject]@{
                        FileName  = $log.Name
                        FilePath  = $log.FullName
                        Issuer    = $issuer
                        NameID    = $nameId
                        ErrorCode = $matches
                        ErrorMeaning = $aadstsMsg
                        Timestamp = $log.LastWriteTime
                    }
                }
            } catch {}
        }
    }
}

# Review SSO integration state
$signInInfo = @{
    UserDomainJoined   = (dsregcmd /status | Select-String -Pattern 'User\s+.*JOINED').ToString().Split(':')[-1].Trim()
    DeviceDomainJoined = (dsregcmd /status | Select-String -Pattern 'Device\s+.*JOINED').ToString().Split(':')[-1].Trim()
    WorkplaceJoined    = (dsregcmd /status | Select-String -Pattern 'WorkplaceJoined').ToString().Split(':')[-1].Trim()
}

# Save report
$outputPath = Join-Path $env:USERPROFILE 'Desktop\SAML_Token_Report.xlsx'
$results | Export-Excel -Path $outputPath -Title 'SAML Token Issues' -WorksheetName 'Traces' -BoldTopRow
$signInInfo.GetEnumerator() | Export-Excel -Path $outputPath -WorksheetName 'SSO_Status' -AutoSize

# Upload to UNC if configured
$uncPath = '\\YOUR-SHARE\SAMLReports'
if (Test-Path $uncPath) {
    Copy-Item -Path $outputPath -Destination (Join-Path $uncPath ('SAML_Token_Report_' + $env:COMPUTERNAME + '.xlsx')) -Force
}

Write-Host "✅ Excel report saved to: $outputPath"


function Get-AADSTSErrorDescription {
    param (
        [Parameter(Mandatory)]
        [string]$ErrorCode,

        [string]$MapPath = "$PSScriptRoot\aadsts_error_map.json"
    )

    if (-Not (Test-Path $MapPath)) {
        Write-Warning "AADSTS error map not found at $MapPath"
        return
    }

    try {
        $json = Get-Content -Raw -Path $MapPath | ConvertFrom-Json
        if ($json.ContainsKey($ErrorCode)) {
            return $json.$ErrorCode
        } else {
            Write-Output "No description found for code: $ErrorCode"
        }
    }
    catch {
        Write-Error "Failed to load or parse $MapPath. $_"
    }
}
