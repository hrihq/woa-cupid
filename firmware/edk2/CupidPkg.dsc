[Defines]
  PLATFORM_NAME                  = CupidPkg
  PLATFORM_GUID                  = 6F1E7B9A-9C2D-4B11-8D53-8450CUPID001
  PLATFORM_VERSION               = 0.1
  DSC_SPECIFICATION              = 0x00010005
  OUTPUT_DIRECTORY               = Build/CupidPkg
  SUPPORTED_ARCHITECTURES        = AARCH64
  BUILD_TARGETS                  = DEBUG|RELEASE
  SKUID_IDENTIFIER               = DEFAULT
  FLASH_DEFINITION               = CupidPkg/CupidPkg.fdf

[PcdsFixedAtBuild]
  gCupidPkgTokenSpaceGuid.PcdUefiFdBase|0xA7100000|UINT64|0x00000001
  gCupidPkgTokenSpaceGuid.PcdUefiFdSize|0x00300000|UINT64|0x00000002

[Components.AARCH64]
  CupidPkg/BootShim/CupidBootShim.inf

[BuildOptions]
  GCC:*_*_AARCH64_ASM_FLAGS = -DREQUIRES_KERNEL_HEADER=1 -DFD_BASE=0xA7100000 -DFD_SIZE=0x300000
