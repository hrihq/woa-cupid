/*
 * Eight little/big clusters as exposed by SM8450 (1 + 3 + 4).
 * ponytail: no _PSS/_LPI yet; Windows sees cores but not DVFS.
 */
DefinitionBlock ("SSDT-CPU.aml", "SSDT", 2, "CU.PID", "CPUS", 1)
{
    Scope (\_SB)
    {
        Device (CPU0) { Name (_HID, "ACPI0007") Name (_UID, Zero) Name (_STA, 0x0F) }
        Device (CPU1) { Name (_HID, "ACPI0007") Name (_UID, One) Name (_STA, 0x0F) }
        Device (CPU2) { Name (_HID, "ACPI0007") Name (_UID, 0x02) Name (_STA, 0x0F) }
        Device (CPU3) { Name (_HID, "ACPI0007") Name (_UID, 0x03) Name (_STA, 0x0F) }
        Device (CPU4) { Name (_HID, "ACPI0007") Name (_UID, 0x04) Name (_STA, 0x0F) }
        Device (CPU5) { Name (_HID, "ACPI0007") Name (_UID, 0x05) Name (_STA, 0x0F) }
        Device (CPU6) { Name (_HID, "ACPI0007") Name (_UID, 0x06) Name (_STA, 0x0F) }
        Device (CPU7) { Name (_HID, "ACPI0007") Name (_UID, 0x07) Name (_STA, 0x0F) }
    }
}
