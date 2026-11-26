# `xiaomi-cupid` target scaffold

Scaffold for `Project-Aloha/mu_aloha_platforms`
`Platforms/WaipioPkg/Device/xiaomi-cupid`. Derived from `qcom-hdk8450`;
no vendor binaries included. `scripts/add-cupid-target.sh` copies this into
an Aloha checkout.

Build after assets are present:

```sh
./build_uefi.py -p WaipioPkg -d xiaomi-cupid
```

`!include` lines reuse the HDK8450 driver lists; override the device-specific
ones only after proving them on cupid.
