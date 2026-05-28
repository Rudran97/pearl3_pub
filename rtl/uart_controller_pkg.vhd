library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package uart_controller_pkg is

    constant ci_clksrc_div : integer := 1;

    type tr_uart_con is record
        i_TXEN    : integer;
        i_RXEN    : integer;
        i_ENBIT9  : integer;
        i_TXIF    : integer;
        i_RXIF    : integer;
        i_FERR    : integer;
        i_TX_SEL0 : integer;
        i_TX_SEL1 : integer;
        i_TX_SEL2 : integer;
        i_TX_SEL3 : integer;
        i_RX_SEL0 : integer;
        i_RX_SEL1 : integer;
        i_RX_SEL2 : integer;
        i_RX_SEL3 : integer;
    end record tr_uart_con;

    constant ctr_uart_con : tr_uart_con := (
        i_TXEN    => 0,
        i_RXEN    => 1,
        i_ENBIT9  => 2,
        i_TXIF    => 3,
        i_RXIF    => 4,
        i_FERR    => 5,
        i_TX_SEL0 => 6,
        i_TX_SEL1 => 7,
        i_TX_SEL2 => 8,
        i_TX_SEL3 => 9,
        i_RX_SEL0 => 10,
        i_RX_SEL1 => 11,
        i_RX_SEL2 => 12,
        i_RX_SEL3 => 13
    );

end package;