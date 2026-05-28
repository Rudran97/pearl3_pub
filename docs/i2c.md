# I2C Module

The microcontroller supports one I2C master interface to communicate with upto 128 I2C devices. The transmission clock SCL, is generated internally by a configurable I2C clock generator. The I2C module has the following characteristics:

* I2C master interface.
* Configurable device address. 
* 10-bit clock generator module.
* Can be configured to raise various interrupts after each I2C operations.

The following registers are associated with the I2C module:

## I2C0 Control Register 0 (I2C0CON0)

| Bit   | Name    | Access | Description                                                                   |
| :---  | :---    | :---   | :---                                                                          |
| 15:14 | -       | -      | -                                                                             |
| 13    | CLRF    | RW     | `1 = Clear all status flags and enable signals except I2CEN`.                 |
| 12    | I2CDNF  | RO     | done flag: `1 = I2C module completed execution`.                              |
| 11    | I2CTOTF | RO     | timeout flag: `1 = I2C operation timed-out`.                                  |
| 10    | I2CBCLF | RO     | bus collision flag: `1 = Bus collision occurred executing current operation`. |
| 9     | I2CIF   | RO     | `1 = I2C operation completed without errors`.                                 |
| 8     | ACKSTAT | RO     | Acknowledgement status response from slave: `0 = Ack`, `1 = Nack`.            |
| 7     | ACKDAT  | RW     | Acknowledgement data bit to be sent to the slave.                             |
| 6     | ACKEN   | RW     | If set, transmit `ACKDAT`.                                                    |
| 5     | RXEN    | RW     | If set, receive data from slave.                                              |
| 4     | TXEN    | RW     | If set, transmit contents of `I2C0TX` register.                               |
| 3     | PEN     | RW     | If set, send stop condition.                                                  |
| 2     | RSEN    | RW     | If set, repeat start condition.                                               |
| 1     | SEN     | RW     | If set, send start condition.                                                 |
| 0     | I2CEN   | RW     | Module enable.                                                                |

## I2C0 Control Register 1 (I2C0CON1)

| Bit   | Name | Access | Description                                                   |
| :---  | :--- | :---   | :---                                                          |
| 15:10 | TOT  | RW     | Timeout timer value. This is set to `(TOT << 4) x 15.625 us`. |
| 9:0   | BRG  | RW     | Baud rate value for I2C clock.                                |

## I2C0 Control Register 2 (I2C0CON2)

| Bit   | Name   | Access | Description                                                         |
| :---  | :---   | :---   | :---                                                                |
| 15:13 | -      | -      | -                                                                   |
| 12:8  | SHTM   | RW     | Setup and hold timer value. This is set to `(SHTM << 4) x 0.25 us`. |
| 7:4   | SCLPIN | RW     | I2C clock pin. Can be mapped to any pins of PORTA.                  |
| 3:0   | SDAPIN | RW     | I2C data pin. Can be mapped to any pins of PORTA.                   |

## I2C0 Transmit Register (I2C0TX)

| Bit  | Access | Description          |
| :--- | :---   | :---                 |
| 15:8 | -      | -                    |
| 7:0  | RW     | 8-bit transmit data. |

## I2C0 Receive Register (I2C0RX)

| Bit  | Access | Description         |
| :--- | :---   | :---                |
| 15:8 | -      | -                   |
| 7:0  | RO     | 8-bit receive data. |