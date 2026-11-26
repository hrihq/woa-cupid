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

## Upstream reference (SM8450)

`Project-Aloha/mu_aloha_platforms` is the Project Mu firmware tree that
already builds SM8450 targets:

```sh
git clone https://github.com/Project-Aloha/mu_aloha_platforms
cd mu_aloha_platforms
./build_setup.sh && pip install --upgrade -r pip-requirements.txt
./build_uefi.py --init
./build_uefi.py -d qcom-hdk8450        # reference target, not cupid
```

Its `Platforms/WaipioPkg/Device/qcom-hdk8450/ACPI/` AML set is the SM8450
starting point. `xiaomi-liuqin` is another SM8450 Xiaomi target, also without
DSDT support. Port from those; no `cupid` target exists upstream.

Install this repo's scaffold into that checkout:

```sh
ALOHA_ROOT=/path/to/mu_aloha_platforms \
  bash scripts/add-cupid-target.sh "$ALOHA_ROOT"
cd "$ALOHA_ROOT"
./build_uefi.py -p WaipioPkg -d xiaomi-cupid
```

The scaffold sets cupid's 1080x2400 framebuffer and SMBIOS values; driver
lists still reuse HDK8450 until vendor payloads are proven.
