/*
 * UFS HC. ponytail: MMIO base and IRQ are the SM8450 defaults, not
 * measured on cupid; replace from the device DTB before flashing.
 */
DefinitionBlock ("SSDT-STORAGE.aml", "SSDT", 2, "CU.PID", "UFS0", 1)
{
    Scope (\_SB)
    {
        Device (UFS0)
        {
            Name (_HID, "QCM8450")
            Name (_CID, "PNP0A03")
            Name (_UID, Zero)
            Name (_CCA, One)
            Name (_STA, 0x0F)
            Name (_DSD, Package () {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package () {
                    Package () { "compat", Package () { "qcom,sm8450-ufshc" } }
                }
            })

            Name (_CRS, ResourceTemplate () {
                Memory32Fixed (ReadWrite, 0x01D84000, 0x10000)
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 0x86 }
            })
        }
    }
}
