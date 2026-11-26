# Build & verify

## Windows host

```powershell
winget install --id Rustlang.Rustup -e
winget install --id LLVM.LLVM -e
choco install iasl -y
cargo test --workspace
cargo run -q -p cupidctl -- verify-platform --root .
cargo run -q -p cupidctl -- verify-drivers --root .
.\tests\run-e2e.ps1
```

## Linux / CI host

```sh
sudo apt-get install -y acpica-tools clang lld llvm qemu-system-arm qemu-efi-aarch64 mtools
cargo test --workspace
bash tests/run-e2e.sh          # BootShim + AML + cupidctl
bash firmware/build.sh         # writes firmware/out/*
```

## Full firmware

Requires a Mu-Silicium checkout with the owner's `Binaries/cupid` and
`Resources/DTBs/cupid.dtb`:

```sh
MU_SILICIUM_ROOT=/path/to/Mu-Silicium bash scripts/integrate-mu-silicium.sh
# then build the platform with Mu-Silicium's build_uefi.py / EDK2 build
```

`cupid_bootshim.efi` and AML are build artifacts. Download them from the CI
run (`cupid-build-artifacts`) or a GitHub release; they are intentionally
gitignored.
