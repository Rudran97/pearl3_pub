# UART Module

The microcontroller has two Asynchronous Serial Communication modules URT0 and URT1. Each UART modules has separate TX and RX channels and can be configured to simulaneously transmit and receive data. Each module features the following characteristics:

* 16-bit Baud rate generator.
* Separate TX and RX channels.
* Can be configured to raise interrupt after transmission.
* Can be configured to raise interrupt after receiving new data.

The following registers are associated with each UART module:

**Note**: x = [0:1]

## UART Control Register (URTxCON)

| Bit   | Name    | Access | Description                                                                                |
| :---  | :---    | :---   | :---                                                                                       |
| 15:14 | -       | -      | -                                                                                          |
| 13:10 | RXPIN   | RW     | RX pin. Can be mapped to any pins of PORTA and PORTB for URT0 and URT1 respectively.       |
| 9:6   | TXPIN   | RW     | TX pin. Can be mapped to any pins of PORTA and PORTB for URT0 and URT1 respectively.       |
| 5     | FERR    | RO     | Frame error: `1 = Stop bit not received`.                                                  |
| 4     | RXIF    | RO     | Receive flag: `1 = New data received`. `RXIF` is cleared when `RXEN` is cleared.           |
| 3     | TXIF    | RO     | Transmit flag: `1 = Transmission complete`. `TXIF` is cleared when `TXEN` is cleared.      |
| 2     | ENBIT9  | RW     | If set, transmit/receive 9 bits (default 8 bits).                                          |
| 1     | RXEN    | RW     | If set, ready to receive.                                                                  |
| 0     | TXEN    | RW     | If set, start transmit.                                                                    |

## UART Baud Rate Generator Register (URTxBRG)

| Bit   | Access | Description      |
| :---  | :---   | :---             |
| 15:0  | RW     | Baud rate value. |

## UART Transmit Register (URTxTX)

| Bit  | Name   | Access | Description                                                                                                    |
| :--- | :---   | :---   | :---                                                                                                           |
| 15:9 | -      | -      | -                                                                                                              |
| 8    | TXBIT9 | RW     | `Bit 9`: If `URTxCON.ENBIT9 = 1` then transmit `TXBIT9` after `TXDATA`. Typically used to transmit parity bit. |
| 7:0  | TXDATA | RW     | 8-bit transmit data.                                                                                           |

## UART Receive Register (URTxRX)

| Bit  | Name   | Access | Description                                                                                         |
| :--- | :---   | :---   | :---                                                                                                |
| 15:9 | -      | -      | -                                                                                                   |
| 8    | RXBIT9 | RW     | `Bit 9`: If `URTxCON.ENBIT9 = 1` then store incoming 9th bit. Typically used to receive parity bit. |
| 7:0  | RXDATA | RW     | 8-bit received data.                                                                                |