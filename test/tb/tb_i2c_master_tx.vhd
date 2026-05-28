library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_i2c_master_tx is
end entity;

architecture rtl of tb_i2c_master_tx is

    signal pil_clk : std_logic := '1';
    signal pil_rst : std_logic := '1';

    signal pil_scl    : std_logic;
    signal pol_scl    : std_logic;
    signal pol_scl_oe : std_logic;
    signal pil_sda    : std_logic;
    signal pol_sda    : std_logic;
    signal pol_sda_oe : std_logic;

    signal piv_baud_rate      : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(79, 10)); --- 400kHz freq
    signal piv_tot_rate       : std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(24, 6)); --- 384 >> 4 -- sets 20 ms tot
    signal piv_set_hold_rate  : std_logic_vector(3 downto 0) := std_logic_vector(to_unsigned(1, 4));
    signal piv_master_control : std_logic_vector(6 downto 0) := (others => '0');
    signal piv_tx_data        : std_logic_vector(7 downto 0) := (others => '0');
    signal pov_rx_data        : std_logic_vector(7 downto 0);
    signal pil_ack            : std_logic := '1';
    signal pol_ack            : std_logic;
    signal pol_master_if      : std_logic;
    signal pol_master_bclf    : std_logic;
    signal pol_master_bus_to  : std_logic;
    signal pol_clr_enable     : std_logic;

    ---

    signal sl_sda_bus : std_logic := '1';
    signal sl_scl_bus : std_logic := '1';

    constant ct_clk_period : time := 15.625 ns;

    alias al_interface_enable : std_logic is piv_master_control(0);
    alias al_master_sen       : std_logic is piv_master_control(1);
    alias al_master_rsen      : std_logic is piv_master_control(2);
    alias al_master_pen       : std_logic is piv_master_control(3);
    alias al_master_txen      : std_logic is piv_master_control(4);
    alias al_master_rxen      : std_logic is piv_master_control(5);
    alias al_master_acken     : std_logic is piv_master_control(6);

begin

    i2c_master_top_inst : entity work.i2c_master_top
        port map(
            pil_clk            => pil_clk,
            pil_rst            => pil_rst,
            piv_baud_rate      => piv_baud_rate,
            piv_tot_rate       => piv_tot_rate,
            piv_set_hold_rate  => piv_set_hold_rate,
            piv_master_control => piv_master_control,
            piv_tx_data        => piv_tx_data,
            pov_rx_data        => pov_rx_data,
            pil_ack            => pil_ack,
            pol_ack            => pol_ack,
            pil_scl            => pil_scl,
            pol_scl            => pol_scl,
            pol_scl_oe         => pol_scl_oe,
            pil_sda            => pil_sda,
            pol_sda            => pol_sda,
            pol_sda_oe         => pol_sda_oe,
            pol_master_if      => pol_master_if,
            pol_master_bclf    => pol_master_bclf,
            pol_master_bus_to  => pol_master_bus_to,
            pol_I2C_done     => pol_clr_enable
        );

    pil_clk <= not pil_clk after ct_clk_period / 2;
    pil_rst <= '0' after ct_clk_period / 2;

    pil_sda <= pol_sda when pol_sda_oe = '1' else sl_sda_bus;
    pil_scl <= pol_scl when pol_scl_oe = '1' else sl_scl_bus;

    proc_stimuli : process
    begin

        wait for ct_clk_period * 2;

        al_interface_enable <= '1';

        wait for ct_clk_period * 20;

        al_master_sen <= '1';

        wait until pol_master_if = '1';

        report "START CONDITION COMPLETE!" severity note;

        wait until pol_clr_enable = '1';

        al_master_sen <= '0';

        wait for ct_clk_period * 20;

        piv_tx_data <= "01001010";

        al_master_txen <= '1';

        for ii in 0 to 7 loop
            wait until falling_edge(pil_scl);
            if ii = 7 then
                sl_sda_bus <= '0';
            end if;
        end loop;
        
        wait until pol_master_if = '1';

        report "DEVICE ADDRESS SENT" severity note;

        wait until pol_clr_enable = '1';

        sl_sda_bus <= '1';

        al_master_txen <= '0';

        wait for ct_clk_period * 20;

        al_master_rsen <= '1';

        wait until pol_master_if = '1';

        report "REPEATED START COMPLETE!" severity note;

        wait until pol_clr_enable = '1';

        al_master_rsen <= '0';

        wait for ct_clk_period * 20;

        al_master_rxen <= '1';

        wait until pol_master_if = '1';

        report "RECEIVED DATA FROM SLAVE!" severity note;

        wait until pol_clr_enable = '1';

        al_master_rxen <= '0';

        wait for ct_clk_period * 20;

        pil_ack <= '1';

        al_master_acken <= '1';

        wait until pol_master_if = '1';

        report "SENT NACK!" severity note;

        wait until pol_clr_enable = '1';

        al_master_acken <= '0';

        wait for ct_clk_period * 20;

        al_master_pen <= '1';

        wait until pol_master_if = '1';

        report "STOP CONDITION SENT" severity note;

        wait until pol_clr_enable = '1';

        al_master_pen <= '0';

        wait for ct_clk_period * 20;

        al_interface_enable <= '0';

        -- pil_scl <= '0';

        -- wait until pol_clr_sen = '1';

        wait for ct_clk_period * 2;

        -- pil_sen <= '0';

        -- wait for ct_clk_period * 2;
        -- assert false severity failure;

        wait;
    end process proc_stimuli;

end architecture;