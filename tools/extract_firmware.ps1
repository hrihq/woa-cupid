#!/usr/bin/env pwsh
# Extract vendor UEFI binaries from xbl.img using UEFIReader
[CmdletBinding()]
param(
    [string] $XblImage = (Join-Path $PSScriptRoot '../assets/private/xbl.img'),
    [string] $OutputDir = (Join-Path $PSScriptRoot '../assets/private/Binaries/cupid'),
    [string] $UefiReaderPath = (Join-Path $PSScriptRoot 'bin/UEFIReader.exe')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $XblImage -PathType Leaf)) {
    Write-Error "xbl.img not found at $XblImage. Please copy xbl.img from device first."
    exit 1
}

if (-not (Test-Path -LiteralPath $UefiReaderPath -PathType Leaf)) {
    Write-Error "UEFIReader.exe not found at $UefiReaderPath."
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Host "Extracting UEFI payloads from $XblImage..."
& $UefiReaderPath $XblImage $OutputDir

$infCount = @(Get-ChildItem -LiteralPath $OutputDir -Recurse -Filter '*.inf' -ErrorAction SilentlyContinue).Count
Write-Host "Extraction complete: $infCount .inf files generated in $OutputDir"
