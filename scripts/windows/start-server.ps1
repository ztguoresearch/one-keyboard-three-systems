#Requires -Version 5.1
<#
.SYNOPSIS
    Start the Deskflow core in server mode if it is not already listening.

.DESCRIPTION
    Designed for a Windows Server + Linux Client setup.
    The core is started hidden and its stdout/stderr are written next to the executable.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\start-server.ps1

.EXAMPLE
    .\start-server.ps1 -DeskflowRoot "E:\Tools\Deskflow" -Port 24800
#>
[CmdletBinding()]
param(
    [string]$DeskflowRoot = "C:\Tools\Deskflow",
    [string]$SettingsPath = (Join-Path $env:APPDATA "Deskflow\Deskflow.conf"),
    [int]$Port = 24800
)

$ErrorActionPreference = "Stop"

$core = Join-Path $DeskflowRoot "deskflow-core.exe"
$log = Join-Path $DeskflowRoot "deskflow-core.log"
$err = Join-Path $DeskflowRoot "deskflow-core.err.log"

if (-not (Test-Path $core)) {
    throw "deskflow-core.exe not found: $core"
}
if (-not (Test-Path $SettingsPath)) {
    throw "Deskflow.conf not found: $SettingsPath"
}

$listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($listening) {
    Write-Host "Deskflow server is already listening on port $Port."
    exit 0
}

Write-Host "Starting Deskflow core from $DeskflowRoot ..."
Start-Process -FilePath $core `
    -ArgumentList @("server", "--new-instance", "-s", $SettingsPath) `
    -WorkingDirectory $DeskflowRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $log `
    -RedirectStandardError $err

Start-Sleep -Seconds 2

$listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($listening) {
    Write-Host "Deskflow server started. Listener:"
    $listening | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
    exit 0
}

Write-Host "Deskflow server did not start. Last error log lines:"
if (Test-Path $err) {
    Get-Content $err -Tail 20
}
exit 1
