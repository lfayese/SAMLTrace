
# Usage Instructions

- Run the script manually:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
cd C:\SAMLTools\Scripts
.\SAMLTraceAnalyzer.ps1
```

- Outputs Excel with token trace, AADSTS error mapping, and local SSO integration (device + user)

- If connected to SharePoint/OneDrive with proper permissions, Excel will also upload.

Requirements:
- Windows 10/11
- PowerShell 5.1+
- Internet (or offline ImportExcel from Tools/)
