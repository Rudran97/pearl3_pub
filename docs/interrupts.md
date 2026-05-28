# Interrupts

The microcontroller uses a custom [clic](../core/SparrowX32/rtl/clic.vhd) module implemented in SparrowX32 architecture. The clic module supports eight interrupt sources and uses a matrix based priority arbitration to select the correct source and pass it through to the core. 

The clic module has the following characteristics:

* 8 interrupt sources that can be mapped to any of the peripheral modules that generates interrupt.
* 8 levels of interrupt priority.
* Can be configured to either use the core's fast IRQ pin or external interrupt pin.

The following registers are associated with interrupts:

**Note**: x = [0:7], y = [0:3]

## Interrupt Vector Address Register (INTxADDR)

| Bit  | Access | Description                                                                                          |
| :--- | :---   | :---                                                                                                 |
| 15:0 | RW     | ISR vector address for interrupt source `x`. The core will jump to this address when fast IRQ pin is used by the clic module. |

## Interrupt Priority Register (INTxPRIO)

| Bit  | Access | Description                                                                          |
| :--- | :---   | :---                                                                                 |
| 15:4 | -      | -                                                                                    |
| 3:0  | RW     | Priority value for interrupt source `x`. `0 = No interrupt`, `7 = Maximum priority`. |

## Interrupt Control Register (INTCON)

| Bit  | Name  | Access | Description                                                                          |
| :--- | :---  | :---   | :---                                                                                 |
| 15:3 |       | -      | -                                                                                    |
| 2    | EXTI  | RW     | External interrupt: `0 = Raise interrupts at core's fast IRQ pin`, `1 = Raise interrupts at core's external interrupt pin`. |
| 1    | -     | -      | -                                                                                    |
| 0    | GIE   | RW     | Clic enable.                                                                         |

## Interrupt ID Register (IRQID)

| Bit  | Access | Description                    |
| :--- | :---   | :---                           |
| 15:0 | RO     | Interrupt source ID value `x`. |

## External Interrupt Control Register (EXTyCON)

In addition to the interrupts raised by the timers and the serial communication modules, the microcontroller supports four additional interrupts through GPIO pins. They can be configured to trigger at either rising or falling edge of the corresponding GPIO pin. To capture an interrupt, the pin must be configured as input.

| Bit  | Name    | Access | Description                                                                                       |
| :--- | :---    | :---   | :---                                                                                              |
| 15:6 |         | -      | -                                                                                                 |
| 5:2  | TRIGPIN | RW     | Trigger pin: `EXT[0:1]` and `EXT[2:3]` can be mapped to any pins of PORTA and PORTB respectively. |
| 1    | EDGE    | RW     | Trigger edge: `0 = falling edge`, `1 = rising edge`.                                              |
| 0    | TRIGyEN | RW     | Enable capturing of external interrupts.                                                          |

## Interrupt Map Register (INTxMAP)

| Bit  | Access | Description                                                  |
| :--- | :---   | :---                                                         |
| 15:0 | RW     | `Interrupt map code`: Map functions to interrupt source `x`. |

The following table shows the various functions that can be mapped to each interrupt source:

| Interrupt map code | Description                                                |
| :---:              | :---                                                       |
| 0                  | No interrupt function is attached to interrupt source `x`. |
| 1                  | Attach TIMER0A to interrupt source `x`.                    |
| 2                  | Attach TIMER0B to interrupt source `x`.                    |
| 3                  | Attach TIMER1A to interrupt source `x`.                    |
| 4                  | Attach TIMER1B to interrupt source `x`.                    |
| 5                  | Attach TIMER2A to interrupt source `x`.                    |
| 6                  | Attach TIMER2B to interrupt source `x`.                    |
| 7                  | Attach TIMER3A to interrupt source `x`.                    |
| 8                  | Attach TIMER3B to interrupt source `x`.                    |
| 9                  | Attach TIMER4 to interrupt source `x`.                     |
| 10                 | Attach TIMER4ICF to interrupt source `x`.                  |
| 11                 | Attach TIMER5 to interrupt source `x`.                     |
| 12                 | Attach TIMER5ICF to interrupt source `x`.                  |
| 13                 | Attach UART0RX to interrupt source `x`.                    |
| 14                 | Attach UART0TX to interrupt source `x`.                    |
| 15                 | Attach UART1RX to interrupt source `x`.                    |
| 16                 | Attach UART1TX to interrupt source `x`.                    |
| 17                 | Attach I2C0IF to interrupt source `x`.                     |
| 18                 | Attach I2C0BCLF to interrupt source `x`.                   |
| 19                 | Attach I2C0TOTF to interrupt source `x`.                   |
| 20                 | Attach I2C0DNF to interrupt source `x`.                    |
| 21                 | Attach SPI0IF to interrupt source `x`.                     |
| 22                 | Attach EXTINT0 to interrupt source `x`.                    |
| 23                 | Attach EXTINT1 to interrupt source `x`.                    |
| 24                 | Attach EXTINT2 to interrupt source `x`.                    |
| 25                 | Attach EXTINT3 to interrupt source `x`.                    |


**Note**: The following registers are only relevant when debugging the actual hardware during simulation. These registers are not used for software development.

### Interrupt Source Pending Register (INTSRC)

| Bit  | Name  | Access | Description              |
| :--- | :---  | :---   | :---                     |
| 15:8 |       | -      | -                        |
| 7    | INT7  | RO     | `1 = Interrupt pending`. |
| 6    | INT6  | RO     | `1 = Interrupt pending`. |
| 5    | INT5  | RO     | `1 = Interrupt pending`. |
| 4    | INT4  | RO     | `1 = Interrupt pending`. |
| 3    | INT3  | RO     | `1 = Interrupt pending`. |
| 2    | INT2  | RO     | `1 = Interrupt pending`. |
| 1    | INT1  | RO     | `1 = Interrupt pending`. |
| 0    | INT0  | RO     | `1 = Interrupt pending`. |

### Interrupt Source Clear Register (INTCLR)

| Bit  | Name  | Access | Description                                                           |
| :--- | :---  | :---   | :---                                                                  |
| 15:8 |       | -      | -                                                                     |
| 7    | INT7  | RO     | `1 = Clic requests the interrupt source to clear the interrupt flag`. |
| 6    | INT6  | RO     | `1 = Clic requests the interrupt source to clear the interrupt flag`. |
| 5    | INT5  | RO     | `1 = Clic requests the interrupt source to clear the interrupt flag`. |
| 4    | INT4  | RO     | `1 = Clic requests the interrupt source to clear the interrupt flag`. |
| 3    | INT3  | RO     | `1 = Clic requests the interrupt source to clear the interrupt flag`. |
| 2    | INT2  | RO     | `1 = Clic requests the interrupt source to clear the interrupt flag`. |
| 1    | INT1  | RO     | `1 = Clic requests the interrupt source to clear the interrupt flag`. |
| 0    | INT0  | RO     | `1 = Clic requests the interrupt source to clear the interrupt flag`. |

### Interrupt Status Register (INTSTAT)

| Bit  | Name  | Access | Description                    |
| :--- | :---  | :---   | :---                           |
| 15:1 |       | -      | -                              |
| 0    | IRQ   | RO     | Current status of the IRQ pin. |