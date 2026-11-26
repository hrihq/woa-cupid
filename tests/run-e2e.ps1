#!/usr/bin/env pwsh
# Tier 1-2 offline E2E on Windows. Safe without vendor blobs or hardware.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (Get-Command cargo -ErrorAction SilentlyContinue) {
    cargo test --workspace --quiet
    if ($LASTEXITCODE -ne 0) { throw "cargo test failed" }
    cargo run --quiet -p cupidctl -- verify-platform --root .
    if ($LASTEXITCODE -ne 0) { throw "verify-platform failed" }
    cargo run --quiet -p cupidctl -- verify-drivers --root .
    if ($LASTEXITCODE -ne 0) { throw "verify-drivers failed" }
}

if (Get-Command clang -ErrorAction SilentlyContinue) {
    New-Item -ItemType Directory -Force -Path 'firmware/out' | Out-Null
    clang --target=aarch64-linux-gnu -c firmware/cupid_bootshim.S -o firmware/out/cupid_bootshim.elf `
        -DREQUIRES_KERNEL_HEADER=1 -DFD_BASE=0xA7100000 -DFD_SIZE=0x300000
    if ($LASTEXITCODE -ne 0) { throw "BootShim compile failed" }
} else {
    Write-Warning 'clang missing; BootShim compile skipped'
}

Write-Output 'E2E_TIER1_2_PASS'
