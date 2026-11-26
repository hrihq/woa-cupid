/*
 * Cupid (SM8450) DSDT skeleton.
 * ponytail: declarative devices only; power/resources are supplied by the
 *           owner's vendor ACPI/DT once available. Upgrade path: replace
 *           with the device's own DSDT from UEFIReader before shipping.
 */
DefinitionBlock ("DSDT.aml", "DSDT", 2, "CU.PID", "CUPID", 1)
{
    Scope (\_SB)
    {
        Device (PWRB)
        {
            Name (_HID, "PNP0C0C")  // Power Button
            Name (_UID, One)
            Name (_STA, 0x0F)
        }

        Device (CPU0)
        {
            Name (_HID, "ACPI0007")
            Name (_UID, Zero)
            Name (_STA, 0x0F)
        }

        Method (_INI, 0, NotSerialized)
        {
            Store (One, \_SB.PCI0.B0LD)
        }
    }

    Scope (\_SB.PCI0)
    {
        Name (B0LD, One)
    }
}
