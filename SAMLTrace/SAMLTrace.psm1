
function Get-SAMLTraces {
    <#
    .SYNOPSIS
    Get-SAMLTraces - Describe what this function does.
    #>
    <#
    .SYNOPSIS
        Parses SAML logs for token info and maps AADSTS errors using external map.
    #>
    [CmdletBinding()]
    param(
        [string]$ExportPath = "$HOME/Desktop/SAML_Token_Report.xlsx",
        [string]$UNCPath
    )
    $ErrorActionPreference = "Stop"
    $ScriptDir = $PSScriptRoot
    $aadstsMapPath = Join-Path $ScriptDir 'aadsts_error_map.json'
    $aadstsErrors = Get-Content $aadstsMapPath | ConvertFrom-Json

    Import-Module (Join-Path $ScriptDir '..\..\Tools\ImportExcel') -Force

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
            $matches = Select-String -InputObject $content -Pattern "SAML(Request|Response)=([^&"'> ]+)" -AllMatches
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

    $results | Export-Excel -Path $ExportPath -Title 'SAML Tokens' -WorksheetName 'Traces' -BoldTopRow

    if ($UNCPath -and (Test-Path $UNCPath)) {
        $copyTo = Join-Path $UNCPath ("SAML_Report_" + $env:COMPUTERNAME + ".xlsx")
        Copy-Item $ExportPath -Destination $copyTo -Force
    }

    return $results
}

function Get-SSOStatus {
    <#
    .SYNOPSIS
    Get-SSOStatus - Describe what this function does.
    #>
    <#
    .SYNOPSIS
        Returns user and device SSO join state
    #>
    $out = @{
        UserDomainJoined   = (dsregcmd /status | Select-String -Pattern 'User\s+.*JOINED').ToString().Split(':')[-1].Trim()
        DeviceDomainJoined = (dsregcmd /status | Select-String -Pattern 'Device\s+.*JOINED').ToString().Split(':')[-1].Trim()
        WorkplaceJoined    = (dsregcmd /status | Select-String -Pattern 'WorkplaceJoined').ToString().Split(':')[-1].Trim()
    }
    return $out
}

Export-ModuleMember -Function Get-SAMLTraces, Get-SSOStatus


function Register-GraphApp {
    <#
    .SYNOPSIS
    Register-GraphApp - Describe what this function does.
    #>
    <#
    .SYNOPSIS
        Authenticates to Microsoft Graph using device code flow and returns a token.
    #>
    [CmdletBinding()]
    param (
        [string]$TenantId = "common",
        [string]$ClientId = "04f0c124-f2bc-4f06-b5ed-5d6f3e56a679",  # Microsoft Graph PowerShell default public client
        [string[]]$Scopes = @("https://graph.microsoft.com/.default")
    )

    $body = @{
        client_id = $ClientId
        scope     = ($Scopes -join " ")
    }

    $deviceCodeResp = Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/devicecode" -Body $body -ContentType "application/x-www-form-urlencoded"

    Write-Host "To sign in, use a web browser to open the page $($deviceCodeResp.verification_uri) and enter the code $($deviceCodeResp.user_code)" -ForegroundColor Yellow

    do {
        Start-Sleep -Seconds $deviceCodeResp.interval
        $pollResp = try {
            Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body @{
                grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
                client_id   = $ClientId
                device_code = $deviceCodeResp.device_code
            } -ContentType "application/x-www-form-urlencoded"
        } catch {
            if ($_.Exception.Response.StatusCode.value__ -eq 400) {
                $errorResp = ($_ | ConvertFrom-Json)
                if ($errorResp.error -eq "authorization_pending") { continue }
                elseif ($errorResp.error -eq "authorization_declined") { throw "Authorization declined." }
                elseif ($errorResp.error -eq "expired_token") { throw "Device code expired." }
                else { throw $_ }
            }
        }
    } while (-not $pollResp)

    Write-Host "✅ Authenticated successfully."
    return $pollResp
}

Export-ModuleMember -Function Register-GraphApp


function Upload-GraphFile {
    <#
    .SYNOPSIS
    Upload-GraphFile - Describe what this function does.
    #>
    <#
    .SYNOPSIS
        Uploads a file to OneDrive or SharePoint using Microsoft Graph token.
    .PARAMETER FilePath
        Local path to the file.
    .PARAMETER AccessToken
        Token returned from Register-GraphApp.
    .PARAMETER RemotePath
        Remote file path under root (e.g. 'Reports/SAML_Report.xlsx')
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$AccessToken,
        [Parameter()][string]$RemotePath = "Reports/SAML_Report_$env:COMPUTERNAME.xlsx"
    )

    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    $uploadUrl = "https://graph.microsoft.com/v1.0/me/drive/root:/$RemotePath:/content"
    $headers = @{ Authorization = "Bearer $AccessToken" }

    try {
        Invoke-RestMethod -Method PUT -Uri $uploadUrl -Headers $headers -InFile $FilePath -ContentType "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        Write-Host "✅ File uploaded to Graph at /$RemotePath"
    } catch {
        Write-Warning "❌ Upload failed: $($_.Exception.Message)"
    }
}

function Upload-LocalShare {
    <#
    .SYNOPSIS
    Upload-LocalShare - Describe what this function does.
    #>
    <#
    .SYNOPSIS
        Uploads a file to a local or UNC share.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$UNCPath
    )

    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    if (-not (Test-Path $UNCPath)) {
        throw "UNC path not found: $UNCPath"
    }

    $target = Join-Path $UNCPath ("SAML_Report_" + $env:COMPUTERNAME + ".xlsx")
    Copy-Item -Path $FilePath -Destination $target -Force
    Write-Host "✅ File copied to: $target"
}

Export-ModuleMember -Function Upload-GraphFile, Upload-LocalShare