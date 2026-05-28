# Timers and Event Capture

The microcontroller supports six timer modules which are divided into two categories - Dual Compare Timer (DCT), and Input Capture Timer (ICT).

## Dual Compare Timer (DCT)

Timer modules TIMER0, TIMER1, TIMER2, and TIMER3 represents the Dual Compare Timers. There are four Dual Compare Timer modules (DCT0, DCT1, DCT2, and DCT3). Each module features the following characteristics:

* Each DCTx have two 16-bit timers.
* 16-bit Prescale for input clock division.
* Both timers can be configured and run independently from each other.
* Can be configured to raise interrupt when TxAF flag is set.
* Can be configured to raise interrupt when TxBF flag is set.

The following registers are associated with each DCT module:

**Note**: x = [0:3]

### DCT Control Register (TxCON)

| Bit  | Name    | Access | Description                                                                                |
| :--- | :---    | :---   | :---                                                                                       |
| 15:6 | -       | -      | -                                                                                          |
| 5    | TxBCLRF | RW     | Clear timer B flag bit (`TFREG.TxBF = 0`). `TxBCLRF` is automatically cleared by Hardware. |
| 4    | TxACLRF | RW     | Clear timer A flag bit (`TFREG.TxAF = 0`). `TxACLRF` is automatically cleared by Hardware. |
| 3    | TxBSET  | RW     | If set, set up Timer B. `TxBSET` is automatically cleared by Hardware.                     |
| 2    | TxASET  | RW     | If set, set up Timer A. `TxASET` is automatically cleared by Hardware.                     |
| 1    | TxBON   | RW     | If set, start Timer B.                                                                     |
| 0    | TxAON   | RW     | If set, start Timer A.                                                                     |

### Timer Input Buffer Low Register (TxL)

| Bit   | Access | Description     |
| :---  | :---   | :---            |
| 15:0  | RW     | Prescale value. |

### Timer Input Buffer High Register (TxH)

| Bit   | Access | Description        |
| :---  | :---   | :---               |
| 15:0  | RW     | Timer match value. |

### Timer A Read Buffer (TxABUF)

| Bit   | Access | Description                           |
| :---  | :---   | :---                                  |
| 15:0  | RO     | Timer A value after timer is stopped. |

### Timer B Read Buffer (TxBBUF)

| Bit   | Access | Description                           |
| :---  | :---   | :---                                  |
| 15:0  | RO     | Timer B value after timer is stopped. |

---

## Input Capture Timer (ICT)

Timer modules TIMER4 and TIMER5 represents the Input Capture Timers. There are two Input Capture Timer modules (ICT0 and ICT1). Each module can be configured either as a regular 16-bit timer or an event counter triggered by external pin event. They feature the following characteristics:

* As timer mode:
    * 16-bit Timer.
    * 16-bit Prescale for input clock division.
    * Can be configured to raise interrupt when TxF flag is set.

* As event counter:
    * 16-bit Counter.
    * 16-bit Prescale for input clock division.
    * Configurable trigger edge for event start and stop pin.
    * ICT0 start and stop pins are multiplexed with PORTB[0:3].
    * ICT1 start and stop pins are multiplexed with PORTB[4:7].
    * Can be configured to raise interrupt when TxICF flag is set.

The following registers are associated with each ICT module:

**Note**: x = [4:5], y = [0:1]

### ICT Control Register (TxCON)

| Bit   | Name        | Access | Description                                                                                        |
| :---  | :---        | :---   | :---                                                                                               |
| 15:12 | -           | -      | -                                                                                                  |
| 11    | TICyCLRF    | RW     | Clear event capture flag bit (`TFREG.TxICF = 0`). `TICyCLRF` is automatically cleared by Hardware. |
| 10    | TxCLRF      | RW     | Clear timer flag bit (`TFREG.TxF = 0`). `TxCLRF` is automatically cleared by Hardware.             |
| 9:8   | ICyPPIN     | RW     | Event counter stop pin. Mapped to PORTB[7:0] (`00000y[ICySPIN]`).                                  |
| 7:6   | ICySPIN     | RW     | Event counter start pin. Mapped to PORTB[7:0] (`00000y[ICySPIN]`).                                 |
| 5     | TxSET       | RW     | If set, set up Timer. `TxSET` is automatically cleared by Hardware.                                |
| 4     | TICySET     | RW     | If set, set up Event counter. `TICySET` is automatically cleared by Hardware.                      |
| 3     | ICyPPOL     | RW     | `0 = Stop event counter at falling edge`, `1 = Stop event counter at rising edge`.                 |
| 2     | ICySPOL     | RW     | `0 = Start event counter at falling edge`, `1 = Start event counter at rising edge`.               |
| 1     | TxMODE      | RW     | `0 = Timer mode`, `1 = Event counter mode`.                                                        |
| 0     | TxON/TICyON | RW     | If set, start Timer/Event counter.                                                                 |

### Timer Input Buffer Low Register (TxL)

| Bit   | Access | Description     |
| :---  | :---   | :---            |
| 15:0  | RW     | Prescale value. |

### Timer Input Buffer High Register (TxH)

| Bit   | Access | Description                                                                                  |
| :---  | :---   | :---                                                                                         |
| 15:0  | RW     | Timer/Counter match value. In Event counter mode set this to `0xffff` to not overflow early. |

### Timer Read Buffer (TxBUF)

| Bit   | Access | Description                         |
| :---  | :---   | :---                                |
| 15:0  | RO     | Timer value after timer is stopped. |

### Counter Read Buffer (TCyBUF)

| Bit   | Access | Description                                     |
| :---  | :---   | :---                                            |
| 15:0  | RO     | Counter value after an event has been captured. |

---

## Timer Flag Register (TFREG)

The microcontroller stores the timer match and event capture flags in a dedicated register:

| Bit   | Name   | Access | Description                 |
| :---  | :---   | :---   | :---                        |
| 15:12 | -      | -      | -                           |
| 11    | T5ICF  | RO     | Timer 5 input capture flag. |
| 10    | T5F    | RO     | Timer 5 match flag.         |
| 9     | T4ICF  | RO     | Timer 4 input capture flag. |
| 8     | T4F    | RO     | Timer 4 match flag.         |
| 7     | T3BF   | RO     | Timer 3B match flag.        |
| 6     | T3AF   | RO     | Timer 3A match flag.        |
| 5     | T2BF   | RO     | Timer 2B match flag.        |
| 4     | T2AF   | RO     | Timer 2A match flag.        |
| 3     | T1BF   | RO     | Timer 1B match flag.        |
| 2     | T1AF   | RO     | Timer 1A match flag.        |
| 1     | T0BF   | RO     | Timer 0B match flag.        |
| 0     | T0AF   | RO     | Timer 0A match flag.        |