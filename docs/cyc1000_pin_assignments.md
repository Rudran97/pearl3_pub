# FPGA Pin Assignments

The following table lists the pin assignments for the `pearl3_soc` design targeting the `cyc1000` development board with the `10CL025YU256C8G` FPGA.

The `Board Reference` names correspond to the official pin naming convention used in the CYC1000 user guide.

---

## System and Debug Interface

| Board Reference | FPGA Pin | pearl3_soc Pin    |
| :---            | :---     | :---              |
| CLK12M          | PIN_M2   | pil_Mclk          |
| USER_BTN        | PIN_N6   | pil_nrst          |
| AIN0            | PIN_R12  | pil_DI            |
| AREF            | PIN_P11  | pol_DO            |

---

## PORTD Assignments

| Board Reference | FPGA Pin | pearl3_soc Pin    |
| :---            | :---     | :---              |
| LED7            | PIN_N3   | pov_PORTD[7]      |
| LED6            | PIN_N5   | pov_PORTD[6]      |
| LED5            | PIN_R4   | pov_PORTD[5]      |
| LED4            | PIN_T2   | pov_PORTD[4]      |
| LED3            | PIN_R3   | pov_PORTD[3]      |
| LED2            | PIN_T3   | pov_PORTD[2]      |
| LED1            | PIN_T4   | pov_PORTD[1]      |
| LED0            | PIN_M6   | pov_PORTD[0]      |

---

## PORTA Assignments

| Board Reference | FPGA Pin | pearl3_soc Pin    |
| :---            | :---     | :---              |
| AIN1            | PIN_T13  | pbv_PORTA[0]      |
| AIN2            | PIN_R13  | pbv_PORTA[1]      |
| AIN3            | PIN_T14  | pbv_PORTA[2]      |
| AIN4            | PIN_P14  | pbv_PORTA[3]      |
| AIN5            | PIN_R14  | pbv_PORTA[4]      |
| AIN6            | PIN_T15  | pbv_PORTA[5]      |
| D0              | PIN_N16  | pbv_PORTA[6]      |
| D1              | PIN_L15  | pbv_PORTA[7]      |
| D2              | PIN_L16  | pbv_PORTA[8]      |
| D3              | PIN_K15  | pbv_PORTA[9]      |
| D4              | PIN_K16  | pbv_PORTA[10]     |
| D5              | PIN_J14  | pbv_PORTA[11]     |
| D6              | PIN_N2   | pbv_PORTA[12]     |
| D7              | PIN_N1   | pbv_PORTA[13]     |
| D8              | PIN_P2   | pbv_PORTA[14]     |
| D9              | PIN_J1   | pbv_PORTA[15]     |

---

## PORTB Assignments

`PORTB[6]`, `PORTB[6]`, `PORTB[6]` are not connected.

| Board Reference | FPGA Pin | pearl3_soc Pin    |
| :---            | :---     | :---              |
| D10             | PIN_J2   | pbv_PORTB[0]      |
| D11             | PIN_K2   | pbv_PORTB[1]      |
| D12             | PIN_L2   | pbv_PORTB[2]      |
| D13             | PIN_P1   | pbv_PORTB[3]      |
| D14             | PIN_R1   | pbv_PORTB[4]      |
| AIN             | PIN_T12  | pbv_PORTB[5]      |
| PIO_01          | PIN_F13  | pbv_PORTB[8]      |
| PIO_02          | PIN_F15  | pbv_PORTB[9]      |
| PIO_04          | PIN_D16  | pbv_PORTB[10]     |
| PIO_05          | PIN_D15  | pbv_PORTB[11]     |
| PIO_06          | PIN_C15  | pbv_PORTB[12]     |
| PIO_07          | PIN_B16  | pbv_PORTB[13]     |
| PIO_08          | PIN_C16  | pbv_PORTB[14]     |

---