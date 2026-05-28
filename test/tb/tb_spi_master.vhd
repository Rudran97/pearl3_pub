library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spi_master is
end entity;

architecture rtl of tb_spi_master is

    signal pil_clk : std_logic := '1';
    signal pil_rst : std_logic := '1';

    signal piv_baud_rate      : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(5, 10)); -- 10 MHz
    signal piv_master_control : std_logic_vector(2 downto 0) := (others => '0');
    signal piv_tx_data        : std_logic_vector(7 downto 0) := (others => '0');
    signal pov_rx_data        : std_logic_vector(7 downto 0);
    signal pol_sclk           : std_logic;
    signal pol_sdo            : std_logic;
    signal pil_sdi            : std_logic := '0';
    signal pol_nss            : std_logic;
    signal pol_master_if      : std_logic;

    constant ct_clk_period : time := 15.626 ns;

    alias al_interface_enable : std_logic is piv_master_control(0);
    alias av_spi_ckp_cke_mode : std_logic_vector(1 downto 0) is piv_master_control(2 downto 1);

begin

    pil_sdi <= pol_sdo;

    dut_spi_master_top : entity work.spi_master_top
        port map(
            pil_clk            => pil_clk,
            pil_rst            => pil_rst,
            piv_baud_rate      => piv_baud_rate,
            piv_master_control => piv_master_control,
            piv_tx_data        => piv_tx_data,
            pov_rx_data        => pov_rx_data,
            pol_sclk           => pol_sclk,
            pol_sdo            => pol_sdo,
            pil_sdi            => pil_sdi,
            pol_nss            => pol_nss,
            pol_master_if      => pol_master_if
        );

    pil_clk <= not pil_clk after ct_clk_period / 2;
    pil_rst <= '0' after ct_clk_period / 2;

    proc_stimuli : process
    begin

        av_spi_ckp_cke_mode <= "10";

        piv_tx_data <= "01001010";

        wait for ct_clk_period * 2;

        al_interface_enable <= '1';

        wait until pol_master_if = '1';

        wait for ct_clk_period;

        al_interface_enable <= '0';

        wait for ct_clk_period * 5;

        assert (false) severity failure;

    end process proc_stimuli;

end architecture;