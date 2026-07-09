# Programming and Debugging Interface

The pearl3 microcontroller supports serial program loading and debugging through a dedicated UART interface.

Communication between the host PC and the microcontroller takes place using the following pins:

| Signal | Direction | Description                                              |
| :---   | :---      | :---                                                     |
| DI     | Input     | Serial programming and debug command input from host PC. |
| DO     | Output    | Serial response output from microcontroller.             |

The host PC sends commands through the `DI` pin. Depending on the command, the microcontroller may return status information or debug data through the `DO` pin.

---

## Supported Commands

| Command | Mode     | Packet Size | Description                                                     |
| :---    | :---     | ---:        | :---                                                            |
| `0xAA`  | Program  | 1 Byte      | Program application image and immediately start execution.      |
| `0xAD`  | Program  | 1 Byte      | Program application image and halt execution after programming. |
| `0xDA`  | Debug    | 6 Bytes     | Read all general-purpose registers and supported CSRs.          |
| `0xDB`  | Debug    | 6 Bytes     | Read from 32-bit memory location.                               |
| `0xD6`  | Debug    | 6 Bytes     | Read retired program counter.                                   |
| `0xDC`  | Debug    | 6 Bytes     | Enable single-step mode.                                        |
| `0xDD`  | Debug    | 6 Bytes     | Resume execution.                                               |
| `0xDE`  | Debug    | 6 Bytes     | Enter debug mode.                                               |
| `0xDF`  | Debug    | 6 Bytes     | Disable single-step mode.                                       |
| `0xD0`  | Debug    | 6 Bytes     | Configure hardware trigger 0.                                   |
| `0xD1`  | Debug    | 6 Bytes     | Configure hardware trigger 1.                                   |
| `0xEA`  | Debug    | 6 Bytes     | Write to a general-purpose register or a CSR.                   |
| `0xEB`  | Debug    | 6 Bytes     | Write to a 32-bit memory location.                              |
| `0xE6`  | Debug    | 6 Bytes     | Write to the `debug write value register`.                      |

---

## Programming Interface

The programming interface allows the host PC to load application code into program memory using Intel HEX format.

---

### Program Load (`0xAA`)

The host PC initiates program loading by sending the single-byte command `0xAA`.

#### Programming Sequence

1. Host PC sends `0xAA`.
2. Microcontroller responds with a 17-byte device ID.
3. Host PC transmits the application image in Intel HEX format.
4. Program memory is updated.
5. Execution automatically begins after programming completes.

---

### Program Load and Halt (`0xAD`)

The `0xAD` command behaves similarly to `0xAA`, except that execution remains halted after programming completes. The programmer module hands over the control to the debug interface by automatically sending `enter debug` command (`0xDE`). The host PC must send only the remaining 5 bytes which comprises the parameter and the state fields.

This mode is primarily intended for debugging immediately after reset.

#### Programming Sequence

1. Host PC sends `0xAD`.
2. Microcontroller responds with a 17-byte device ID.
3. Host PC transmits the application image.
4. Program memory is updated.
5. Core execution remains halted.
6. Host PC must send the parameter and state fields.

## Debug Interface

The debugger interface uses fixed-length 6-byte packets.

All packets are transmitted in little-endian format.

---

### Debug Command Packet Format

| Field     | Size    | Description                           |
| :---      | ---:    | :---                                  |
| Command   | 1 Byte  | Debug command opcode.                 |
| Parameter | 4 Bytes | Command parameter or memory address.  |
| State     | 1 Byte  | Command state or configuration value. |

---

### Packet Layout

```text
[0]     = Command
[1..4]  = Parameter (little-endian)
[5]     = State
```

If a command does not require `Parameter` or `State`, the following packet format is recommended in little-endian format:

| 5     | 4 3 2 1                     | 0         |
| :---: | :---:                       | :---:     |
| State | Parameter                   | Command   |
| `0x00`| `0x00` `0x00` `0x00` `0x00` | `cmd`     |

---

#### Debugger Responses

The debugger returns a 32-bit status value for all commands.

| Response Code    | Type        | Description                                       |
| :---             | :---        | :---                                              |
| `0x0000_<cmd>00` | NO ERROR    | Command executed successfully.                    |
| `0x0000_0000`    | UNDEF STATE | Debugger exited due to previous error or timeout. |
| `0x0000_<cmd>AF` | TIMEOUT     | Core did not respond before timeout expired.      |
| `0x0000_<cmd>02` | INVALID CMD | Unsupported or invalid command.                   |
| `0x0000_<cmd>03` | REG ACCESS  | Failed to access GPRs or CSRs.                    |

If the debugger returns `UNDEF STATE`, the host should issue the `Enter Debug` command again before continuing further debug operations.

---

### Enter Debug (`0xDE`)

Places the core into debug mode.

This command uses both the `Parameter` and `State` fields.

| State value | Description               |
| :---        | :---                      |
| `0x00`      | Disable debugger timeout. |
| `0x01`      | Enable debugger timeout.  |

When debugger timeout is enabled:

* `Parameter[31:16]` specifies the timer prescaler.
* `Parameter[15:0]` specifies the timeout match value.

If the core does not respond before the timeout expires, the debugger returns a timeout response.

This feature can be used to verify that a hardware breakpoint is reached within a bounded time interval.

---

### Log Registers (`0xDA`)

Reads all general-purpose registers (`x0-x31`) and supported CSRs.

This command does not require `Parameter` or `State`.

For example, to read all register values, the host transmits:

```text
0xDA 0x00 0x00 0x00 0x00 0x00
```

---

### Read Memory (`0xDB`)

Reads a 32-bit value from memory.

`Parameter` specifies the 32-bit memory address to read.

`State` is ignored.

For example, to read memory address `0xCAAD10A0`, the host transmits:

```text
0xDB 0xA0 0x10 0xAD 0xCA 0x00
```

---

### Log Retired Program Counter (`0xD6`)

Returns the address of the last retired instruction.

This command does not require `Parameter` or `State`.

For example, to read address of the last instruction executed, the host transmits:

```text
0xD6 0x00 0x00 0x00 0x00 0x00
```
---

### Enable Step Mode (`0xDC`)

Enables single-step execution.

When enabled, the processor executes one instruction and automatically re-enters debug mode.

This command does not require `Parameter` or `State`.

---

### Resume Execution (`0xDD`)

Resumes normal execution from debug mode.

This command does not require `Parameter` or `State`.

---

### Disable Step Mode (`0xDF`)

Disables single-step execution mode.

This command does not require `Parameter` or `State`.

---

### Configure Trigger0 (`0xD0`)

Configures hardware trigger module 0.

| State value | Description      |
| :---        | :---             |
| `0x00`      | Disable trigger. |
| `0x01`      | Enable trigger   |

When enabled, `Parameter` specifies the instruction address used for trigger matching.

---

### Configure Trigger1 (`0xD1`)

Configures hardware trigger module 1.

| State value | Description      |
| :---        | :---             |
| `0x00`      | Disable trigger. |
| `0x01`      | Enable trigger.  |

When enabled, `Parameter` specifies the instruction address used for trigger matching.

---

### Write Register (`0xEA`)

Write the value of `Debug Write Value Register` to a specific general-purpose register or a CSR.

`Parameter` specifies the register to write to. Register: `0x000 - 0x01F` for GPRs, `0x300 - 0xFFF` for CSRs.

`State` is ignored.

For example, to write to `mstatus` at `0x300`, the host transmits:

```text
0xEA 0x00 0x03 0x00 0x00 0x00
```

---

### Write Memory (`0xEB`)

Write the value of `Debug Write Value Register` to memory.

`Parameter` specifies the 32-bit memory address to write to.

`State` is ignored.

For example, to write to memory address `0xCAAD10A0`, the host transmits:

```text
0xEB 0xA0 0x10 0xAD 0xCA 0x00
```

---

### Write to Debug Write Value Register (`0xE6`)

Write a 32-bit value to `debug write value register`.

`Parameter` specifies the 32-bit value to write.

`State` is ignored.

For example, to write the value `0xCAAD10A0`, the host transmits:

```text
0xE6 0xA0 0x10 0xAD 0xCA 0x00
```

---

## Notes

* All debug packets are fixed-length packets of 6 bytes.
* Multi-byte fields are transmitted in little-endian format.
* The debugger interface is independent from the standard UART peripherals.
* Debugging support is implemented using the native SparrowX32 debug interface.
* Hardware triggers operate on instruction address matches.