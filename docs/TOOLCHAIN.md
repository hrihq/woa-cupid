# Toolchain (Windows dev host)

| Component | Install hint |
|---|---|
| Git | `winget install --id Git.Git -e` |
| Python 3.11+ | `winget install --id Python.Python.3.11 -e` |
| Rust / cargo | `winget install --id Rustlang.Rustup -e` |
| LLVM / clang / lld | `winget install --id LLVM.LLVM -e` |
| iasl | `choco install iasl -y` |
| VS Build Tools | `winget install --id Microsoft.VisualStudio.2022.BuildTools -e` |
| GnuMake | `choco install make -y` |
| WDK (M3) | https://learn.microsoft.com/windows-hardware/drivers/download-the-wdk |
| Windows ADK / DISM | https://learn.microsoft.com/windows-hardware/get-started/adk-install |
| QEMU + AAVMF | Linux CI only: `apt install qemu-system-arm qemu-efi-aarch64` |

Check: `python --version`, `cargo --version`, `clang --version`, `iasl -v`.
