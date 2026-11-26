/*
 * MDSS/framebuffer. Address matches cupid's scanned-out splash buffer
 * used by the BootShim probe (1080x2400, 32bpp).
 * ponytail: no backlight/brightness yet.
 */
DefinitionBlock ("SSDT-DISPLAY.aml", "SSDT", 2, "CU.PID", "GDP0", 1)
{
    Scope (\_SB)
    {
        Device (GDP0)
        {
            Name (_HID, "QCM8450")
            Name (_UID, Zero)
            Name (_STA, 0x0F)
            Name (_DSD, Package () {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package () {
                    Package () { "compat", Package () { "qcom,sm8450-mdss" } }
                }
            })

            Name (_CRS, ResourceTemplate () {
                Memory32Fixed (ReadWrite, 0x0AE00000, 0x20000)
                Memory32Fixed (ReadWrite, 0x0B800000, 0x02000000)
            })
        }
    }
}
