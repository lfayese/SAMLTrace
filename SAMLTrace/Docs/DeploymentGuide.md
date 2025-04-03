
# Deployment Guide

## Step-by-step

1. Extract `SAMLTraceDeploymentPackage.zip` to a local folder (e.g. `C:\SAMLTools`)
2. Run `Scripts\SAMLTraceAnalyzer.ps1` with admin privileges
3. Reports are saved to desktop and optionally copied to a UNC share
4. Use Intune Win32 packaging to deploy as `.intunewin` app or detection script

Ensure PowerShell Execution Policy allows running local scripts.
