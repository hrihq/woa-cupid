/* Minimal UEFI aarch64 app used only for the QEMU boot smoke test.
 * ponytail: marker app, not a driver-loading diagnostic. Upgrade path:
 *           replace with a real DriverStore query app once WDK is available.
 */
typedef unsigned long long UINTN;

typedef struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;
struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
    UINTN Reset;
    UINTN OutputString;
    UINTN TestString;
    UINTN QueryMode;
    UINTN SetMode;
    UINTN SetAttribute;
    UINTN ClearScreen;
    UINTN SetCursorPosition;
    UINTN EnableCursor;
    UINTN CursorVisible;
    void *Mode;
};

typedef struct {
    UINT64 Signature;
    UINT32 Revision;
    UINT32 HeaderSize;
    UINT32 CRC32;
    UINT32 Reserved;
    void *FirmwareVendor;
    UINT32 FirmwareRevision;
    UINT32 Reserved2;
    void *ConsoleInHandle;
    void *ConIn;
    void *ConsoleOutHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *ConOut;
} EFI_SYSTEM_TABLE;

typedef UINTN (*EFI_OUTPUT_STRING)(EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *, const unsigned short *);

UINTN efi_main(void *ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    EFI_OUTPUT_STRING out;
    (void)ImageHandle;
    if (SystemTable == 0 || SystemTable->ConOut == 0)
        return 1;
    out = (EFI_OUTPUT_STRING)SystemTable->ConOut->OutputString;
    out(SystemTable->ConOut, L"CUPID_DIAG_OK\r\n");
    for (;;) { }
    return 0;
}
