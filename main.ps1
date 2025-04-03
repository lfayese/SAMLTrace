
<#
.SYNOPSIS
    Launcher for SAMLTrace module.

.DESCRIPTION
    Loads the SAMLTrace module and executes core investigation or export functions.
#>

# Import the module (assumes it's in a folder named 'SAMLTrace')
Import-Module "$PSScriptRoot\SAMLTrace\SAMLTrace.psm1" -Force

# Example usage (modify as needed):
Write-Host "Starting SAMLTrace analysis..."
Get-SAMLTraces -LogPath ".\sample-logs" -OutputExcel ".\output\trace-report.xlsx"

Write-Host "Completed. Output written to .\output\trace-report.xlsx"
