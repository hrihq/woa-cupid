# Asset collection (owner-supplied only)

Nothing here downloads firmware from someone else's device. Use **your own**
Xiaomi 12. Unlocking the bootloader may wipe the phone. Back up first and keep
an EDL/stock-ROM restore path.

## Private layout

Put assets in `assets/private/` (gitignored):

```
assets/private/
  xbl.img                 vendor UEFI volume source
  xbl_config.img
  abl.img
  cupid.dtb               SM8450 Xiaomi 12 device tree
  install.wim             Windows 11 ARM64 install image
  Binaries/cupid/         .inf payloads extracted with UEFIReader
  drivers/                licensed driver packages (optional)
```

## 1. Backup partitions

From a rooted Android session, copy the phone's own partitions:

```sh
adb shell su -c 'dd if=/dev/block/by-name/xbl of=/sdcard/xbl.img'
adb shell su -c 'dd if=/dev/block/by-name/xbl_config of=/sdcard/xbl_config.img'
adb shell su -c 'dd if=/dev/block/by-name/abl of=/sdcard/abl.img'
adb pull /sdcard/xbl.img assets/private/xbl.img
adb pull /sdcard/xbl_config.img assets/private/xbl_config.img
adb pull /sdcard/abl.img assets/private/abl.img
```

If Android is unavailable, use your EDL tool (`fh_loader`/`eds`) with the
authorized programmer for this device. Keep both slots' backups.

## 2. Extract vendor UEFI payloads

`xbl.img` contains the OEM UEFI volume. Feed it to
`https://github.com/MSMTools/UEFIReader` and write the generated `.inf`
payloads to `assets/private/Binaries/cupid/`. Do not commit them.

`Project-Aloha/mu_aloha_platforms` uses `Binaries/` as a submodule for the
same purpose; its `qcom-hdk8450` set is a reference, **not** a cupid substitute.

## 3. Device tree

Use the cupid DTB from `sm8450-mainline` (`sm8450-xiaomi-cupid.dtb`) or the
phone's own boot image. Verify it decodes:

```sh
dtc -I dtb -O dts assets/private/cupid.dtb -o /tmp/cupid.dts
```

Cross-check `Memory32Fixed` bases and IRQs in `firmware/acpi/*.asl` against
this DTB before any boot attempt.

## 4. Windows image

Obtain a legitimate Windows 11 ARM64 ISO, mount it, copy `sources/install.wim`
to `assets/private/install.wim`. Record its SHA-256 privately.

## 5. Validate

```powershell
./tests/check-assets.ps1 -AssetRoot ./assets/private
```

Script only checks presence, magic bytes, non-empty files and `.inf` payloads.
It prints SHA-256 values for your records. It never flashes or modifies the
device. `Ready for boot-to-Windows` requires all checks green **and** a
restore path.
