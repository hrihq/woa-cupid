# Drivers

No driver binaries are committed. `manifest.json` is the inventory; place
licensed packages in `drivers/cache/` (gitignored) or attach them as a GitHub
release, then point `setup_cupid.ps1 -DriverRoot` at that directory.

`msm8998` (Snapdragon 835) is the wrong chipset for cupid. Target is
**SM8450 / waipio**. Driver sources are WOA-Project's Snapdragon 8 Gen 1 BSP
and Qualcomm reference packages; none are proven on cupid yet.
