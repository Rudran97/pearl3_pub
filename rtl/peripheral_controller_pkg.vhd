library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package peripheral_controller_pkg is

    type tr_altout_en is record
        i_URT0_ALT_EN : integer;
        i_URT1_ALT_EN : integer;
        i_I2C0_ALT_EN : integer;
        i_I2C1_ALT_EN : integer;
        i_SPI0_ALT_EN : integer;
        i_SPI1_ALT_EN : integer;
        i_PWM0_ALT_EN : integer;
        i_PWM1_ALT_EN : integer;
        i_PWM2_ALT_EN : integer;
        i_PWM3_ALT_EN : integer;
        i_PWM4_ALT_EN : integer;
        i_PWM5_ALT_EN : integer;
    end record tr_altout_en;

    constant ctr_altout_en : tr_altout_en := (
        i_URT0_ALT_EN => 0,
        i_URT1_ALT_EN => 1,
        i_I2C0_ALT_EN => 2,
        i_I2C1_ALT_EN => 3,
        i_SPI0_ALT_EN => 4,
        i_SPI1_ALT_EN => 5,
        i_PWM0_ALT_EN => 6,
        i_PWM1_ALT_EN => 7,
        i_PWM2_ALT_EN => 8,
        i_PWM3_ALT_EN => 9,
        i_PWM4_ALT_EN => 10,
        i_PWM5_ALT_EN => 11
    );

    type tr_int_map is record
        i_T0FA     : integer;
        i_T0FB     : integer;
        i_T1FA     : integer;
        i_T1FB     : integer;
        i_T2FA     : integer;
        i_T2FB     : integer;
        i_T3FA     : integer;
        i_T3FB     : integer;
        i_T4F      : integer;
        i_T4ICF    : integer;
        i_T5F      : integer;
        i_T5ICF    : integer;
        i_URT0RXIF : integer;
        i_URT0TXIF : integer;
        i_URT1RXIF : integer;
        i_URT1TXIF : integer;
        i_I2C0IF   : integer;
        i_I2C0BCLF : integer;
        i_I2C0TOTF : integer;
        i_I2C0DNF  : integer;
        i_SPI0IF   : integer;
        i_EXT0IN   : integer;
        i_EXT1IN   : integer;
        i_EXT2IN   : integer;
        i_EXT3IN   : integer;
    end record tr_int_map;

    constant ctr_int_map : tr_int_map := (
        i_T0FA     => 1,
        i_T0FB     => 2,
        i_T1FA     => 3,
        i_T1FB     => 4,
        i_T2FA     => 5,
        i_T2FB     => 6,
        i_T3FA     => 7,
        i_T3FB     => 8,
        i_T4F      => 9,
        i_T4ICF    => 10,
        i_T5F      => 11,
        i_T5ICF    => 12,
        i_URT0RXIF => 13,
        i_URT0TXIF => 14,
        i_URT1RXIF => 15,
        i_URT1TXIF => 16,
        i_I2C0IF   => 17,
        i_I2C0BCLF => 18,
        i_I2C0TOTF => 19,
        i_I2C0DNF  => 20,
        i_SPI0IF   => 21,
        i_EXT0IN   => 22,
        i_EXT1IN   => 23,
        i_EXT2IN   => 24,
        i_EXT3IN   => 25
    );

    type tr_ext_con is record
        i_EN        : integer;
        i_TRIG_EG   : integer;
        i_TRIG_SEL0 : integer;
        i_TRIG_SEL1 : integer;
        i_TRIG_SEL2 : integer;
        i_TRIG_SEL3 : integer;
    end record tr_ext_con;

    constant ctr_ext_con : tr_ext_con := (
        i_EN        => 0,
        i_TRIG_EG   => 1,
        i_TRIG_SEL0 => 2,
        i_TRIG_SEL1 => 3,
        i_TRIG_SEL2 => 4,
        i_TRIG_SEL3 => 5
    );

    type tr_pwm_con is record
        i_PWM_PR0  : integer;
        i_PWM_PR11 : integer;
        i_PWM_SEL0 : integer;
        i_PWM_SEL1 : integer;
        i_PWM_SEL2 : integer;
        i_PWM_SEL3 : integer;
    end record tr_pwm_con;

    constant ctr_pwm_con : tr_pwm_con := (
        i_PWM_PR0  => 0,
        i_PWM_PR11 => 11,
        i_PWM_SEL0 => 12,
        i_PWM_SEL1 => 13,
        i_PWM_SEL2 => 14,
        i_PWM_SEL3 => 15
    );

    --------------------------------------------------------------------------
    ------------------- I/0 MEMORY MAP (WORD OFFSET) -------------------------
    --------------------------------------------------------------------------

    --- GPIO registers ---

    constant ci_DDRA  : integer := 0;
    constant ci_PORTA : integer := 1;
    constant ci_LATA  : integer := 2;

    constant ci_DDRB  : integer := 3;
    constant ci_PORTB : integer := 4;
    constant ci_LATB  : integer := 5;

    constant ci_LATD : integer := 6;

    constant ci_ALTOUTACON : integer := 7;
    constant ci_ALTOUTBCON : integer := 8;
    constant ci_ALTOUTA    : integer := 9;
    constant ci_ALTOUTB    : integer := 10;

    --- Timer registers ---

    constant ci_T0CON  : integer := 11;
    constant ci_T0L    : integer := 12;
    constant ci_T0H    : integer := 13;
    constant ci_T0BUFL : integer := 14;
    constant ci_T0BUFH : integer := 15;

    constant ci_T1CON  : integer := 16;
    constant ci_T1L    : integer := 17;
    constant ci_T1H    : integer := 18;
    constant ci_T1BUFL : integer := 19;
    constant ci_T1BUFH : integer := 20;

    constant ci_T2CON  : integer := 21;
    constant ci_T2L    : integer := 22;
    constant ci_T2H    : integer := 23;
    constant ci_T2BUFL : integer := 24;
    constant ci_T2BUFH : integer := 25;

    constant ci_T3CON  : integer := 26;
    constant ci_T3L    : integer := 27;
    constant ci_T3H    : integer := 28;
    constant ci_T3BUFL : integer := 29;
    constant ci_T3BUFH : integer := 30;

    constant ci_T4CON  : integer := 31;
    constant ci_T4L    : integer := 32;
    constant ci_T4H    : integer := 33;
    constant ci_T4BUFL : integer := 34;
    constant ci_T4BUFH : integer := 35;

    constant ci_T5CON  : integer := 36;
    constant ci_T5L    : integer := 37;
    constant ci_T5H    : integer := 38;
    constant ci_T5BUFL : integer := 39;
    constant ci_T5BUFH : integer := 40;

    constant ci_TFREG : integer := 41;

    --- Interrupt mapping function registers ---

    constant ci_INT0MAP : integer := 42;
    constant ci_INT1MAP : integer := 43;
    constant ci_INT2MAP : integer := 44;
    constant ci_INT3MAP : integer := 45;
    constant ci_INT4MAP : integer := 46;
    constant ci_INT5MAP : integer := 47;
    constant ci_INT6MAP : integer := 48;
    constant ci_INT7MAP : integer := 49;

    --- ALT OUTPUT sel register ---

    constant ci_ALTOUTEN : integer := 50;

    --- UART controller registers ---

    constant ci_URT0CON : integer := 51;
    constant ci_URT0BRG : integer := 52;
    constant ci_URT0TX  : integer := 53;
    constant ci_URT0RX  : integer := 54;

    constant ci_URT1CON : integer := 55;
    constant ci_URT1BRG : integer := 56;
    constant ci_URT1TX  : integer := 57;
    constant ci_URT1RX  : integer := 58;

    --- I2C module registers ---

    constant ci_I2C0CON0 : integer := 59;
    constant ci_I2C0CON1 : integer := 60;
    constant ci_I2C0CON2 : integer := 61;
    constant ci_I2C0TX   : integer := 62;
    constant ci_I2C0RX   : integer := 63;

    --- External Trigger Control registers ---

    constant ci_EXT0CON : integer := 64;
    constant ci_EXT1CON : integer := 65;
    constant ci_EXT2CON : integer := 66;
    constant ci_EXT3CON : integer := 67;

    --- PWM module registers ---

    constant ci_PWM0CON : integer := 68;
    constant ci_PWM0DC  : integer := 69;

    constant ci_PWM1CON : integer := 70;
    constant ci_PWM1DC  : integer := 71;

    constant ci_PWM2CON : integer := 72;
    constant ci_PWM2DC  : integer := 73;

    constant ci_PWM3CON : integer := 74;
    constant ci_PWM3DC  : integer := 75;

    constant ci_PWM4CON : integer := 76;
    constant ci_PWM4DC  : integer := 77;

    constant ci_PWM5CON : integer := 78;
    constant ci_PWM5DC  : integer := 79;

    --- SPI module registers ---

    constant ci_SPI0CON0 : integer := 80;
    constant ci_SPI0CON1 : integer := 81;
    constant ci_SPI0TX   : integer := 82;
    constant ci_SPI0RX   : integer := 83;

end package;