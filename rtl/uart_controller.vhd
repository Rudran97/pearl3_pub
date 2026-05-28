library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_controller_pkg.all;

entity uart_controller is
    port (
        pil_clk            : in std_logic;
        pil_rst            : in std_logic;
        piv_uart_control   : in std_logic_vector(2 downto 0); -- 2 -> enable bit 9, 1 -> uart rx enable, 0 -> uart tx enable
        piv_half_baud_rate : in std_logic_vector(15 downto 0);
        piv_tx_data        : in std_logic_vector(8 downto 0);
        pov_rx_data        : out std_logic_vector(8 downto 0);
        pil_uart_rx        : in std_logic;
        pol_uart_tx        : out std_logic;
        pol_uart_RXIF      : out std_logic;
        pol_uart_TXIF      : out std_logic;
        pol_frame_error    : out std_logic;
        pol_uart_rx_busy   : out std_logic;
        pol_uart_tx_busy   : out std_logic
    );
end entity uart_controller;

architecture rtl of uart_controller is

    --- baud rate gen ---

    signal sl_rx_bg_counter_en         : std_logic;
    signal sl_rx_bg_counter_match_flag : std_logic;

    signal sl_tx_bg_counter_en         : std_logic;
    signal sl_tx_bg_counter_match_flag : std_logic;

    --- tx module ---

    signal sv_uart_tx_control     : std_logic_vector(1 downto 0);
    signal sl_tx_complete         : std_logic;
    signal sl_tx_timer_on_request : std_logic;
    signal sl_tx_busy             : std_logic;

    --- rx module ---

    signal sv_uart_rx_control     : std_logic_vector(1 downto 0);
    signal sv_rx_data             : std_logic_vector(7 downto 0);
    signal sl_rx_bit9             : std_logic;
    signal sl_rx_complete         : std_logic;
    signal sl_rx_timer_on_request : std_logic;
    signal sl_rx_busy             : std_logic;

    type t_controller_stage is (st_valid_transmission_detect, st_idle, st_uart_bus_ready, st_data, st_stop_comm);

    signal st_tx_controller_state : t_controller_stage;
    signal sl_uart_tx_busy        : std_logic;
    signal sl_uart_TXIF           : std_logic;

    signal st_rx_controller_state : t_controller_stage;
    signal sl_uart_rx_busy        : std_logic;
    signal sl_uart_RXIF           : std_logic;

begin

    -----------------------------------------------------------------------------------------------------
    --------------------------------------------UART RX MODULE-------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_rx_bg_counter_en <= sl_rx_timer_on_request;

    inst_rx_bd_counter : entity work.counter
        generic map(
            gi_counter_width => 16,
            gi_clksrc_div    => ci_clksrc_div
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            piv_counter_control     => '1' & sl_rx_bg_counter_en,
            piv_counter_prescale => (others => '0'),
            piv_counter_match_value => piv_half_baud_rate,
            pov_counter_value       => open,
            pol_counter_match_flag  => sl_rx_bg_counter_match_flag
        );

    inst_uart_rx_module : entity work.uart_rx
        port map(
            pil_clk                    => pil_clk,
            pil_rst                    => pil_rst,
            piv_uart_rx_control        => sv_uart_rx_control,
            pil_half_baud_period_pulse => sl_rx_bg_counter_match_flag,
            pil_uart_rx                => pil_uart_rx,
            pov_rx_data                => sv_rx_data,
            pol_bit9                   => sl_rx_bit9,
            pol_rx_data_valid          => sl_rx_complete,
            pol_error                  => pol_frame_error,
            pol_timer_on               => sl_rx_timer_on_request,
            pol_rx_busy                => sl_rx_busy
        );

    proc_uart_rx_controller : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sv_uart_rx_control     <= (others => '0');
            sl_uart_rx_busy        <= '0';
            st_rx_controller_state <= st_valid_transmission_detect;
        elsif rising_edge(pil_clk) then
            case st_rx_controller_state is
                when st_valid_transmission_detect =>
                    sl_uart_rx_busy    <= '0';
                    sv_uart_rx_control <= (others => '0');
                    if piv_uart_control(ctr_uart_con.i_RXEN) = '0' then
                        st_rx_controller_state <= st_idle;
                    end if;
                when st_idle =>
                    sl_uart_RXIF <= '0';
                    if piv_uart_control(ctr_uart_con.i_RXEN) = '1' then
                        st_rx_controller_state <= st_uart_bus_ready;
                    end if;
                when st_uart_bus_ready =>
                    sl_uart_rx_busy        <= '1';
                    sv_uart_rx_control     <= '1' & piv_uart_control(ctr_uart_con.i_ENBIT9);
                    st_rx_controller_state <= st_data;
                when st_data =>
                    if sl_rx_complete = '1' then
                        sl_uart_RXIF           <= '1';
                        st_rx_controller_state <= st_stop_comm;
                    end if;
                when st_stop_comm =>
                    if sl_rx_busy = '0' then
                        st_rx_controller_state <= st_valid_transmission_detect;
                    end if;
            end case;
        end if;
    end process proc_uart_rx_controller;

    -----------------------------------------------------------------------------------------------------
    --------------------------------------------UART TX MODULE-------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_tx_bg_counter_en <= sl_tx_timer_on_request;

    inst_tx_bd_counter : entity work.counter
        generic map(
            gi_counter_width => 16,
            gi_clksrc_div    => ci_clksrc_div
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            piv_counter_control     => '1' & sl_tx_bg_counter_en,
            piv_counter_prescale => (others => '0'),
            piv_counter_match_value => piv_half_baud_rate,
            pov_counter_value       => open,
            pol_counter_match_flag  => sl_tx_bg_counter_match_flag
        );

    inst_uart_tx_module : entity work.uart_tx
        port map(
            pil_clk                    => pil_clk,
            pil_rst                    => pil_rst,
            piv_uart_tx_control        => sv_uart_tx_control,
            pil_half_baud_period_pulse => sl_tx_bg_counter_match_flag,
            piv_tx_data                => piv_tx_data(7 downto 0),
            pil_bit9                   => piv_tx_data(8),
            pol_uart_tx                => pol_uart_tx,
            pol_tx_ready_next_data     => sl_tx_complete,
            pol_timer_on               => sl_tx_timer_on_request,
            pol_tx_busy                => sl_tx_busy
        );

    proc_uart_tx_controller : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sv_uart_tx_control     <= (others => '0');
            sl_uart_tx_busy        <= '0';
            st_tx_controller_state <= st_valid_transmission_detect;
        elsif rising_edge(pil_clk) then
            case st_tx_controller_state is
                when st_valid_transmission_detect =>
                    sl_uart_tx_busy    <= '0';
                    sv_uart_tx_control <= (others => '0');
                    if piv_uart_control(ctr_uart_con.i_TXEN) = '0' then
                        st_tx_controller_state <= st_idle;
                    end if;
                when st_idle =>
                    sl_uart_TXIF <= '0';
                    if piv_uart_control(ctr_uart_con.i_TXEN) = '1' then
                        st_tx_controller_state <= st_uart_bus_ready;
                    end if;
                when st_uart_bus_ready =>
                    sl_uart_tx_busy        <= '1';
                    sv_uart_tx_control     <= '1' & piv_uart_control(ctr_uart_con.i_ENBIT9);
                    st_tx_controller_state <= st_data;
                when st_data =>
                    if sl_tx_complete = '1' then
                        sl_uart_TXIF           <= '1';
                        st_tx_controller_state <= st_stop_comm;
                    end if;
                when st_stop_comm =>
                    if sl_tx_busy = '0' then
                        st_tx_controller_state <= st_valid_transmission_detect;
                    end if;
            end case;
        end if;
    end process proc_uart_tx_controller;

    pov_rx_data <= sl_rx_bit9 & sv_rx_data;

    pol_uart_RXIF    <= sl_uart_RXIF;
    pol_uart_rx_busy <= sl_uart_rx_busy;

    pol_uart_TXIF    <= sl_uart_TXIF;
    pol_uart_tx_busy <= sl_uart_tx_busy;

end architecture rtl;