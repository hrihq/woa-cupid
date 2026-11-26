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
    }
}
