_Head:
#ifdef REQUIRES_KERNEL_HEADER
    adr x1, _Payload
    b _Start

    .quad FD_BASE
    .quad FD_SIZE
    .quad 0
    .quad 0
    .quad 0
    .quad 0
    .ascii "ARM\x64"
    .long 0
#endif

_Start:
    mov x4, x1
    ldr x5, _StackBase
    cmp x4, x5
    beq _Entry

    ldr x6, _StackSize

_CopyLoop:
    ldp x2, x3, [x4], #16
    stp x2, x3, [x5], #16
    subs x6, x6, #16
    b.ne _CopyLoop

    ldr x5, _StackBase

_Entry:
    br x5

_Dead:
    b _Dead

.text
.align 4

_StackBase:
    .quad FD_BASE

_StackSize:
    .quad FD_SIZE

_Payload:
