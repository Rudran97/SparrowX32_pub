# SparrowX32 Control and Status Registers

SparrowX32 core implements the following Control and Status Registers (CSRs) as listed in the following table in accordance with the RISC-V Privileged Specification version 1.13 and RISC-V Debug Specification version 1.0.

| CSR Name   | Address      | Privilege | Access | Description                                  |
| :---       | :---         | :---      | :---   | :---                                         |
| MSTATUS    | 0x300        | MRW       | WARL   | Machine status register                      |
| MISA       | 0x301        | MRW       | WARL   | ISA and extensions register                  |
| MIE        | 0x304        | MRW       | WARL   | Machine interrupt enable register            |
| MTVEC      | 0x305        | MRW       | WARL   | Trap-handler base address and mode register  |
| MSCRATCH   | 0x340        | MRW       | RW     | Machine scratch register                     |
| MEPC       | 0x341        | MRW       | WARL   | Machine exception program counter register   |
| MCAUSE     | 0x342        | MRW       | WLRL   | Machine trap cause register                  |
| MTVAL      | 0x343        | MRW       | WLRL   | Machine trap value register                  |
| MIP        | 0x344        | MRW       | WARL   | Machine Interrupt Pending register           |
| TSELECT    | 0x7A0        | MRW       | WARL   | Debug trigger register select                |
| TDATA1     | 0x7A1        | MRW       | WARL   | Debug trigger first data register            |
| TDATA2     | 0x7A2        | MRW       | RW     | Debug trigger second data register           |
| TDATA3     | 0x7A3        | MRW       | RW     | Debug trigger third data register            |
| DCSR       | 0x7B0        | DRW       | Debug  | Debug control and status register            |
| DPC        | 0x7B1        | DRW       | Debug  | Debug program counter register               |
| DSCRATCH0  | 0x7B2        | DRW       | Debug  | Debug scratch register 0                     |
| DSCRATCH1  | 0x7B3        | DRW       | Debug  | Debug scratch register 1                     |
| MINSTRET   | 0xB02        | MRW       | RW     | Machine instruction retired counter register |
| MVENDORID  | 0xF11        | MRO       | RO     | Vendor ID                                    |
| MARCHID    | 0xF12        | MRO       | RO     | Architecture ID                              |
| MIMPID     | 0xF13        | MRO       | RO     | Implementation ID                            |
| MHARTID    | 0xF14        | MRO       | RO     | Hardware thread ID                           |

## Machine Status Register (mstatus)

Address: `0x300`

Reset  : `0x0000_0000`

The `mstatus` CSR is a WARL register. To enable interrupts globally, `mstatus.MIE` must be set to `1`.

Only implemented fields are shown. Unimplemented fields default to `0`.

| Bit  | Access | Description                                                                                       |
| :--- | :---   | :---                                                                                              |
| 7    | RW     | Previous interrupt enable (`MPIE`): holds the interrupt enable before entering exception handler. |
| 3    | RW     | Interrupt enable (`MIE`): If set, interrupts are globally enabled.                                |

When an exception/interrupt occurs, `mstatus.MPIE` is set to `mstatus.MIE` and `mstatus.MIE` is set to `0`. Inside the exception handler, when `mret` instruction is executed, the value of `mstatus.MPIE` is stored back to `mstatus.MIE` and `mstatus.MPIE` is set to `1`.

## Machine ISA Register (misa)

Address: `0x301`

The `misa` CSR is a WARL register that is effectively read-only and reflects the supported ISA configuration.

Some of the `misa` values are as follows:

| Value       | Description                     |
| :---        | :---                            |
| 0x4000_0100 | XLEN = 32, base ISA = RV32[I]   |
| 0x4000_1100 | XLEN = 32, base ISA = RV32I[M]  |
| 0x4000_1104 | XLEN = 32, base ISA = RV32IM[C] |

## Machine Interrupt-Enable Register (mie)

Address: `0x304`

Reset  : `0x0000_0000`

The `mie` CSR is a WARL register to enable/disable individual local interrupts. Interrupts are enabled by setting them to `1`. On reset, all interrupts are disabled.

Only implemented fields are shown. Unimplemented fields default to `0`.

| Bit  | Access | Description                                                                |
| :--- | :---   | :---                                                                       |
| 11   | RW     | External interrupt enable (`MEIE`): If set, external interrupt is enabled. |
| 7    | RW     | Timer interrupt enable (`MTIE`): If set, timer interrupt is enabled.       |
| 3    | RW     | Software interrupt enable (`MSIE`): If set, software interrupt is enabled. |

## Machine Trap-Vector Base-Address Register (mtvec)*

Address: `0x305`

Reset  : `0x0000_0000`

The `mtvec` CSR is a WARL register that holds the trap-vector base address and mode.

Only implemented fields are shown. Unimplemented fields default to `0`.

| Bit    | Description                                                                                                                |
| :---   | :---                                                                                                                       |
| 31:2   | `BASE`: Trap-vector base address. Exception address is always aligned to 64 bytes i.e., `mtvec[5:2]` is always set to `0`. |
| 1:0    | `MODE`: Additional alignment constraints on the `BASE` value.                                                              |

| MODE | Name     | Description                                                                                                            |
| :--- | :---     | :---                                                                                                                   |
| 0    | Direct   | All traps set `pc` to `BASE`.                                                                                          |
| 1    | Vectored | Interrupts set `pc` to `BASE + 4 x cause` and Exception set `pc` to `BASE`.                                            |
| 2    | Fast IRQ | If `mcause[4]` is `1` then `pc` is set to `piv_fast_irq_vect`. All other interrupts and exceptions set `pc` to `BASE`. |

## Machine Scratch Register (mscratch)

Address: `0x340`

Reset  : `0x0000_0000`

The `mscratch` CSR is a read/write register dedicated for use in machine mode.

## Machine Exception Program Counter Register (mepc)

Address: `0x341`

Reset  : `0x0000_0000`

The `mepc` CSR is a read/write register. The low bit of `mepc[0]` is always zero. When an exception is encountered, the current program counter is saved in `mepc`. When the `mret` instruction is executed, the current program counter is replaced by `mepc`.

## Machine Cause Register (mcause)

Address: `0x342`

Reset  : `0x0000_0000`

The `mcause` CSR is a WLRL register. When an exception is encountered, the exception code is stored in `mcause`.

Only implemented fields are shown. Unimplemented fields default to `0`.

| Bit  | Access | Description                                                   |
| :--- | :---   | :---                                                          |
| 31   | R      | `Interrupt`: When `1`, the cause of the trap is an interrupt. |
| 30:0 | RW     | `Exception Code`: WLRL. Exception code of the trap.           |

The core supports the following traps:

| Interrupt | Exception Code | Description                                                                            |
| ---:      | ---:           | :---                                                                                   |
| 1         | 3              | Machine software interrupt.                                                            |
| 1         | 7              | Machine timer interrupt.                                                               |
| 1         | 11             | Machine external interrupt.                                                            |
| 1         | `>=16`         | Fast IRQ. For fast interrupts, the lower bits (`mcause[3:0]`) encode the interrupt ID. |
| 0         | 0              | Instruction address misaligned exception.                                              |
| 0         | 2              | Illegal instruction exception.                                                         |
| 0         | 3              | Environment break.                                                                     |
| 0         | 11             | Environment call from M-mode.                                                          |

## Machine Trap Value Register (mtval)*

Address: `0x343`

Reset  : `0x0000_0000`

The `mtval` CSR is a WLRL register. When an exception is encountered, the `mtval` register stores the zero-extended lower 16 bits of the faulting instruction (non-standard behavior). This value can be used by the software to determine alignment of the faulting instruction.

## Machine Interrupt-Pending Register (mip)

Address: `0x344`

Reset  : `0x0000_0000`

The `mip` CSR is a WARL register containing information of pending interrupts. If global interrupt `mstatus.MIE` is set to `1` and the individual local interrupt is enabled in the `mie` register, then the corresponding pending interrupt in `mip` register would trigger an interrupt.

Only implemented fields are shown. Unimplemented fields default to `0`.

| Bit  | Access | Description                                                                 |
| :--- | :---   | :---                                                                        |
| 11   | RO     | External interrupt pending (`MEIP`): If set, external interrupt is pending. |
| 7    | RO     | Timer interrupt pending (`MTIP`): If set, timer interrupt is pending.       |
| 3    | RO     | Software interrupt pending (`MSIP`): If set, software interrupt is pending. |

## Trigger Select Register (tselect)

Address: `0x7A0`

Reset  : `0x0000_0000`

Accessible in Debug mode and M-mode. Writing to `tselect` register would select the corresponding trigger module. Each trigger module has its own `tdata1`, `tdata2` and `tdata3` registers. Currently eight trigger modules are supported i.e., valid values for `tselect` are `0` and `7`.

For more info follow RISC-V Debug Specification version 1.0.

## Trigger Data1 Register (tdata1)

Address: `0x7A1`

Reset  : `0x2800_1000`

Accessible in Debug mode and M-mode. `tdata1` is primarily used to enable or disable trigger on instruction address match.
Software can still access and modify `tdata1`, as it is not strictly implemented as a debug-only register. However, this is not the intended use.

Only implemented fields are shown. The unimplemented fields are hardwired to the default value specified in the debug specification.

| Bit  | Access | Description                                        |
| :--- | :---   | :---                                               |
| 2    | RW     | `execute`: Enable matching on instruction address. |

## Trigger Data2 Register (tdata2)

Address: `0x7A2`

Reset  : `0x0000_0000`

Accessible in Debug mode and M-mode. `tdata2` holds the address of the instruction to match against for a trigger.
Software can still access and modify `tdata2`, as it is not strictly implemented as a debug-only register. However, this is not the intended use.

## Trigger Data3 Register (tdata3)

Address: `0x7A3`

Reset  : `0x0000_0000`

`tdata3` is not implemented currently.

## Debug Control and Status Register (dcsr)

Address: `0x7B0`

Reset  : `0x4000_0003`

Accessible only in Debug mode. An illegal instruction exception would be raised if software tries to access `dcsr`.

Only implemented fields are shown. The unimplemented fields are hardwired to the default values specified in the debug specification.

| Bit  | Access | Description                                        |
| :--- | :---   | :---                                               |
| 15   | RW     | `ebreakm`: If set to `1`, `ebreak` enters debug mode. If set to `0`, `ebreak` in M-mode behaves as described in privilege mode. |
| 8:6  | RO     | `cause`: `1 = ebreak`, `2 = trigger`, `3 = halt request`, `4 = step`. |
| 2    | RW     | `step`: When set and not in debug mode, the core executes single instruction and then enters debug mode. |

## Debug PC Register (dpc)

Address: `0x7B1`

Reset  : `0x0000_0000`

Accessible only in Debug mode. An illegal instruction exception would be raised if software tries to access `dpc`.

When entering debug mode, `dpc` is updated with the next instruction to be executed. When resuming, the core's PC is updated to the address stored in `dpc`.

## Debug Scratch Register 0 (dscratch0)

Address: `0x7B2`

Reset  : `0x0000_0000`

Accessible only in Debug mode. An illegal instruction exception would be raised if software tries to access `dscratch0`.

## Debug Scratch Register 1 (dscratch1)

Address: `0x7B3`

Reset  : `0x0000_0000`

Accessible only in Debug mode. An illegal instruction exception would be raised if software tries to access `dscratch1`.

## Machine Instructions-Retired Counter (minstret)

Address: `0xB02`

Reset  : `0x0000_0000`

`minstret` holds the number of instructions executed at the point of reading the register.

Note that `minstreth` register is not implemented.

## Machine Vendor ID Register (mvendorid)

Address: `0xF11`

Reset  : `0x0000_0000`

Refer to RISC-V Privileged Specification for more information on this register.

## Machine Architecture ID Register (marchid)

Address: `0xF12`

Reset  : `0x0600_A033`

Refer to RISC-V Privileged Specification for more information on this register.

Note that the reset value of the register here is randomly chosen. The value can be modified in [options_pkg.vhd](../rtl/options_pkg.vhd) file.

## Machine Implementation ID Register (mimpid)

Address: `0xF13`

`mimpid` holds the version of the processor implementation.

## Hart ID Register (mhartid)

Address: `0xF14`

Reset  : `0x0000_0001`

Refer to RISC-V Privileged Specification for more information on this register.

Note that the reset value of the register here is randomly chosen. The value can be modified in [options_pkg.vhd](../rtl/options_pkg.vhd) file.

## Notes

`mtval` and `mtvec` deviate from the standard RISC-V specification.

* `mtvec` introduces a Fast IRQ mode, which is not part of the standard specification.
* `mtval` is used to distinguish between `c.ebreak` and `ebreak`.
