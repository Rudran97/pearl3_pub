# SPI Module

The microcontroller supports one SPI master interface. The transmission clock SCLK, is generated internally by a configurable SPI clock generator. The SPI module has the following characteristics:

* SPI master interface.
* 10-bit clock generator module.
* Can be configured to work in four different SPI modes.
* Automatically works in full-duplex mode.
* Can be configured to raise interrupt after SPI operation is complete.

The following registers are associated with the SPI module:

## SPI0 Control Register 0 (SPI0CON0)

| Bit   | Name    | Access | Description                                                                                      |
| :---  | :---    | :---   | :---                                                                                             |
| 15    | -       | -      | -                                                                                                |
| 14:5  | BRG     | RW     | Baud rate value for SPI clock.                                                                   |
| 4     | CLRF    | RW     | `1 = Clear all status flags and SPIEN`.                                                          |
| 3     | SPIIF   | RO     | SPI flag: `1 = SPI operation complete`. `SPIIF` is cleared when `CLRF` is `1` or `SPIEN` is `0`. |
| 2     | CKP     | RW     | Clock polarity: `0 = SCLK idle at logic low`, `1 = SCLK idle at logic high`.                     |
| 1     | CKE     | RW     | Input sampling phase: `0 = At second clock transition`, `1 = At first clock transition`.         |
| 0     | SPIEN   | RW     | `1 = Start SPI transmit and receive`. Works in full-duplex mode.                                 |

### SPI Mode

| Mode | CKP  | CKE  | Description                                           |
| :--- | ---: | ---: | :---                                                  |
| 0    | 0    | 1    | Clock idles low. Sampling at rising edge of `SCLK`.   |
| 1    | 0    | 0    | Clock idles low. Sampling at falling edge of `SCLK`.  |
| 2    | 1    | 1    | Clock idles high. Sampling at falling edge of `SCLK`. |
| 3    | 1    | 0    | Clock idles high. Sampling at rising edge of `SCLK`.  |

## SPI0 Control Register 1 (SPI0CON1)

| Bit   | Name    | Access | Description                                           |
| :---  | :---    | :---   | :---                                                  |
| 15:12 | SCLKPIN | RW     | SPI clock pin. Can be mapped to any pins of PORTB.    |
| 11:8  | SDOPIN  | RW     | MOSI pin. Can be mapped to any pins of PORTB.         |
| 7:4   | SDIPIN  | RW     | MISO pin. Can be mapped to any pins of PORTB.         |
| 3:0   | SSPIN   | RW     | Slave select pin. Can be mapped to any pins of PORTB. |

## SPI0 Transmit Register (SPI0TX)

| Bit  | Access | Description          |
| :--- | :---   | :---                 |
| 15:8 | -      | -                    |
| 7:0  | RW     | 8-bit transmit data. |

## SPI0 Receive Register (SPI0RX)

| Bit  | Access | Description         |
| :--- | :---   | :---                |
| 15:8 | -      | -                   |
| 7:0  | RO     | 8-bit receive data. |