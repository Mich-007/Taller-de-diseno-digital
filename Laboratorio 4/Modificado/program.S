    .section .text
    .globl _start
_start:
    # Inicial: x1 = 5, x2 = 3
    addi x1, x0, 5
    addi x2, x0, 3

    # R-type ops
    add  x3, x1, x2      # x3 = 8
    sub  x4, x1, x2      # x4 = 2
    and  x5, x1, x2
    or   x6, x1, x2
    xor  x7, x1, x2

    # shifts
    slli x8, x1, 1       # x8 = x1 << 1
    srli x9, x1, 1
    srai x10, x1, 1

    # slt / sltu
    slt  x11, x2, x1
    sltu x12, x2, x1

    # immediate arithmetic
    addi x13, x0, 10
    andi x14, x13, 1
    ori  x15, x13, 2
    xori x16, x13, 3
    slti x17, x2, 4
    sltiu x18, x2, 4

    # store x3 at RAM[0x1000] (Data memory base)
    la   x19, 0x1000
    sw   x3, 0(x19)

    # load back into x20
    lw   x20, 0(x19)

    # byte/halfword tests (sb/sh/lb/lh)
    addi x21, x0, 0x12
    sb   x21, 1(x19)     # store byte at offset 1
    lb   x22, 1(x19)     # load signed byte
    lbu  x23, 1(x19)     # load unsigned byte

    addi x24, x0, 0x1234
    sh   x24, 2(x19)
    lh   x25, 2(x19)
    lhu  x26, 2(x19)

    # branches
    beq  x20, x3, label_eq
    bne  x20, x3, label_ne
label_eq:
    addi x27, x0, 1
    jal  x0, after_jal   # jump over next
label_ne:
    addi x27, x0, 2

after_jal:
    # jalr test: set x5 = x1 + x2, then jump via jalr
    add  x28, x1, x2
    addi x29, x0, 8
    jalr x0, 0(x29)      # jump to address in x29 (demo; may wrap)

    # MMIO: write LED register (0x2004) with x3
    la   x30, 0x2004
    sw   x3, 0(x30)

    # MMIO: start timer (write to 0x2018)
    la   x31, 0x2018
    addi x1, x0, 100     # small limit for sim
    sw   x1, 0(x31)

    # loop forever
1:  jal x0, 1b
