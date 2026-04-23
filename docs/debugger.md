# SparrowX32 Debugger

SparrowX32 supports a modified abstract command-based debugging mechanism. When a debug request is issued, or a trigger condition (e.g., instruction address match) occurs, the core halts execution and enters debug mode. While in debug mode, the pipeline remains stalled until a resume request is received.

## Debug Interface between Debug Module and Core

| Signal                | Direction | Description                                                       |
| :---                  | :---      | :---                                                              |
| pil_debug_haltreq     | Input     | Request to enter debug mode (from debug module to core).          |
| pil_debug_resumereq   | Input     | Request to resume execution (from debug module to core).          |
| pol_debug_havereset   | Output    | Asserted while the core is in reset.                              |
| pol_debug_running     | Output    | Asserted when the core is executing normally (not in debug mode). |
| pol_debug_halted      | Output    | Asserted when the core is halted in debug mode.                   |

## Debug Mode Interface for CSR and GPR access

This interface allows the debug module to access general-purpose registers (`x0`–`x31`) and CSRs.

| Signal                | Direction | Description                                                                                       |
| :---                  | :---      | :---                                                                                              |
| pil_debug_regreq      | Input     | Request to access registers or CSRs.                                                              |
| piv_debug_regno       | Input     | Register address: `0x000 - 0x01f` for GPRs, `0x300 - 0xfff` for CSRs.                             |
| pil_debug_write       | Input     | When asserted, the debug module performs a write to the selected register.                        |
| piv_debug_wdata       | Input     | Data to be written.                                                                               |
| pov_debug_rdata       | Output    | Data read from the selected register.                                                             |
| pol_debug_ack         | Output    | Asserted by the core for one clock cycle when the current register access completes successfully. |
| pol_debug_err         | Output    | Asserted by the core for one clock cycle if the access fails.                                     |
| pov_debug_pc_retired  | Output    | Address of the last retired instruction.                                                          |

## Debug Flow

The debug module can configure features such as single-step execution and hardware breakpoints as follows:

### Single step

* After entering debug mode, set `dcsr.STEP = 1`.

* Assert `pil_debug_resumereq` for one clock cycle.

* The core executes one instruction and re-enters debug mode.

* To disable single0-step, clear `dcsr.STEP`.

**Note:** Interrupts are inhibited during single-step execution. Normal interrupt handling resumes once single-step mode is disabled.

### Hardware breakpoints

* Disable single-step mode (`dcsr.STEP = 0`).

* Select the trigger module using the `tselect` register. From here on any further operation on `tdata1` and `tdata2` register would only affect the selected breakpoint.

    * Set `tdata1.EXECUTE` to `1` to enable trigger on instruction address match.

    * Write the value of the address to match against in `tdata2`.

* Assert `pil_debug_resumereq` for one clock cycle. The core continues normal execution until a trigger match occurs, at which point it enters debug mode.

* To disable the breakpoint, clear `tdata1.EXECUTE`.