#!/usr/bin/env pwsh
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $DriverRoot = (Join-Path $PSScriptRoot 'drivers/cache'),
    [string] $WindowsMount,
    [ValidateSet('Online', 'Offline')] [string] $Mode = 'Online',
    [string] $DiagEfiSource,
    [string] $Staging = (Join-Path $PSScriptRoot 'build/drivers')
)

$ErrorActionPreference = 'Stop'
$manifestPath = Join-Path $PSScriptRoot 'drivers/manifest.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $Staging | Out-Null

foreach ($driver in $manifest.drivers) {
    foreach ($relative in $driver.files) {
        $source = Join-Path $DriverRoot $relative
        if (-not (Test-Path -LiteralPath $source)) {
            Write-Warning "Driver file missing: $source"
            continue
        }
        $destination = Join-Path $Staging $relative
        if ($PSCmdlet.ShouldProcess($source, 'Stage driver')) {
            New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
            Copy-Item -LiteralPath $source -Destination $destination -Force
        }
    }
}

$infs = @(Get-ChildItem -LiteralPath $Staging -Recurse -Filter '*.inf' -ErrorAction SilentlyContinue)
if ($infs.Count -eq 0) {
    Write-Warning 'No .inf files staged. Put licensed driver packages in drivers/cache/.'
}

foreach ($inf in $infs) {
    if ($Mode -eq 'Online') {
        if ($PSCmdlet.ShouldProcess($inf.FullName, 'pnputil add-driver')) {
            & pnputil.exe /add-driver $inf.FullName /install
        }
    } else {
        if (-not $WindowsMount) { throw '-WindowsMount required for Offline mode' }
        if ($PSCmdlet.ShouldProcess($inf.FullName, 'dism add-driver')) {
            & dism.exe "/Image:$WindowsMount" /Add-Driver "/Driver:$($inf.FullName)"
        }
    }
    if ($LASTEXITCODE -ne 0) { throw "Driver install failed: $($inf.FullName)" }
}

$diag = $DiagEfiSource
if (-not $diag) { $diag = Join-Path $PSScriptRoot 'firmware/out/cupid-diag.efi' }
if (-not (Test-Path -LiteralPath $diag) -and (Get-Command clang -ErrorAction SilentlyContinue)) {
    $source = Join-Path $PSScriptRoot 'tools/cupid-diag/cupid_diag.c'
    New-Item -ItemType Directory -Force -Path (Split-Path $diag) | Out-Null
    & clang --target=aarch64-pc-windows-msvc -O2 -ffreestanding -fno-stack-protector `
        -nostdlib -fuse-ld=lld '-Wl,/subsystem:efi_application' '-Wl,/entry:efi_main' `
        '-Wl,/nodefaultlib' -o $diag $source
    if ($LASTEXITCODE -ne 0) { throw 'cupid-diag.efi build failed' }
}
if (Test-Path -LiteralPath $diag) {
    if ($PSCmdlet.ShouldProcess($diag, 'Stage cupid-diag.efi')) {
        Copy-Item -LiteralPath $diag -Destination (Join-Path $Staging 'cupid-diag.efi') -Force
    }
    Write-Host "Diagnostic app: $(Join-Path $Staging 'cupid-diag.efi')"
} else {
    Write-Warning 'cupid-diag.efi unavailable. Download the cupid-build-artifacts CI artifact or install clang.'
}

Write-Host "Staging: $Staging"
