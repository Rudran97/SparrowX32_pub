# SparrowX32 Fast Interrupt

SparrowX32 introduces a fast interrupt mode that enables context switching without requiring software to save and restore general-purpose registers (`x0`–`x31`).

When a fast interrupt occurs, the hardware automatically saves the contents of the general-purpose registers into shadow registers before transferring control to the interrupt handler. Upon execution of the `mret` instruction, the original register values are restored automatically.

This mechanism eliminates software overhead and enables low-latency interrupt handling.

Unlike software, timer, and external interrupts, fast interrupts do not have individual enable bits in the `mie` CSR. Instead, fast interrupts are enabled whenever global interrupts are enabled (`mstatus.MIE = 1`).

The `pil_fast_irq` input signal of the `svx32_core` top-level module is used to trigger a fast interrupt.

When `mstatus.MIE = 1` and `pil_fast_irq` is asserted:
* The core enters fast interrupt mode.
* General-purpose registers are saved into shadow registers.
* Control is transferred to the interrupt handler based on `mtvec.MODE`.

Refer to [`CSR.md`](../docs/CSR.md) for details on `mtvec` configuration.