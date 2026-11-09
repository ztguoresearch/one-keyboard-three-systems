#Requires -Version 5.1
<#
.SYNOPSIS
    Allow only one remote IP to reach the Deskflow port.

.DESCRIPTION
    Creates an inbound TCP rule scoped to the client IP.
    Optionally disables the legacy "Deskflow Server"/"Deskflow Client" any-address rules,
    and enables the Windows Private firewall profile.

.EXAMPLE
    .\setup-firewall.ps1 -RemoteAddress 10.10.10.2

.EXAMPLE
    .\setup-firewall.ps1 -RemoteAddress 10.10.10.2 -DisableLegacyRules -EnablePrivateFirewall
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RemoteAddress,

    [int]$Port = 24800,

    [string]$RuleName = "Deskflow $Port ($RemoteAddress only)",

    [switch]$DisableLegacyRules,

    [switch]$EnablePrivateFirewall
)

$ErrorActionPreference = "Stop"

# Recreate the rule so repeated runs are idempotent.
Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue |
    Remove-NetFirewallRule

New-NetFirewallRule `
    -DisplayName $RuleName `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort $Port `
    -RemoteAddress $RemoteAddress `
    -Action Allow `
    -Profile Any | Out-Null

Write-Host "Created rule: $RuleName -> $RemoteAddress`:$Port"

if ($DisableLegacyRules) {
    Get-NetFirewallRule -DisplayName "Deskflow Server", "Deskflow Client" -ErrorAction SilentlyContinue |
        Disable-NetFirewallRule
    Write-Host "Disabled legacy Deskflow Server/Client rules."
}

if ($EnablePrivateFirewall) {
    Set-NetFirewallProfile -Profile Private -Enabled True
    Write-Host "Enabled Windows firewall Private profile."
}

Write-Host ""
Write-Host "Current Deskflow rules:"
Get-NetFirewallRule -DisplayName $RuleName, "Deskflow Server", "Deskflow Client" -ErrorAction SilentlyContinue |
    Format-Table DisplayName, Enabled, Direction, Action, Profile -AutoSize
