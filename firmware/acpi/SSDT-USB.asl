/*
 * SM8450 xHCI. ponytail: IDs are provisional until the device's own
 * ACPI/DT and the matching Windows driver are paired.
 */
DefinitionBlock ("SSDT-USB.aml", "SSDT", 2, "CU.PID", "USB0", 1)
{
    Scope (\_SB)
    {
        Device (USB0)
        {
            Name (_HID, "QCM8450")
            Name (_CID, "PNP0A08")
            Name (_UID, Zero)
            Name (_CCA, One)
            Name (_STA, 0x0F)
            Name (_DSD, Package () {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package () {
                    Package () { "compat", Package () { "qcom,sm8450-xhci" } }
                }
            })

            Name (_CRS, ResourceTemplate () {
                Memory32Fixed (ReadWrite, 0x0A000000, 0x10000)
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 0x9D }
            })
        }
    }
}
