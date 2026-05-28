library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.pearl3_soc_pkg.all;

entity pearl3_soc is
    port (
        pil_Mclk   : in std_logic;
        pil_nrst   : in std_logic;
        pil_DI     : in std_logic;
        pol_DO     : out std_logic;
        pbv_PORTA  : inout std_logic_vector(15 downto 0);
        pbv_PORTB  : inout std_logic_vector(15 downto 0);
        pov_PORTD  : out std_logic_vector(7 downto 0)
    );
end entity pearl3_soc;

architecture rtl of pearl3_soc is

    signal sv_PORTA : std_logic_vector(15 downto 0);
    signal sv_PORTB : std_logic_vector(15 downto 0);
    signal sv_DDRA  : std_logic_vector(15 downto 0);
    signal sv_DDRB  : std_logic_vector(15 downto 0);
    signal sv_LATA  : std_logic_vector(15 downto 0);
    signal sv_LATB  : std_logic_vector(15 downto 0);
    signal sv_LATD  : std_logic_vector(15 downto 0);

begin

    inst_pearl3_top : entity work.pearl3_top
        port map(
            pil_Mclk  => pil_Mclk,
            pil_nrst  => pil_nrst,
            pil_DI    => pil_DI,
            pol_DO    => pol_DO,
            piv_PORTA => sv_PORTA,
            piv_PORTB => sv_PORTB,
            pov_DDRA  => sv_DDRA,
            pov_DDRB  => sv_DDRB,
            pov_LATA  => sv_LATA,
            pov_LATB  => sv_LATB,
            pov_LATD  => sv_LATD
        );

    -----------------------------------------------------------------------------------------------------
    ----------------------------------------------PORT A-------------------------------------------------
    -----------------------------------------------------------------------------------------------------

    --- input ---

    sv_PORTA <= pbv_PORTA;

    --- output ---

    gen_PORTA : for ii in 0 to 15 generate
        pbv_PORTA(ii) <= sv_LATA(ii) when sv_DDRA(ii) = cl_GPIO_OUT else 'Z';
    end generate;

    -----------------------------------------------------------------------------------------------------
    ----------------------------------------------PORT B-------------------------------------------------
    -----------------------------------------------------------------------------------------------------

    --- input ---

    sv_PORTB <= pbv_PORTB;

    --- output ---

    gen_PORTB : for ii in 0 to 15 generate
        pbv_PORTB(ii) <= sv_LATB(ii) when sv_DDRB(ii) = cl_GPIO_OUT else 'Z';
    end generate;

    -----------------------------------------------------------------------------------------------------
    ----------------------------------------------PORT D-------------------------------------------------
    -----------------------------------------------------------------------------------------------------

    pov_PORTD <= sv_LATD(7 downto 0);

end architecture;