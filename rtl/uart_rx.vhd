library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (
        pil_clk                    : in std_logic;
        pil_rst                    : in std_logic;
        piv_uart_rx_control        : in std_logic_vector(1 downto 0); --- 1 -> rx enable, 0 -> receive 9th bit
        pil_half_baud_period_pulse : in std_logic;
        pil_uart_rx                : in std_logic;
        pov_rx_data                : out std_logic_vector(7 downto 0);
        pol_bit9                   : out std_logic;
        pol_rx_data_valid          : out std_logic;
        pol_error                  : out std_logic; --- framing error (stop bit not received properly)
        pol_timer_on               : out std_logic;
        pol_rx_busy                : out std_logic
    );
end entity uart_rx;

architecture rtl of uart_rx is

    constant ci_uart_rx_enable : integer := 1;
    constant ci_parity_enable  : integer := 0;

    type t_uart_rx_stage is (st_idle, st_start_bit_detect, st_receive_data, st_receive_bit9, st_stop_bit);
    signal st_uart_rx_state : t_uart_rx_stage;

    signal si_rx_bit_count : integer range 0 to 7;

    signal sv_rx_data       : std_logic_vector(7 downto 0);
    signal sl_bit9          : std_logic;
    signal sl_rx_data_valid : std_logic;
    signal sl_rx_busy       : std_logic;
    signal sl_frame_error   : std_logic;
    signal sl_timer_on      : std_logic;

    signal si_full_baud_ct : integer range 0 to 1;

begin

    proc_uart_rx : process (pil_clk, pil_rst) is
    begin
        if pil_rst = '1' then
            sv_rx_data       <= (others => '0');
            sl_bit9          <= '0';
            sl_rx_data_valid <= '0';
            sl_rx_busy       <= '0';
            si_rx_bit_count  <= 0;
            si_full_baud_ct  <= 0;
            sl_frame_error   <= '0';
            sl_timer_on      <= '0';
            st_uart_rx_state <= st_idle;
        elsif rising_edge(pil_clk) then
            sl_rx_data_valid <= '0';
            if piv_uart_rx_control(ci_uart_rx_enable) = '1' then
                case st_uart_rx_state is
                    when st_idle =>
                        sl_rx_busy       <= '0';
                        si_rx_bit_count  <= 0;
                        sl_rx_data_valid <= '0';
                        si_full_baud_ct  <= 0;
                        sl_timer_on      <= '0';
                        if pil_uart_rx = '0' then
                            st_uart_rx_state <= st_start_bit_detect;
                            sl_timer_on      <= '1';
                            sl_rx_busy       <= '1';
                        else
                            st_uart_rx_state <= st_idle;
                        end if;
                    when st_start_bit_detect =>
                        sl_rx_busy <= '1';
                        if pil_half_baud_period_pulse = '1' then
                            if pil_uart_rx = '0' then
                                st_uart_rx_state <= st_receive_data;
                            else
                                st_uart_rx_state <= st_idle;
                            end if;
                        else
                            st_uart_rx_state <= st_start_bit_detect;
                        end if;
                    when st_receive_data =>
                        sl_frame_error <= '0';
                        sl_rx_busy     <= '1';
                        if pil_half_baud_period_pulse = '1' then
                            if si_full_baud_ct = 1 then
                                si_full_baud_ct             <= 0;
                                sv_rx_data(si_rx_bit_count) <= pil_uart_rx;
                                if si_rx_bit_count < 7 then
                                    si_rx_bit_count  <= si_rx_bit_count + 1;
                                    st_uart_rx_state <= st_receive_data;
                                else
                                    if piv_uart_rx_control(ci_parity_enable) = '1' then
                                        st_uart_rx_state <= st_receive_bit9;
                                    else
                                        st_uart_rx_state <= st_stop_bit;
                                    end if;
                                end if;
                            else
                                si_full_baud_ct <= si_full_baud_ct + 1;
                            end if;
                        else
                            st_uart_rx_state <= st_receive_data;
                        end if;
                    when st_receive_bit9 =>
                        sl_rx_busy <= '1';
                        if pil_half_baud_period_pulse = '1' then
                            if si_full_baud_ct = 1 then
                                si_full_baud_ct  <= 0;
                                sl_bit9          <= pil_uart_rx;
                                st_uart_rx_state <= st_stop_bit;
                            else
                                si_full_baud_ct <= si_full_baud_ct + 1;
                            end if;
                        else
                            st_uart_rx_state <= st_receive_bit9;
                        end if;
                    when st_stop_bit =>
                        sl_rx_busy <= '1';
                        if pil_half_baud_period_pulse = '1' then
                            if si_full_baud_ct = 1 then
                                si_full_baud_ct  <= 0;
                                sl_frame_error   <= pil_uart_rx;
                                st_uart_rx_state <= st_idle;
                                sl_rx_data_valid <= '1';
                                sl_rx_busy       <= '0';
                            else
                                si_full_baud_ct <= si_full_baud_ct + 1;
                            end if;
                        else
                            st_uart_rx_state <= st_stop_bit;
                        end if;
                end case;
            else
                st_uart_rx_state <= st_idle;
            end if;
        end if;
    end process proc_uart_rx;

    pov_rx_data <= sv_rx_data;

    pol_bit9          <= sl_bit9;
    pol_rx_data_valid <= sl_rx_data_valid;

    pol_error    <= not sl_frame_error;
    pol_rx_busy  <= sl_rx_busy;
    pol_timer_on <= sl_timer_on;

end architecture rtl;