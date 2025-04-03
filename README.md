<!-- CI Status Badge (Update `your-repo` once created) -->
![CI](https://img.shields.io/github/actions/workflow/status/lfayese/your-repo/pester.yml?branch=main)


# SAMLTrace Enhanced Module 📦

An enterprise-ready PowerShell module for analyzing and exporting Azure AD (AADSTS) error traces. Includes enhanced error mapping, Excel automation, Pester testing, and CI/CD readiness.

---

## 📦 Features

- 🔍 AADSTS error map with over 200+ enriched Microsoft error codes
- ✅ PowerShell function for dynamic error lookup
- 📊 Automated Excel export using [ImportExcel](https://github.com/dfinke/ImportExcel)
- 🧪 Pester tests included
- 🗂 Categorized Excel output with `Success`, `Warnings`, `Unknowns` worksheets
- ⏰ Scheduler-ready for automated weekly reporting
- 📁 Flat module layout for cleaner integration

---

## 🛠 Installation

1. **Extract** the full ZIP module.
2. Ensure PowerShell 5.1+ or PowerShell Core is installed.
3. (Optional) Install `ImportExcel`:
   ```powershell
   Install-Module ImportExcel -Scope CurrentUser -Force
   ```

---

## 🚀 Usage

### 🔹 Run Error Report
```powershell
cd path	o\module
.\Export-AADSTSErrorLogs.ps1
```

### 🔹 Lookup Single Error
```powershell
.\SAMLTraceAnalyzer.ps1
Get-AADSTSErrorDescription -ErrorCode "AADSTS50076"
```

---

## 📅 Schedule Weekly Report

Create a task using this command (admin):
```cmd
schtasks /create /tn "SAMLTraceReport" ^
 /tr "powershell -ExecutionPolicy Bypass -File path\to\Export-AADSTSErrorLogs.ps1" ^
 /sc weekly /d MON /st 08:00 /rl HIGHEST /f
```

---

## 🧪 Run Pester Tests

```powershell
Invoke-Pester -Script .\Tests\SAMLTrace.Tests.ps1
```

---

## 📂 File Structure

```
SAMLTrace/
├── aadsts_error_map.json
├── SAMLTraceAnalyzer.ps1
├── Export-AADSTSErrorLogs.ps1
├── Tests/
│   └── SAMLTrace.Tests.ps1
├── Tools/
│   └── ImportExcel/
│       ├── Public/
│       └── Examples/
└── README.md
```

---

## 👩‍💼 Admin Notes

- Use Intune to push and schedule script via `.cmd` or `.ps1`
- All logs are exported to `aadsts_error_log.xlsx` in module root
- Make sure `.json` and `.xlsx` are writeable in the script context

