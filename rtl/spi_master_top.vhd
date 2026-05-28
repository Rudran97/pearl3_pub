-----------------------------------------------------------------------------------------------------
--------------------------------------------SPI MASTER TOP-------------------------------------------
-----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.spi_master_pkg.all;

entity spi_master_top is
    port (
        pil_clk            : in std_logic;
        pil_rst            : in std_logic;
        piv_baud_rate      : in std_logic_vector(9 downto 0);
        piv_master_control : in std_logic_vector(2 downto 0);
        piv_tx_data        : in std_logic_vector(7 downto 0);
        pov_rx_data        : out std_logic_vector(7 downto 0);

        pol_sclk : out std_logic;
        pol_sdo  : out std_logic;
        pil_sdi  : in std_logic;
        pol_nss  : out std_logic;

        pol_master_if : out std_logic
    );
end entity;

architecture rtl of spi_master_top is

    type t_master_stage is (
        st_idle,
        st_data_handler,
        st_wait,
        st_disable_nss,
        st_done
    );
    signal st_master_stage : t_master_stage;

    signal sl_nss : std_logic;

    signal sl_master_if : std_logic;
    signal sv_rx_data   : std_logic_vector(7 downto 0);

    signal sl_brg_counter_en         : std_logic;
    signal sl_brg_counter_match_flag : std_logic;

    signal si_bit_index_count : integer range 0 to 7;

    --- spi bit handler ---
    signal sl_spi_en                   : std_logic;
    signal sl_brg_pulse                : std_logic;
    signal sl_bit_handler_en_brg_count : std_logic;
    signal sl_tx                       : std_logic;
    signal sl_rx                       : std_logic;
    signal sl_done                     : std_logic;

    alias al_interface_enable : std_logic is piv_master_control(0);

    --- spi component ---

    component spi_bit_handler is
        port (
            pil_clk              : in std_logic;
            pil_rst              : in std_logic;
            pil_spi_en           : in std_logic;
            pil_brg_pulse        : in std_logic;
            pol_enable_brg_count : out std_logic;
            piv_spi_mode         : in std_logic_vector(1 downto 0);
            pil_tx_data          : in std_logic;
            pol_rx_data          : out std_logic;
            pol_rx_valid         : out std_logic;
            pol_sclk             : out std_logic;
            pol_sdo              : out std_logic;
            pil_sdi              : in std_logic;
            pol_done             : out std_logic
        );
    end component;

begin

    proc_master_controller : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_nss             <= '1';
            sl_master_if       <= '0';
            sl_spi_en          <= '0';
            sl_tx              <= '0';
            sv_rx_data         <= (others => '0');
            si_bit_index_count <= 0;
        elsif rising_edge(pil_clk) then
            case st_master_stage is
                when st_idle =>
                    sl_nss       <= '1';
                    sl_master_if <= '0';
                    if al_interface_enable = '1' then
                        st_master_stage <= st_data_handler;
                    end if;
                when st_data_handler =>
                    sl_nss            <= '0';
                    sl_spi_en         <= '1';
                    sl_tx             <= piv_tx_data(7 - si_bit_index_count);
                    sl_brg_counter_en <= sl_bit_handler_en_brg_count;
                    if sl_done = '1' then
                        sl_spi_en                          <= '0';
                        sv_rx_data(7 - si_bit_index_count) <= sl_rx;
                        if si_bit_index_count < 7 then
                            si_bit_index_count <= si_bit_index_count + 1;
                            st_master_stage    <= st_wait;
                        else
                            si_bit_index_count <= 0;
                            st_master_stage    <= st_disable_nss;
                        end if;
                    end if;
                when st_wait =>
                    if sl_done = '0' then
                        st_master_stage <= st_data_handler;
                    end if;
                when st_disable_nss =>
                    sl_brg_counter_en <= '1';
                    if sl_brg_pulse = '1' then
                        sl_brg_counter_en <= '0';
                        sl_nss            <= '1';
                        st_master_stage <= st_done;
                    end if;
                when st_done =>
                    sl_master_if <= '1';
                    if al_interface_enable = '0' then
                        sl_master_if    <= '0';
                        st_master_stage <= st_idle;
                    end if;
            end case;
        end if;
    end process proc_master_controller;

    -----------------------------------------------------------------------------------------------------
    ------------------------------------------BAUD RATE GENERATOR----------------------------------------
    -----------------------------------------------------------------------------------------------------

    inst_baud_rate_generator : entity work.counter
        generic map(
            gi_counter_width => 10,
            gi_clksrc_div    => ci_clksrc_div
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            piv_counter_control     => '1' & sl_brg_counter_en,
            piv_counter_prescale => (others => '0'),
            piv_counter_match_value => piv_baud_rate,
            pov_counter_value       => open,
            pol_counter_match_flag  => sl_brg_counter_match_flag
        );

    -----------------------------------------------------------------------------------------------------
    -----------------------------------------SPI MASTER COMPONENT----------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_brg_pulse <= sl_brg_counter_match_flag;

    inst_spi_bit_handler : spi_bit_handler
    port map(
        pil_clk              => pil_clk,
        pil_rst              => pil_rst,
        pil_spi_en           => sl_spi_en,
        pil_brg_pulse        => sl_brg_pulse,
        pol_enable_brg_count => sl_bit_handler_en_brg_count,
        piv_spi_mode         => piv_master_control(2 downto 1),
        pil_tx_data          => sl_tx,
        pol_rx_data          => sl_rx,
        pol_rx_valid         => open,
        pol_sclk             => pol_sclk,
        pol_sdo              => pol_sdo,
        pil_sdi              => pil_sdi,
        pol_done             => sl_done
    );

    pol_master_if <= sl_master_if;
    pol_nss       <= sl_nss;

    pov_rx_data <= sv_rx_data;

end architecture;

-----------------------------------------------------------------------------------------------------
-------------------------------------------SPI BIT HANDLER-------------------------------------------
-----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_bit_handler is
    port (
        pil_clk              : in std_logic;
        pil_rst              : in std_logic;
        pil_spi_en           : in std_logic;
        pil_brg_pulse        : in std_logic;
        pol_enable_brg_count : out std_logic;
        piv_spi_mode         : in std_logic_vector(1 downto 0);
        pil_tx_data          : in std_logic;
        pol_rx_data          : out std_logic;
        pol_rx_valid         : out std_logic;
        pol_sclk             : out std_logic;
        pol_sdo              : out std_logic;
        pil_sdi              : in std_logic;
        pol_done             : out std_logic
    );
end entity;

architecture rtl of spi_bit_handler is

    constant cl_cke_atoi : std_logic := '1';
    constant cl_cke_itoa : std_logic := '0';

    type t_bit_handler is (
        st_idle,
        st_spi_cke1_le,
        st_spi_cke1_te,
        st_spi_cke0_le,
        st_spi_cke0_te,
        st_done
    );
    signal st_bit_handler : t_bit_handler;

    signal sl_done : std_logic;

    signal sl_brg_count_en : std_logic;

    signal sl_rx_data  : std_logic;
    signal sl_rx_valid : std_logic;

    signal sl_sclk : std_logic;
    signal sl_sdo  : std_logic;

    alias al_spi_cpk : std_logic is piv_spi_mode(1);
    alias al_spi_cke : std_logic is piv_spi_mode(0);

begin

    proc_nit_handler : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_brg_count_en <= '0';
            sl_rx_data      <= '0';
            sl_rx_valid     <= '0';
            sl_sclk         <= '0';
            sl_sdo          <= '0';
            sl_done         <= '0';
            st_bit_handler  <= st_idle;
        elsif rising_edge(pil_clk) then
            case st_bit_handler is
                when st_idle =>
                    sl_done     <= '0';
                    sl_rx_data  <= '0';
                    sl_rx_valid <= '0';
                    sl_sclk     <= al_spi_cpk;
                    if pil_spi_en = '1' then
                        case al_spi_cke is
                            when cl_cke_atoi =>
                                st_bit_handler <= st_spi_cke1_le;
                            when cl_cke_itoa =>
                                st_bit_handler <= st_spi_cke0_le;
                            when others =>
                        end case;
                    end if;
                when st_spi_cke1_le =>
                    sl_brg_count_en <= '1';
                    sl_sdo          <= pil_tx_data;
                    if pil_brg_pulse = '1' then
                        sl_sclk         <= not sl_sclk;
                        sl_rx_data      <= pil_sdi;
                        sl_rx_valid     <= '1';
                        sl_brg_count_en <= '0';
                        st_bit_handler  <= st_spi_cke1_te;
                    end if;
                when st_spi_cke1_te =>
                    sl_brg_count_en <= '1';
                    sl_rx_valid     <= '0';
                    if pil_brg_pulse = '1' then
                        sl_sclk         <= not sl_sclk;
                        sl_brg_count_en <= '0';
                        st_bit_handler  <= st_done;
                    end if;
                when st_spi_cke0_le =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_sclk         <= not sl_sclk;
                        sl_sdo          <= pil_tx_data;
                        sl_brg_count_en <= '0';
                        st_bit_handler  <= st_spi_cke0_te;
                    end if;
                when st_spi_cke0_te =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_sclk         <= not sl_sclk;
                        sl_rx_data      <= pil_sdi;
                        sl_rx_valid     <= '1';
                        sl_brg_count_en <= '0';
                        st_bit_handler  <= st_done;
                    end if;
                when st_done =>
                    sl_done     <= '1';
                    sl_rx_valid <= '0';
                    if pil_spi_en = '0' then
                        st_bit_handler <= st_idle;
                    end if;
            end case;
        end if;
    end process proc_nit_handler;

    pol_sclk <= sl_sclk;
    pol_sdo  <= sl_sdo;
    pol_done <= sl_done;

    pol_enable_brg_count <= sl_brg_count_en;

    pol_rx_data  <= sl_rx_data;
    pol_rx_valid <= sl_rx_valid;

end architecture;