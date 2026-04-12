# 8-bit Harvard Architecture Processor with Extended Instruction and Register Operations on FPGA
> A fully custom-designed, 5-stage multi-cycle 8-bit processor implementing the **Harvard architecture**, synthesized and demonstrated on a **Digilent Basys3 (Xilinx Artix-7)** FPGA board. All arithmetic units are built from gate-level primitives — no native Verilog operators were used for computation, as required for academic demonstration.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Module Breakdown](#module-breakdown)
- [Instruction Set Architecture (ISA)](#instruction-set-architecture-isa)
- [ALU Operations](#alu-operations)
- [Demo Program (program.mem)](#demo-program-programmem)
- [I/O Interface — Basys3 Board](#io-interface--basys3-board)
- [File Structure](#file-structure)
- [Simulation & Testbenches](#simulation--testbenches)
- [How to Build & Run](#how-to-build--run)
- [Hardware Requirements](#hardware-requirements)
- [Known Limitations](#known-limitations)

---

## Overview

This project implements a custom **8-bit Harvard CPU** in Verilog, simulated and synthesized using **Xilinx Vivado** for the **Basys3 development board** (Artix-7 FPGA, XC7A35T-1CPG236C).

Key highlights:
- **5-stage multi-cycle execution pipeline**: FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK
- **Harvard architecture**: Physically separated instruction memory (ROM) and data memory (RAM)
- **Gate-level ALU**: The entire ALU — including the adder, subtractor, multiplier, divider, and shift/rotate logic — is implemented using explicit bit-level operations (no `+`, `*` operators in RTL computation paths)
- **17 supported operations**: Arithmetic, logic, shift/rotate, extended math (MUL, SQR, CUBE, DIV), memory access, branching, and HALT
- **Real-time hardware I/O**: 16 switches, 5 buttons, 16 LEDs, and a 4-digit 7-segment display for live CPU observation
- **Single-step debug mode**: Manually clock the CPU one stage at a time using the BTNC button

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        HARVARD CPU (top)                        │
│                                                                 │
│  ┌──────────────┐    ┌────────────────┐    ┌─────────────────┐  │
│  │  Instruction │    │  Control Unit  │    │  Register File  │  │
│  │  Memory (ROM)│ ─► │  (Decoder)     │ ─► │  R0..R3 (8-bit) │  │
│  │  256 x 8-bit │    │                │    │  4 registers    │  │
│  └──────────────┘    └────────────────┘    └─────────────────┘  │
│          │                  │                      │            │
│          │            ┌─────▼──────┐               │            │
│          │            │    ALU     │◄──────────────┘            │
│          │            │ (gate-lvl) │                            │
│          │            │  17 ops    │                            │
│          │            └─────┬──────┘                            │
│          │                  │                                   │
│          │            ┌─────▼──────┐    ┌─────────────────┐    │
│          │            │  Data Mem  │    │  7-Seg Display  │    │
│          │            │  (256 B    │    │  (PC + Result)  │    │
│          │            │   RAM)     │    └─────────────────┘    │
│          │            └────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

### Pipeline Stages

| Stage | State ID | Description |
|-------|----------|-------------|
| **FETCH** | `4'd0` | Reads instruction from Instruction Memory at current PC address |
| **DECODE** | `4'd1` | Control Unit decodes the 8-bit instruction into control signals |
| **EXECUTE** | `4'd2` | ALU performs the operation; result and flags are latched |
| **MEMORY** | `4'd3` | Data Memory read (LOAD) or write (STORE) is performed |
| **WRITEBACK** | `4'd4` | Result is written back to the Register File; PC advances |
| **HALTED** | `4'd5` | CPU is stopped (triggered by `0xFF` instruction) |

The pipeline state is visible on `LED[15:12]` in real-time on the board.

---

## Module Breakdown

### `top_module.v` — Board Top-Level Wrapper
Connects the CPU to all physical I/O on the Basys3 board. Handles:
- Clock selection from clock divider (SW[5:4])
- Button debouncing and edge detection for single-step and manual register load
- Flag override logic (SW[12] enables manual ZCVS override via SW[11:8] + BTNL/BTNR)
- 7-segment display routing (PC value on digits 0–1, ALU result on digits 2–3)

### `harvard_cpu.v` — 5-Stage Multi-Cycle CPU
The core processor module. Implements the state machine, PC control, branch resolution, writeback mux, and flag latching. Instantiates all sub-modules.

### `control_unit.v` — Instruction Decoder
Decodes the 8-bit instruction word `[opcode 7:4][Rd 3:2][Rs 1:0]` into control signals:
- `alu_op[4:0]` — 5-bit ALU operation selector
- `reg_write`, `mem_read`, `mem_write`, `mem_to_reg` — datapath enables
- `is_branch`, `branch_type[1:0]` — branch handling
- `is_ldi`, `halt` — special cases

### `alu.v` — Gate-Level Arithmetic Logic Unit
The most complex module. Implements **all operations from scratch** at the bit level:
- **8-bit ripple-carry adder**: Manually chained 8× full-adder cells using `XOR` / `AND` / `OR` gates
- **Subtractor**: Uses 2's complement (invert B + Cin=1)
- **Shift & Rotate**: Explicit bit-wire connections (no `<<`/`>>` operators in RTL)
- **Multiply**: Shift-and-add algorithm (16-bit accumulator)
- **Square & Cube**: Iterative multiply stages, all manual
- **Divide**: Repeated-subtraction logic with divide-by-zero guard

### `register_file.v` — 4 × 8-Bit Registers (R0–R3)
- Synchronous write (on `posedge clk`)
- Asynchronous combinational read
- On reset: R0=0x00, R1=0x0A (10), R2=0x03 (3), R3=0x00
- External write port for manual register loading via BTND + SW[15:8]

### `instruction_memory.v` — 256 × 8-Bit ROM
- Loaded at synthesis/simulation from `program.mem` via `$readmemh`
- Asynchronous read (instruction available combinationally same cycle as address)
- 256 addressable locations (8-bit PC)

### `data_memory.v` — 256 × 8-Bit RAM
- Synchronous read and write
- Pre-loaded test data:
  - `0x00` → 5, `0x01` → 10, `0x02` → 3, `0x03` → 7
  - `0x10` → 0xAA, `0x11` → 0x55
- Read data is held stable until next read (safe for WB stage)

### `clock_divider.v` — Adjustable Clock Generator
Derives three divided clocks from the 100 MHz Basys3 oscillator using a 27-bit counter:

| Output | Bit Tap | Frequency |
|--------|---------|-----------|
| `slow_clk` | bit 26 | ~1.5 Hz |
| `med_clk` | bit 24 | ~6 Hz |
| `fast_clk` | bit 22 | ~24 Hz |

### `seven_seg_display.v` — Multiplexed 4-Digit Display
Multiplexes 4 hex digits at ~763 Hz. Display layout:

| Digit | Position | Content |
|-------|----------|---------|
| 3 (leftmost) | `an[3]` | ALU result high nibble |
| 2 | `an[2]` | ALU result low nibble |
| 1 | `an[1]` | Program Counter high nibble |
| 0 (rightmost) | `an[0]` | Program Counter low nibble |

---

## Instruction Set Architecture (ISA)

### Instruction Format (8-bit)

```
 7   6   5   4   3   2   1   0
┌───┬───┬───┬───┬───┬───┬───┬───┐
│  OPCODE (4 bits)  │ Rd  │ Rs  │
└───┴───┴───┴───┴───┴───┴───┴───┘
```

- **OPCODE [7:4]**: 4-bit operation code (16 primary operations)
- **Rd [3:2]**: Destination register (R0–R3)
- **Rs [1:0]**: Source register (R0–R3), or a function modifier

### Standard ALU Instructions

| Opcode (hex) | Mnemonic | Operation | Notes |
|---|---|---|---|
| `0x` | `ADD Rd, Rs` | `Rd ← Rd + Rs` | Sets Z, C, V, S flags |
| `1x` | `SUB Rd, Rs` | `Rd ← Rd - Rs` | Uses 2's complement; C=borrow |
| `2x` | `INC Rd` | `Rd ← Rd + 1` | Sets C on overflow |
| `3x` | `DEC Rd` | `Rd ← Rd - 1` | C=borrow from 0 |
| `4x` | `AND Rd, Rs` | `Rd ← Rd & Rs` | Bitwise AND |
| `5x` | `OR Rd, Rs` | `Rd ← Rd \| Rs` | Bitwise OR |
| `6x` | `XOR Rd, Rs` | `Rd ← Rd ^ Rs` | Bitwise XOR |
| `7x` | `NOT Rd` | `Rd ← ~Rd` | 1's complement |
| `8x` | `SHL Rd` | `Rd ← Rd << 1` | Logical shift left; MSB→C |
| `9x` | `SHR Rd` | `Rd ← Rd >> 1` | Logical shift right; LSB→C |
| `Ax` | `ASHR Rd` | `Rd ← Rd >>> 1` | Arithmetic shift right (sign ext.) |
| `Bx` | `ROL Rd` | `Rd ← rol(Rd, 1)` | Rotate left; MSB wraps to LSB |
| `Cx` | `ROR Rd` | `Rd ← ror(Rd, 1)` | Rotate right; LSB wraps to MSB |
| `Dx` | `MUL Rd, Rs` | `Rd ← (Rd × Rs)[7:0]` | Shift-and-add multiplier |

### Extended Operations (Rs field as function modifier)

| Instruction Word | Mnemonic | Operation |
|---|---|---|
| `7_11` (Rs=11) | `CLR Rd` | `Rd ← 0x00` |
| `8_11` (Rs=11) | `CUBE Rd` | `Rd ← (Rd³)[7:0]` |
| `9_11` (Rs=11) | `SQR Rd` | `Rd ← (Rd²)[7:0]` |
| `A_xx` (Rs≠00) | `DIV Rd, Rs` | `Rd ← Rd / Rs` (div-by-zero → 0xFF, C=1) |

### Memory Instructions (Opcode `1110` = `Ex`)

| Rd | Rs | Mnemonic | Operation |
|---|---|---|---|
| `00` | any | `STORE MEM[Rs], Rd_unused` | `MEM[R[Rs]] ← R[Rd_reg]` |
| ≠`00` | ≠`11` | `LOAD Rd, [Rs]` | `Rd ← MEM[R[Rs]]` |
| ≠`00` | `11` | `LDI Rd, #imm` | `Rd ← SW[7:0]` (from switches) |

### Branch / Control Instructions (Opcode `1111` = `Fx`)

| Rd (branch type) | Mnemonic | Condition |
|---|---|---|
| `00` | `JMP Rs` | Unconditional: `PC ← R[Rs]` |
| `01` | `BEQ Rs` | If Z=1: `PC ← R[Rs]` |
| `10` | `BNE Rs` | If Z=0: `PC ← R[Rs]` |
| `11` | `BMI Rs` | If S=1: `PC ← R[Rs]` |
| `FF` | `HALT` | CPU enters halted state; all LEDs lit |

### Status Flags

| Flag | Bit | Description |
|---|---|---|
| **Z** | `flag_reg[3]` | Zero — result is 0x00 |
| **C** | `flag_reg[2]` | Carry / Borrow — unsigned overflow or borrow |
| **V** | `flag_reg[1]` | Overflow — signed two's complement overflow |
| **S** | `flag_reg[0]` | Sign — MSB of result (bit 7) |

Flags are updated on every ALU write-back. LDI and LOAD instructions update only Z and S. Branch instructions do not update flags.

---

## ALU Operations

The ALU uses a **5-bit opcode** internally. The extra bit space allows for extended operations beyond the 4-bit primary opcode.

| ALU opcode | Hex | Operation |
|---|---|---|
| `5'b00000` | `0x00` | ADD |
| `5'b00001` | `0x01` | SUB (2's complement) |
| `5'b00010` | `0x02` | INC |
| `5'b00011` | `0x03` | DEC |
| `5'b00100` | `0x04` | AND |
| `5'b00101` | `0x05` | OR |
| `5'b00110` | `0x06` | XOR |
| `5'b00111` | `0x07` | NOT |
| `5'b01000` | `0x08` | SHL |
| `5'b01001` | `0x09` | SHR |
| `5'b01010` | `0x0A` | ASHR (arithmetic shift right) |
| `5'b01011` | `0x0B` | ROL |
| `5'b01100` | `0x0C` | ROR |
| `5'b01101` | `0x0D` | MUL (shift-and-add) |
| `5'b01110` | `0x0E` | DIV (unsigned quotient) |
| `5'b01111` | `0x0F` | SQR (A²) |
| `5'b10000` | `0x10` | CUBE (A³) |
| `5'b10001` | `0x11` | CLR (result = 0) |
| `5'b10100` | `0x14` | PASS B (used by LOAD path) |
| `5'b10101` | `0x15` | ZERO (used by LDI path) |

### Hardware Implementation Details

| Unit | Method |
|---|---|
| **Adder** | 8-stage ripple-carry: each bit is a full-adder (`sum = A^B^Cin`, `carry = (A&B)\|(B&Cin)\|(A&Cin)`) |
| **Subtractor** | Inverts B, sets Cin=1 (2's complement negate) |
| **INC / DEC** | Special-cased adder with B=0x00/0xFF |
| **AND/OR/XOR/NOT** | Bit-indexed gate arrays |
| **SHL/SHR** | Explicit bit-wire assignments |
| **ASHR** | SHR with `result[7] = A[7]` (sign replicated) |
| **ROL/ROR** | Circular bit-wire assignments (`A[7]→result[0]` for ROL) |
| **MUL** | 8-iteration shift-and-add; 16-bit accumulator; lower 8 bits returned |
| **SQR** | MUL applied with `A = B = operand` |
| **CUBE** | Two chained MUL stages: `temp = A²`, then `result = temp × A` |
| **DIV** | Division with divide-by-zero guard (`0xFF` returned, C=1) |

---

## Demo Program (`program.mem`)

The CPU ships with an 18-instruction demonstration program that exercises every functional group:

```
; Addr | Hex | Instruction          | Expected Result
; -----+-----+----------------------+------------------
  [00]   06   ADD  R1, R2            R1 = 0x0A + 0x03 = 0x0D (13)
  [01]   16   SUB  R1, R2            R1 = 0x0D - 0x03 = 0x0A (10)
  [02]   24   INC  R1                R1 = 0x0A + 1    = 0x0B (11)
  [03]   34   DEC  R1                R1 = 0x0B - 1    = 0x0A (10)
  [04]   46   AND  R1, R2            R1 = 0x0A & 0x03 = 0x02
  [05]   56   OR   R1, R2            R1 = 0x02 | 0x03 = 0x03
  [06]   66   XOR  R1, R2            R1 = 0x03 ^ 0x03 = 0x00  (Z=1)
  [07]   74   NOT  R1                R1 = ~0x00       = 0xFF  (S=1)
  [08]   77   CLR  R1                R1 = 0x00               (Z=1)
  [09]   88   SHL  R2                R2 = 0x03 << 1   = 0x06
  [0A]   98   SHR  R2                R2 = 0x06 >> 1   = 0x03
  [0B]   B8   ROL  R2                R2 = rol(0x03,1) = 0x06
  [0C]   C8   ROR  R2                R2 = ror(0x06,1) = 0x03
  [0D]   70   NOT  R0                R0 = ~0x00       = 0xFF
  [0E]   90   SHR  R0                R0 = 0xFF >> 1   = 0x7F  (C=1)
  [0F]   70   NOT  R0                R0 = ~0x7F       = 0x80  (S=1)
  [10]   A0   ASHR R0                R0 = 0x80 >>>1   = 0xC0  (sign ext. S=1)
  [11]   06   ADD  R1, R2            R1 = 0x00+0x03   = 0x03  (re-init)
  [12]   D6   MUL  R1, R2            R1 = 3 × 3       = 0x09 (9)
  [13]   97   SQR  R1                R1 = 9²          = 81 = 0x51
  [14]   8B   CUBE R2                R2 = 3³          = 27 = 0x1B
  [15]   A6   DIV  R1, R2            R1 = 81 / 27     = 3 = 0x03
  [16]   FF   HALT                   CPU stops; LED[15:12] = 0xF
```

## Demo Video

Watch the processor running on real FPGA hardware:

[![Watch the demo](https://img.youtube.com/vi/0D2HFEzq8hU/0.jpg)](https://youtu.be/0D2HFEzq8hU)

**Initial Register State (after BTNU reset):**
- R0 = `0x00`
- R1 = `0x0A` (decimal 10)
- R2 = `0x03` (decimal 3)
- R3 = `0x00`

---

## I/O Interface — Basys3 Board

### Switches (SW[15:0])

| Switch(es) | Function |
|---|---|
| `SW[15:8]` | Manual data byte — written to register R[SW[1:0]] when BTND is pressed |
| `SW[7:0]` | Immediate value for `LDI` instructions |
| `SW[5:4]` | CPU clock speed: `00`=~1.5Hz (slow), `01`=~6Hz (med), `10`=~24Hz (fast), `11`=single-step (BTNC) |
| `SW[12]` | Flag override enable — allows manual control of ZCVS flags |
| `SW[11:8]` | Manual flag values `{Z, C, V, S}` (active when SW[12]=1) |
| `SW[1:0]` | Register address for manual write (R0–R3) |

### Push Buttons

| Button | Function |
|---|---|
| **BTNU** (Up) | **Reset** — clears PC to 0x00, resets state machine, restores register defaults |
| **BTNC** (Center) | **Single-step pulse** when SW[5:4]=11; advances CPU by one clock edge |
| **BTNL** (Left) | OR's into the Z flag when flag override is enabled |
| **BTNR** (Right) | OR's into the S flag when flag override is enabled |
| **BTND** (Down) | Loads SW[15:8] into register R[SW[1:0]] (manual register write) |

### LEDs

| LED Range | Content |
|---|---|
| `LED[7:0]` | Current instruction register (IR) — the 8-bit opcode being executed |
| `LED[11:8]` | Processor flags: `{Z, C, V, S}` |
| `LED[15:12]` | Pipeline stage indicator: 0=FETCH, 1=DECODE, 2=EXECUTE, 3=MEMORY, 4=WRITEBACK, F=HALTED |

### 7-Segment Display

```
  ┌────┬────┬────┬────┐
  │ D3 │ D2 │ D1 │ D0 │
  │ RH │ RL │ PH │ PL │  RH/RL = Result (high/low nibble)
  └────┴────┴────┴────┘  PH/PL = PC value (high/low nibble)
```

---

## File Structure

```
harvard_cpu2/
│
├── harvard_cpu2.xpr               # Vivado project file
│
└── harvard_cpu2.srcs/
    ├── sources_1/
    │   └── imports/
    │       ├── sources/
    │       │   ├── top_module.v           # Basys3 top-level wrapper
    │       │   ├── harvard_cpu.v          # 5-stage multi-cycle CPU core
    │       │   ├── control_unit.v         # Instruction decoder
    │       │   ├── alu.v                  # Gate-level ALU (17 operations)
    │       │   ├── register_file.v        # 4 × 8-bit register file
    │       │   ├── instruction_memory.v   # 256 × 8-bit ROM
    │       │   ├── data_memory.v          # 256 × 8-bit RAM
    │       │   ├── clock_divider.v        # 100 MHz → 1.5/6/24 Hz divider
    │       │   └── seven_seg_display.v    # 4-digit hex display controller
    │       └── memory_files/
    │           └── program.mem            # 18-instruction demo program (hex)
    │
    ├── sim_1/
    │   └── imports/
    │       └── sim/
    │           ├── cpu_tb.v               # Full CPU integration testbench
    │           └── alu_tb.v               # ALU unit testbench
    │
    └── constrs_1/
        └── imports/
            └── constraints/
                └── basys3.xdc             # Pin constraints for Artix-7 / Basys3
```

---

## Simulation & Testbenches

### `cpu_tb.v` — Full CPU Integration Test
Instantiates the complete `harvard_cpu` module and runs the full demo program for 5000 ns. Uses `$monitor` to print a cycle-accurate trace:

```
==========================================================
 CPU Test — 5-stage Harvard CPU (multi-cycle)
==========================================================
 Time | PC   | Instr | ALUResult | Flags(ZCVS)
    5 | 0x00 | 0x06  | 0x00      | 0000
   55 | 0x01 | 0x16  | 0x0D      | 0000
  ...
```

### `alu_tb.v` — ALU Unit Test
Directly tests the ALU module by sweeping input combinations and verifying flags for each operation individually.

### Running Simulation in Vivado
1. Open `harvard_cpu2.xpr` in Vivado
2. In the **Flow Navigator**, expand **Simulation** → click **Run Simulation** → **Run Behavioral Simulation**
3. Select `cpu_tb` as the top simulation module
4. Observe waveforms or console output

> **Note**: The `instruction_memory.v` uses an absolute path for `$readmemh`. Update the path in `instruction_memory.v` to match your local project directory before simulating.

---

## How to Build & Run

### Prerequisites
- [Xilinx Vivado](https://www.xilinx.com/support/download.html) (2020.x or later recommended; free WebPACK edition works)
- Digilent Basys3 board (or compatible Artix-7 board with 16 switches, 16 LEDs, 5 buttons, 4-digit 7-seg)
- USB-A to Micro-USB cable for JTAG programming

### Steps

1. **Clone/copy** the project folder to your machine.

2. **Open in Vivado**:
   ```
   File → Open Project → select harvard_cpu2.xpr
   ```

3. **Fix the memory file path** in `instruction_memory.v`:
   ```verilog
   $readmemh("YOUR_PATH/memory_files/program.mem", mem);
   ```

4. **Run Synthesis**: Flow Navigator → Synthesis → Run Synthesis

5. **Run Implementation**: Flow Navigator → Implementation → Run Implementation

6. **Generate Bitstream**: Flow Navigator → Generate Bitstream

7. **Program the FPGA**:
   ```
   Open Hardware Manager → Open Target → Auto Connect → Program Device
   ```

### Operating the CPU on Hardware

| Step | Action |
|---|---|
| Power on | Connect Basys3 via USB |
| Reset | Press **BTNU** to initialize CPU (PC=0, registers to defaults) |
| Set clock speed | Use **SW[5:4]**: Start with `01` (medium, ~6 Hz) to watch execution |
| Watch state | `LED[15:12]` cycles 0→1→2→3→4→0 each instruction |
| Watch IR | `LED[7:0]` shows the current instruction byte |
| Watch flags | `LED[11:8]` = Z, C, V, S |
| Watch result | 7-segment shows PC (right 2 digits) and ALU result (left 2 digits) |
| Load register | Set SW[15:8] to value, SW[1:0] to register address, press **BTND** |
| Single-step | Set SW[5:4]=`11`, then press **BTNC** for one clock edge at a time |
| Halt | CPU stops at `0xFF` instruction; `LED[15:12]` shows `F` (all 4 lit) |

---

## Hardware Requirements

| Component | Specification |
|---|---|
| FPGA Board | Digilent Basys3 (Artix-7 XC7A35T-1CPG236C) |
| Clock | 100 MHz on-board oscillator (W5) |
| I/O Standard | LVCMOS33 (3.3V) |
| Switches | 16 slide switches (SW0–SW15) |
| LEDs | 16 LEDs (LD0–LD15) |
| Buttons | 5 tactile buttons (BTNC, BTNU, BTNL, BTNR, BTND) |
| Display | 4-digit common-anode 7-segment display |
| EDA Tool | Xilinx Vivado (WebPACK license sufficient) |

---

## Known Limitations

1. **Absolute memory path**: `instruction_memory.v` hardcodes the `$readmemh` path. This must be updated when moving the project to a different machine or directory.

2. **8-bit PC**: Maximum program size is 256 instructions. No paging or extended addressing is implemented.

3. **No forwarding/hazard detection**: This is a true multi-cycle design, not a pipelined design. Each instruction completes all 5 stages before the next begins, so there are no data hazards.

4. **Truncated multiply results**: MUL, SQR, and CUBE return only the lower 8 bits of the full product. The carry flag `C=1` signals that the upper byte was non-zero (product overflowed 8 bits).

5. **Clock mux is combinational**: The `cpu_clk` MUX in `top_module.v` is combinational, which may produce glitches during clock selection switching. Avoid changing SW[5:4] while the CPU is running critical operations.

6. **Division is behavioral**: Despite the ALU's gate-level design philosophy, the `DIV` operation uses a Verilog `/` operator internally (a pragmatic exception for synthesizable division). All other arithmetic uses gate-level or structural RTL.

---

## Academic Context

This project was developed as a **Digital Systems Design (DSD)** course assignment demonstrating:
- Harvard vs. Von Neumann architecture trade-offs
- Custom ISA design and binary encoding
- Gate-level ALU implementation without built-in operators
- Multi-cycle FSM-based processor design
- FPGA synthesis and physical demonstration on real hardware

---

*Designed and implemented in Verilog HDL | Synthesized with Xilinx Vivado | Target: Digilent Basys3 (Artix-7)*
