library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package i2c_master_pkg is

    constant ci_clksrc_div : integer := 1;

    type tr_i2c_con0 is record
        i_EN      : integer;
        i_SEN     : integer;
        i_RSEN    : integer;
        i_PEN     : integer;
        i_TXEN    : integer;
        i_RXEN    : integer;
        i_ACKEN   : integer;
        i_ACKDAT  : integer;
        i_ACKSTAT : integer;
        i_IF      : integer;
        i_BCLF    : integer;
        i_TOTF    : integer;
        i_DN      : integer;
        i_CLRF    : integer; -- clears all flag and enable signals
    end record;

    constant ctr_i2c_con0 : tr_i2c_con0 := (
        i_EN      => 0,
        i_SEN     => 1,
        i_RSEN    => 2,
        i_PEN     => 3,
        i_TXEN    => 4,
        i_RXEN    => 5,
        i_ACKEN   => 6,
        i_ACKDAT  => 7,
        i_ACKSTAT => 8,
        i_IF      => 9,
        i_BCLF    => 10,
        i_TOTF    => 11,
        i_DN      => 12,
        i_CLRF    => 13
    );

    type tr_i2c_con1 is record
        i_BRG0 : integer;
        i_BRG9 : integer;
        i_TOT0 : integer;
        i_TOT5 : integer;
    end record;

    constant ctr_i2c_con1 : tr_i2c_con1 := (
        i_BRG0 => 0,
        i_BRG9 => 9,
        i_TOT0 => 10,
        i_TOT5 => 15
    );

    type tr_i2c_con2 is record
        i_SDA_SEL0 : integer;
        i_SDA_SEL1 : integer;
        i_SDA_SEL2 : integer;
        i_SDA_SEL3 : integer;
        i_SCL_SEL0 : integer;
        i_SCL_SEL1 : integer;
        i_SCL_SEL2 : integer;
        i_SCL_SEL3 : integer;
        i_SHTM0    : integer;
        i_SHTM1    : integer;
        i_SHTM2    : integer;
        i_SHTM3    : integer;
    end record tr_i2c_con2;

    constant ctr_i2c_con2 : tr_i2c_con2 := (
        i_SDA_SEL0 => 0,
        i_SDA_SEL1 => 1,
        i_SDA_SEL2 => 2,
        i_SDA_SEL3 => 3,
        i_SCL_SEL0 => 4,
        i_SCL_SEL1 => 5,
        i_SCL_SEL2 => 6,
        i_SCL_SEL3 => 7,
        i_SHTM0    => 8,
        i_SHTM1    => 9,
        i_SHTM2    => 10,
        i_SHTM3    => 11
    );

end package;