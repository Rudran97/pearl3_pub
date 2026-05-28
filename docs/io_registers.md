# Peripheral Registers

This document lists the memory-mapped peripheral registers implemented in the pearl3 microcontroller.

All peripheral registers are 16-bit wide and aligned to 4-byte boundaries.

---

## Custom Core-Local Interrupt Controller (CLIC)

Base Address: `0x40000000`

| Register | Address     | Description                     |
| :---     | :---        | :---                            |
| INT0ADDR | 0x40000000  | Interrupt 0 ISR vector address. |
| INT1ADDR | 0x40000004  | Interrupt 1 ISR vector address. |
| INT2ADDR | 0x40000008  | Interrupt 2 ISR vector address. |
| INT3ADDR | 0x4000000C  | Interrupt 3 ISR vector address. |
| INT4ADDR | 0x40000010  | Interrupt 4 ISR vector address. |
| INT5ADDR | 0x40000014  | Interrupt 5 ISR vector address. |
| INT6ADDR | 0x40000018  | Interrupt 6 ISR vector address. |
| INT7ADDR | 0x4000001C  | Interrupt 7 ISR vector address. |
| INT0PRIO | 0x40000020  | Interrupt 0 priority register.  |
| INT1PRIO | 0x40000024  | Interrupt 1 priority register.  |
| INT2PRIO | 0x40000028  | Interrupt 2 priority register.  |
| INT3PRIO | 0x4000002C  | Interrupt 3 priority register.  |
| INT4PRIO | 0x40000030  | Interrupt 4 priority register.  |
| INT5PRIO | 0x40000034  | Interrupt 5 priority register.  |
| INT6PRIO | 0x40000038  | Interrupt 6 priority register.  |
| INT7PRIO | 0x4000003C  | Interrupt 7 priority register.  |
| INTCON   | 0x40000040  | Interrupt control register.     |
| IRQID    | 0x40000044  | Current interrupt ID.           |
| INTSRC   | 0x40000048  | Interrupt source register.      |
| INTCLR   | 0x4000004C  | Interrupt clear register.       |
| INTSTAT  | 0x40000050  | Interrupt status register.      |

---

## General I/O and Peripheral Registers

Base Address: `0x20000000`

### GPIO Control Registers

| Register   | Address     | Description                           |
| :---       | :---        | :---                                  |
| DDRA       | 0x20000000  | PORTA direction register.             |
| PORTA      | 0x20000004  | PORTA input register.                 |
| LATA       | 0x20000008  | PORTA output latch register.          |
| DDRB       | 0x2000000C  | PORTB direction register.             |
| PORTB      | 0x20000010  | PORTB input register.                 |
| LATB       | 0x20000014  | PORTB output latch register.          |
| LATD       | 0x20000018  | Dedicated output port latch register. |
| ALTOUTACON | 0x2000001C  | PORTA alternate output control.       |
| ALTOUTBCON | 0x20000020  | PORTB alternate output control.       |
| ALTOUTEN   | 0x200000C8  | Alternate output enable.              |

---

### Timer Registers

#### Timer0 (DCT0)

| Register | Address     | Description             |
| :---     | :---        | :---                    |
| T0CON    | 0x2000002C  | Timer control register. |
| T0L      | 0x20000030  | Timer low register.     |
| T0H      | 0x20000034  | Timer high register.    |
| T0ABUF   | 0x20000038  | Timer A read buffer.    |
| T0BBUF   | 0x2000003C  | Timer B read buffer.    |

#### Timer1 (DCT1)

| Register | Address     | Description             |
| :---     | :---        | :---                    |
| T1CON    | 0x20000040  | Timer control register. |
| T1L      | 0x20000044  | Timer low register.     |
| T1H      | 0x20000048  | Timer high register.    |
| T1ABUF   | 0x2000004C  | Timer A read buffer.    |
| T1BBUF   | 0x20000050  | Timer B read buffer.    |

#### Timer2 (DCT2)

| Register | Address     | Description             |
| :---     | :---        | :---                    |
| T2CON    | 0x20000054  | Timer control register. |
| T2L      | 0x20000058  | Timer low register.     |
| T2H      | 0x2000005C  | Timer high register.    |
| T2ABUF   | 0x20000060  | Timer A read buffer.    |
| T2BBUF   | 0x20000064  | Timer B read buffer.    |

#### Timer3 (DCT3)

| Register | Address     | Description            |
| :---     | :---        | :---                   |
| T3CON    | 0x20000068  | Timer control registe. |
| T3L      | 0x2000006C  | Timer low register.    |
| T3H      | 0x20000070  | Timer high register.   |
| T3ABUF   | 0x20000074  | Timer A read buffer.   |
| T3BBUF   | 0x20000078  | Timer B read buffer.   |

#### Timer4 (ICT0)

| Register | Address     | Description             |
| :---     | :---        | :---                    |
| T4CON    | 0x2000007C  | Timer control register. |
| T4L      | 0x20000080  | Timer low register.     |
| T4H      | 0x20000084  | Timer high register.    |
| T4BUF    | 0x20000088  | Timer read buffer.      |
| TC0BUF   | 0x2000008C  | Counter read buffer.    |

#### Timer5 (ICT1)

| Register | Address     | Description             |
| :---     | :---        | :---                    |
| T5CON    | 0x20000090  | Timer control register. |
| T5L      | 0x20000094  | Timer low register.     |
| T5H      | 0x20000098  | Timer high register.    |
| T5BUF    | 0x2000009C  | Timer read buffer.      |
| TC1BUF   | 0x200000A0  | Counter read buffer.    |

#### Timer Flag Register

| Register | Address     | Description          |
| :---     | :---        | :---                 |
| TFREG    | 0x200000A4  | Timer flag register. |

---

### Interrupt Mapping Registers

| Register | Address     | Description                  |
| :---     | :---        | :---                         |
| INT0MAP  | 0x200000A8  | Interrupt0 mapping register. |
| INT1MAP  | 0x200000AC  | Interrupt1 mapping register. |
| INT2MAP  | 0x200000B0  | Interrupt2 mapping register. |
| INT3MAP  | 0x200000B4  | Interrupt3 mapping register. |
| INT4MAP  | 0x200000B8  | Interrupt4 mapping register. |
| INT5MAP  | 0x200000BC  | Interrupt5 mapping register. |
| INT6MAP  | 0x200000C0  | Interrupt6 mapping register. |
| INT7MAP  | 0x200000C4  | Interrupt7 mapping register. |

---

### UART Registers

#### UART0

| Register | Address     | Description                |
| :---     | :---        | :---                       |
| URT0CON  | 0x200000CC  | UART0 control register.    |
| URT0BRG  | 0x200000D0  | UART0 baud-rate generator. |
| URT0TX   | 0x200000D4  | UART0 transmit register.   |
| URT0RX   | 0x200000D8  | UART0 receive register.    |

#### UART1

| Register | Address     | Description                |
| :---     | :---        | :---                       |
| URT1CON  | 0x200000DC  | UART1 control register.    |
| URT1BRG  | 0x200000E0  | UART1 baud-rate generator. |
| URT1TX   | 0x200000E4  | UART1 transmit register.   |
| URT1RX   | 0x200000E8  | UART1 receive register.    |

---

### I2C Registers

| Register | Address     | Description             |
| :---     | :---        | :---                    |
| I2C0CON0 | 0x200000EC  | I2C control register 0. |
| I2C0CON1 | 0x200000F0  | I2C control register 1. |
| I2C0CON2 | 0x200000F4  | I2C control register 2. |
| I2C0TX   | 0x200000F8  | I2C transmit register.  |
| I2C0RX   | 0x200000FC  | I2C receive register.   |

---

### SPI Registers

| Register | Address     | Description             |
| :---     | :---        | :---                    |
| SPI0CON0 | 0x20000140  | SPI control register 0. |
| SPI0CON1 | 0x20000144  | SPI control register 1. |
| SPI0TX   | 0x20000148  | SPI transmit register.  |
| SPI0RX   | 0x2000014C  | SPI receive register.   |

---

### External Interrupt Registers

| Register | Address     | Description                           |
| :---     | :---        | :---                                  |
| EXT0CON  | 0x20000100  | External interrupt0 control register. |
| EXT1CON  | 0x20000104  | External interrupt1 control register. |
| EXT2CON  | 0x20000108  | External interrupt2 control register. |
| EXT3CON  | 0x2000010C  | External interrupt3 control register. |

---

### PWM Registers

| Register | Address     | Description               |
| :---     | :---        | :---                      |
| PWM0CON  | 0x20000110  | PWM0 control register.    |
| PWM0DC   | 0x20000114  | PWM0 duty-cycle register. |
| PWM1CON  | 0x20000118  | PWM1 control register.    |
| PWM1DC   | 0x2000011C  | PWM1 duty-cycle register. |
| PWM2CON  | 0x20000120  | PWM2 control register.    |
| PWM2DC   | 0x20000124  | PWM2 duty-cycle register. |
| PWM3CON  | 0x20000128  | PWM3 control register.    |
| PWM3DC   | 0x2000012C  | PWM3 duty-cycle register. |
| PWM4CON  | 0x20000130  | PWM4 control register.    |
| PWM4DC   | 0x20000134  | PWM4 duty-cycle register. |
| PWM5CON  | 0x20000138  | PWM5 control register.    |
| PWM5DC   | 0x2000013C  | PWM5 duty-cycle register. |

---