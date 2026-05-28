library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package spi_master_pkg is

    constant ci_clksrc_div : integer := 1;

    type tr_spi_con0 is record
        i_EN   : integer;
        i_CKE  : integer;
        i_CKP  : integer;
        i_IF   : integer;
        i_CLRF : integer;
        i_BRG0 : integer;
        i_BRG9 : integer;
    end record tr_spi_con0;

    constant ctr_spi_con0 : tr_spi_con0 := (
        i_EN   => 0,
        i_CKE  => 1,
        i_CKP  => 2,
        i_IF   => 3,
        i_CLRF => 4,
        i_BRG0 => 5,
        i_BRG9 => 14
    );

    type tr_spi_con1 is record
        i_SCLK_SEL0 : integer;
        i_SCLK_SEL1 : integer;
        i_SCLK_SEL2 : integer;
        i_SCLK_SEL3 : integer;
        i_SDO_SEL0  : integer;
        i_SDO_SEL1  : integer;
        i_SDO_SEL2  : integer;
        i_SDO_SEL3  : integer;
        i_SDI_SEL0  : integer;
        i_SDI_SEL1  : integer;
        i_SDI_SEL2  : integer;
        i_SDI_SEL3  : integer;
        i_SS_SEL0   : integer;
        i_SS_SEL1   : integer;
        i_SS_SEL2   : integer;
        i_SS_SEL3   : integer;
    end record tr_spi_con1;

    constant ctr_spi_con1 : tr_spi_con1 := (
        i_SCLK_SEL0 => 0,
        i_SCLK_SEL1 => 1,
        i_SCLK_SEL2 => 2,
        i_SCLK_SEL3 => 3,
        i_SDO_SEL0  => 4,
        i_SDO_SEL1  => 5,
        i_SDO_SEL2  => 6,
        i_SDO_SEL3  => 7,
        i_SDI_SEL0  => 8,
        i_SDI_SEL1  => 9,
        i_SDI_SEL2  => 10,
        i_SDI_SEL3  => 11,
        i_SS_SEL0   => 12,
        i_SS_SEL1   => 13,
        i_SS_SEL2   => 14,
        i_SS_SEL3   => 15
    );

end package;