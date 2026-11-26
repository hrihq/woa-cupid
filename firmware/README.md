# Firmware

| File | Role |
|---|---|
| `cupid_bootshim.S` | canonical BootShim source (FD copy + branch to `FD_BASE`) |
| `config/cupid.toml` | FD base/size, header version 4, dtb append |
| `acpi/*.asl` | DSDT + CPU/USB/storage/display SSDTs |
| `edk2/` | minimal EDK2 overlay (DEC/DSC/FDF/INF) |
| `out/` | generated artifacts: `cupid_bootshim.elf/.bin`, `*.aml`, `cupid-diag.efi`, QEMU log |

`cupid_bootshim.efi` is **not** committed: the BootShim is a raw ABL payload,
not a standalone UEFI application. Build output is the raw binary plus AML from
`build.sh`; download release/CI artifacts instead of tracking binaries.

Build: `bash firmware/build.sh` (needs `clang`, `llvm-objcopy`, `iasl`).
See `../docs/BUILD_AND_VERIFY.md`.
