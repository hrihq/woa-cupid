# Install Windows (PoC)

**Warning:** flashing unofficial firmware can brick the phone. Back up
`xbl`, `abl`, `xbl_config` and all persistent partitions first. Have a
recovery path (EDL / stock ROM) before continuing.

1. Build or download `firmware/out/cupid_bootshim.bin` and the AML tables.
2. Assemble the boot image: header v4, gzip kernel, append `cupid.dtb`,
   then BootShim + UEFI FD at `0xA7100000`.
3. Validate the image and AML plan first (M3 dry-run; writes nothing):

   ```sh
   cargo run -q -p cupidctl -- flash-image --image firmware/out/boot.img --slot a
   cargo run -q -p cupidctl -- apply-acpi --aml firmware/out/DSDT.aml
   ```

   `--execute` is intentionally refused. Flash with your own fastboot/EDL
   tool. Keep the other slot stock.
4. Boot once without drivers; confirm serial/output from `cupid-diag.efi`.
5. On a Windows 11 ARM64 image, stage drivers:

   ```powershell
   .\setup_cupid.ps1 -Mode Offline -WindowsMount C:\mount -DriverRoot .\drivers\cache
   # or, on a running Windows install:
   .\setup_cupid.ps1 -Mode Online -DriverRoot .\drivers\cache
   ```

6. Check installed drivers with `Get-WindowsDriver -Online` (or `-Path` for
   an offline mount). Re-deploy from `drivers/cache/`; nothing is bundled.

Known gaps: no device-specific GPU/audio/Wi-Fi/camera binaries, no validated
ACPI MMIO bases, no camera/ISP power sequencing. Expect failures.
