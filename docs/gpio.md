# GPIO Ports

The microcontroller has two configurable input/output ports called GPIO PORTA and GPIO PORTB. Each of these ports consists of 16 pins. These pins are multiplexed with other peripheral modules and performs specific functions. Additionally the microcontroller has 16-bit dedicated output port out of which 8 of them are connected to the on-board LEDs of the FPGA.

## Port A

### Data Direction Register (DDRA)

| Bit  | Access | Description                                             |
| :--- | :---   | :---                                                    |
| 15:0 | RW     | Pin direction: `0 = Set as output`, `1 = Set as input`. |

### Data Input Register (PORTA)

| Bit  | Access | Description                                        |
| :--- | :---   | :---                                               |
| 15:0 | RO     | Read pin state: `0 = Logic low`, `1 = Logic High`. |

### Data Output Register (LATA)

| Bit  | Access | Description                                       |
| :--- | :---   | :---                                              |
| 15:0 | RW     | Set pin state: `0 = Logic low`, `1 = Logic High`. |

### Alternate Output Control Register (ALTOUTACON)

| Bit  | Access | Description                                                                       |
| :--- | :---   | :---                                                                              |
| 15:0 | RW     | `0 = Output regular LATA value`, `1 = Output alternate function on specific pin`. |

## Port B

### Data Direction Register (DDRB)

| Bit  | Access | Description                                             |
| :--- | :---   | :---                                                    |
| 15:0 | RW     | Pin direction: `0 = Set as output`, `1 = Set as input`. |

### Data Input Register (PORTB)

| Bit  | Access | Description                                        |
| :--- | :---   | :---                                               |
| 15:0 | RO     | Read pin state: `0 = Logic low`, `1 = Logic High`. |

### Data Output Register (LATB)

| Bit  | Access | Description                                       |
| :--- | :---   | :---                                              |
| 15:0 | RW     | Set pin state: `0 = Logic low`, `1 = Logic High`. |

### Alternate Output Control Register (ALTOUTBCON)

| Bit  | Access | Description                                                                       |
| :--- | :---   | :---                                                                              |
| 15:0 | RW     | `0 = Output regular LATB value`, `1 = Output alternate function on specific pin`. |

## Select Alternate functions (ALTOUTEN)

Alternate functions on PORTA and PORTB can be selected by writing into `ALTOUTEN` register.

| Bit   | Name   | Access | Description                                 |
| :---  | :---   | :---   | :---                                        |
| 15:12 | -      | -      | -                                           |
| 11    | ENPWM5 | RW     | `1 = Enable PWM5 on GPIO PORTB`.            |
| 10    | ENPWM4 | RW     | `1 = Enable PWM4 on GPIO PORTB`.            |
| 9     | ENPWM3 | RW     | `1 = Enable PWM3 on GPIO PORTB`.            |
| 8     | ENPWM2 | RW     | `1 = Enable PWM2 on GPIO PORTA`.            |
| 7     | ENPWM1 | RW     | `1 = Enable PWM1 on GPIO PORTA`.            |
| 6     | ENPWM0 | RW     | `1 = Enable PWM0 on GPIO PORTA`.            |
| 5     | -      | -      | -                                           |
| 4     | ENSPI0 | RW     | `1 = Enable SPI0 on GPIO PORTB`.            |
| 3     | -      | -      | -                                           |
| 2     | ENI2C0 | RW     | `1 = Enable I2C0 on GPIO PORTA`.            |
| 1     | ENURT1 | RW     | `1 = Enable UART1 TX output on GPIO PORTB`. |
| 0     | ENURT0 | RW     | `1 = Enable UART0 TX output on GPIO PORTA`. |