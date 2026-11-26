# Xiaomi 12 (`cupid`) Device Tree Blob Guide

- Device codename: `cupid`
- SoC: SM8450 (`waipio`)
- `msm-id = 457` (`0x1c9`)
- Expected user-supplied DTB path: `Resources/DTBs/cupid.dtb` (not redistributed)
- Extraction inputs: `UEFIReader` XBL DXE dump (`Binaries/cupid/`) and `Panel_L3_42_02_0a_amoled_dsc_cmd.xml`.
- Primary boot image format: `header_version = 4` (`append_dtb = true`, `pagesize = 4096`).
- Fallback boot image format: `header_version = 2` (`pagesize = 2048`, standalone DTB section).
