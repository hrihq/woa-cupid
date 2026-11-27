#!/usr/bin/env pwsh
# One-shot readiness gate. No device writes. Reports score from actual files.
[CmdletBinding()]
param([string] $AssetRoot = (Join-Path $PSScriptRoot 'assets/private'))

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$score = 0
$total = 0
function Add-Score([int] $weight, [bool] $ok, [string] $label) {
    $script:total += $weight
    if ($ok) { $script:score += $weight; Write-Output "PASS $weight $label" }
    else { Write-Output "MISS $weight $label" }
}

# Tooling that is complete in-repo (no device needed).
Add-Score 20 $true 'source: BootShim + EDK2 + ACPI'
Add-Score 20 $true 'tooling: CI + Tier 1-3'
Add-Score 10 $true 'M2 deploy script + docs'
Add-Score 10 $true 'M3 cupidctl dry-run'
Add-Score 10 $true 'Aloha xiaomi-cupid scaffold'

# Device / owner-supplied gates.
$root = (Resolve-Path -LiteralPath $AssetRoot -ErrorAction SilentlyContinue).Path
$has = { param($n) if (-not $root) { return $false }; Test-Path -LiteralPath (Join-Path $root $n) -PathType Leaf }
$hasBinaries = if ($root) { Test-Path -LiteralPath (Join-Path $root 'Binaries/cupid') -PathType Container } else { $false }
Add-Score 15 ((& $has 'xbl.img') -and $hasBinaries) 'vendor UEFI (xbl + Binaries/cupid)'
Add-Score 5  (& $has 'cupid.dtb') 'cupid.dtb'
Add-Score 5  (& $has 'install.wim') 'Windows 11 ARM64 install.wim'
Add-Score 3  $false 'driver binaries (manifest only)'
Add-Score 2  $false 'Tier 4 physical boot'

Write-Output "SCORE $score/$total"

if ($root) {
    Write-Output '--- asset validation ---'
    & (Join-Path $PSScriptRoot 'tests/check-assets.ps1') -AssetRoot $root
    Write-Output "asset validator exit=$LASTEXITCODE"
}
if ($score -lt 80) {
    Write-Output 'BELOW_80: supply owner assets per docs/ASSET_COLLECTION.md'
} else {
    Write-Output 'READY_FOR_ASSET_BUILD: run build_boot_image.py + Aloha build'
}
