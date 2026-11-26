#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [string] $AssetRoot = (Join-Path $PSScriptRoot '../assets/private')
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $AssetRoot -ErrorAction SilentlyContinue).Path
if (-not $root) {
    Write-Output 'ASSETS_MISSING: asset directory absent (see docs/ASSET_COLLECTION.md)'
    exit 1
}

function Get-HeadHex([string] $Path, [int] $Count) {
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $buffer = New-Object byte[] $Count
        $read = $stream.Read($buffer, 0, $Count)
        return (($buffer[0..($read - 1)] | ForEach-Object { $_.ToString('X2') }) -join '')
    } finally {
        $stream.Dispose()
    }
}

$files = @('xbl.img', 'xbl_config.img', 'abl.img', 'cupid.dtb', 'install.wim')
$missing = @()
foreach ($name in $files) {
    $path = Join-Path $root $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0) {
        $missing += $name
        continue
    }
    $size = (Get-Item -LiteralPath $path).Length
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    Write-Output "$name : $size bytes : sha256=$hash"
}

if ($missing.Count -eq 0) {
    $xblHead = Get-HeadHex (Join-Path $root 'xbl.img') 4
    $dtbHead = Get-HeadHex (Join-Path $root 'cupid.dtb') 4
    $wimHead = Get-HeadHex (Join-Path $root 'install.wim') 8
    if ($xblHead -ne '7F454C46') { Write-Output "WARN: xbl.img head=$xblHead (expected ELF 7F454C46)" }
    if ($dtbHead -ne 'D00DFEED') { $missing += 'cupid.dtb (bad DTB magic)' }
    if ($wimHead -ne '4D5357494D000000') { $missing += 'install.wim (bad WIM magic)' }

    $binaries = Join-Path $root 'Binaries/cupid'
    $inf = @(Get-ChildItem -LiteralPath $binaries -Recurse -Filter '*.inf' -ErrorAction SilentlyContinue)
    if ($inf.Count -eq 0) {
        $missing += 'Binaries/cupid/*.inf (UEFIReader output)'
    } else {
        Write-Output "Binaries/cupid : $($inf.Count) .inf payloads"
    }
}

if ($missing.Count -gt 0) {
    Write-Output "ASSETS_MISSING: $($missing -join ', ')"
    exit 1
}
Write-Output 'ASSET_READY'
