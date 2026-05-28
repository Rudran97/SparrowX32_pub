# Pipeline Structure

The SparrowX32 core uses a five-stage pipeline to improve instruction throughput and reduce overall execution latency.

The pipeline stages are as follows:

---

## Instruction Fetch

The Instruction Fetch (IF) stage contains the prefetch buffer. This buffer fetches instructions from instruction memory and forwards them to the next pipeline stage.

Optionally, if the Compressed (`C`) extension is enabled, the prefetch buffer forwards the instruction to the compressed instruction decoder module, which determines whether the fetched instruction is a valid compressed instruction.

The following table shows the instruction memory interface of the core:

| Signal                | Direction | Description                                                                                    |
| :---                  | :---      | :---                                                                                           |
| `pil_fetch_mem_valid` | Input     | `1 = piv_fetch_mem_rdata is valid` (from memory controller to core).                           |
| `pil_fetch_mem_ack`   | Input     | `1 = Memory controller acknowledged the request of the core` (from memory controller to core). |
| `pol_fetch_mem_req`   | Output    | `1 = Core requests a new instruction fetch`.                                                   |
| `piv_fetch_mem_rdata` | Input     | Instruction data fetched from memory (from memory controller to core).                         |
| `pov_fetch_mem_addr`  | Output    | Instruction fetch address (from core to memory controller).                                    |

The core supports two instruction fetch modes:

### Single-Cycle Fetch

In this mode, the core expects a new instruction every clock cycle. The prefetch buffer aligns the incoming data depending on whether the previous instruction was compressed.

This mode reduces hardware complexity and system latency by simplifying the instruction memory interface. The memory controller can be connected directly to the core without requiring a dedicated memory bus.

Only the following signals are required:

* `piv_fetch_mem_rdata`
* `pov_fetch_mem_addr`

The following signals must be tied to `0`:

* `pil_fetch_mem_valid`
* `pil_fetch_mem_ack`

`pol_fetch_mem_req` may be left unconnected.

### Multi-Cycle Fetch

In this mode, the core waits for a valid response from the memory controller before continuing instruction fetch operations.

This mode is suitable for systems that introduce instruction memory latency.

**Note:** This mode is not fully validated and may introduce undefined behavior when used together with the debugger interface.

---

## Instruction Decode

The Instruction Decode (ID) stage consists of the instruction decoder, the register file, and the data forwarding unit.

The decoder receives instructions from the IF stage and generates the required control signals for subsequent pipeline stages. These control signals propagate through the pipeline and are consumed by the computational units of each stage.

The register file consists of 32 general-purpose registers. If the Embedded (`E`) extension is enabled, only the lower 16 registers are implemented, significantly reducing area and resource utilization.

Optionally, if the hardware-backup feature is enabled, a shadow copy of the entire register file is created, effectively doubling the total register count. This feature is useful for low-latency interrupt handling. Refer to [fast_interrupt.md](fast_interrupt.md) for additional details.

The data forwarding unit resolves data hazards and dependencies between pipeline stages.

---

## Execute

The Execute (EXE) stage contains the computational units of the processor, including the Arithmetic Logic Unit (ALU) CSR Unit.

Additionally, if the Integer Multiplication and Division (`M`) extension is enabled, multiplication and division modules are also instantiated in this stage.

Custom execution modules may also be integrated into this stage.

---

## Memory Access

The Memory Access (MA) stage contains the memory interface module responsible for handling data bus read and write transactions. Similar to the prefetch buffer, the memory interface module uses acknowledge and valid signals to coordinate memory operations.
 
The following table shows the data memory interface of the core:

| Signal             | Direction | Description                                                                                        |
| :---               | :---      | :---                                                                                               |
| `pil_mem_valid`    | Input     | `1 = piv_mem_rdata is valid` (from memory bus controller to core).                                 |
| `pil_mem_ack`      | Input     | `1 = Memory controller acknowledged the request of the core` (from memory bus controller to core). |
| `pol_mem_req`      | Output    | `1 = Core requests access to the data bus`.                                                        |
| `pol_mem_wen`      | Output    | `1 = Core requests a memory write operation`.                                                      |
| `piv_mem_rdata`    | Input     | Data read from memory (from memory bus controller to core).                                        |
| `pov_mem_wdata`    | Output    | Write data (from core to memory bus controller).                                                   |
| `pov_mem_addr`     | Output    | Memory address (from core to memory bus controller).                                               |
| `pov_mem_byte_sel` | Output    | Indicates which byte lanes are active for the current memory access operation.                     |

Custom modules that operate on specialized data structures may also be integrated into this stage.

---

## Writeback

The Writeback (WB) stage selects and forwards results from the Execute (EXE) and Memory Access (MA) stages back to the register file.