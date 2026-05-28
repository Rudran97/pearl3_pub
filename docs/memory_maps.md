# Memory Organization

The pearl3 microcontroller uses a simple bus multiplexer to access different memory regions. Each region is mapped into a fixed address space and is used for program storage, data storage, interrupt control, and peripheral access.

All memory regions are word-aligned. Peripheral accesses are performed using 32-bit aligned addresses.

---

## Memory Map

| Region         | Start Address | End Address | Size      | Access               | Description                     |
| :---           | :---          | :---        | :---      | :---                 | :---                            |
| Program Memory | 0x80000000    | 0x8000BFFF  | 48 kB     | Core, Debugger       | Instruction memory.             |
| CLIC Region    | 0x40000000    | 0x4000007C  | 128 Bytes | Core, User, Debugger | Interrupt controller registers. |
| I/O Region     | 0x20000000    | 0x2000014C  | 332 Bytes | Core, User, Debugger | Peripheral registers.           |
| Data Memory    | 0x10000000    | 0x10003FFF  | 16 kB     | Core, User, Debugger | Data RAM.                       |

---

## Program Memory

Address Range: `0x80000000 - 0x8000BFFF`

Size: `48 kB`

The program memory stores executable instructions fetched by the SparrowX32 core.

This region is accessible only by the processor instruction fetch unit and the debugger interface. The user program cannot directly modify program memory contents through normal bus transactions.

The current implementation is configured for a 48 kB instruction memory and supports the RV32IMC instruction set architecture.

---

## Core Local Interrupt Controller (CLIC) Region

Address Range: `0x40000000 - 0x4000007F`

Implemented Register Range: `0x40000000 - 0x40000050`

Allocated Size: `128 Bytes`

The CLIC region contains registers related to interrupt vector configuration, interrupt priorities, interrupt status, and interrupt control.

The hardware internally allocates 32 word-aligned register locations. Address bits `[1:0]` are ignored by the hardware, and register selection is performed using address bits `[6:2]`.

Both the user program and debugger can access the CLIC region.

---

## I/O Region

Address Range: `0x20000000 - 0x2000014C`

Size: `336 Bytes`

The I/O region contains memory-mapped peripheral registers including:

* GPIO
* Timers
* UART
* I2C
* SPI
* PWM
* External interrupts
* Interrupt mapping registers

Peripheral registers are word-aligned and accessed through 32-bit transactions.

Both the user program and debugger can access this region.

Refer to `io_registers.md` for the complete peripheral register map.

---

## Data Memory

Address Range: `0x10000000 - 0x10003FFF`

Size: `16 kB`

The data memory region provides general-purpose RAM storage for:

* Global variables
* Stack
* Heap
* Runtime data

Both the user program and debugger can access this region.

---

## Notes

* All peripheral and CLIC registers are word-aligned.
* Address bits `[1:0]` are ignored for peripheral and clic register accesses.
* Reserved or unimplemented register locations return `0` on read operations, unless software modifies it.
* Writes to reserved regions have no effect unless otherwise specified.