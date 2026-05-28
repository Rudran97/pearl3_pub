library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    port (
        pil_clk                    : in std_logic;
        pil_rst                    : in std_logic;
        piv_uart_tx_control        : in std_logic_vector(1 downto 0); --- 1 -> tx enable, 0 -> send 9th bit
        pil_half_baud_period_pulse : in std_logic;
        piv_tx_data                : in std_logic_vector(7 downto 0);
        pil_bit9                   : in std_logic;
        pol_uart_tx                : out std_logic;
        pol_tx_ready_next_data     : out std_logic;
        pol_timer_on               : out std_logic;
        pol_tx_busy                : out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is

    constant ci_uart_tx_enable : integer := 1;
    constant ci_parity_enable  : integer := 0;

    type t_uart_tx_stage is (st_idle, st_send_start_bit, st_send_data, st_send_bit9, st_stop_bit, st_wait);
    signal st_uart_tx_state : t_uart_tx_stage;

    signal si_tx_bit_count : integer range 0 to 7;

    signal sl_tx : std_logic;

    signal sl_tx_ready_next_data : std_logic;
    signal sl_tx_busy            : std_logic;
    signal sl_timer_on           : std_logic;

    signal si_full_baud_ct : integer range 0 to 1;

begin

    proc_uart_tx : process (pil_clk, pil_rst) is
    begin
        if pil_rst = '1' then
            sl_tx                 <= '1';
            sl_tx_ready_next_data <= '0';
            sl_tx_busy            <= '0';
            si_tx_bit_count       <= 0;
            si_full_baud_ct       <= 0;
            sl_timer_on           <= '0';
            st_uart_tx_state      <= st_idle;
        elsif rising_edge(pil_clk) then
            sl_tx_ready_next_data <= '0';
            case st_uart_tx_state is
                when st_idle =>
                    sl_tx                 <= '1';
                    sl_tx_busy            <= '0';
                    si_full_baud_ct       <= 0;
                    si_tx_bit_count       <= 0;
                    sl_tx_ready_next_data <= '0';
                    sl_timer_on           <= '0';
                    if piv_uart_tx_control(ci_uart_tx_enable) = '1' then
                        st_uart_tx_state <= st_send_start_bit;
                    else
                        st_uart_tx_state <= st_idle;
                    end if;
                when st_send_start_bit =>
                    sl_tx_busy  <= '1';
                    sl_timer_on <= '1';
                    sl_tx       <= '0';
                    if pil_half_baud_period_pulse = '1' then
                        if si_full_baud_ct = 1 then
                            si_full_baud_ct  <= 0;
                            st_uart_tx_state <= st_send_data;
                        else
                            si_full_baud_ct <= si_full_baud_ct + 1;
                        end if;
                    else
                        st_uart_tx_state <= st_send_start_bit;
                    end if;
                when st_send_data =>
                    sl_tx_busy <= '1';
                    sl_tx      <= piv_tx_data(si_tx_bit_count);
                    if pil_half_baud_period_pulse = '1' then
                        if si_full_baud_ct = 1 then
                            si_full_baud_ct <= 0;
                            if si_tx_bit_count < 7 then
                                si_tx_bit_count  <= si_tx_bit_count + 1;
                                st_uart_tx_state <= st_send_data;
                            else
                                if piv_uart_tx_control(ci_parity_enable) = '1' then
                                    st_uart_tx_state <= st_send_bit9;
                                else
                                    st_uart_tx_state <= st_stop_bit;
                                end if;
                            end if;
                        else
                            si_full_baud_ct <= si_full_baud_ct + 1;
                        end if;
                    else
                        st_uart_tx_state <= st_send_data;
                    end if;
                when st_send_bit9 =>
                    sl_tx_busy <= '1';
                    sl_tx      <= pil_bit9;
                    if pil_half_baud_period_pulse = '1' then
                        if si_full_baud_ct = 1 then
                            si_full_baud_ct  <= 0;
                            st_uart_tx_state <= st_stop_bit;
                        else
                            si_full_baud_ct <= si_full_baud_ct + 1;
                        end if;
                    else
                        st_uart_tx_state <= st_send_bit9;
                    end if;
                when st_stop_bit =>
                    sl_tx_busy <= '1';
                    sl_tx      <= '1';
                    if pil_half_baud_period_pulse = '1' then
                        if si_full_baud_ct = 1 then
                            si_full_baud_ct       <= 0;
                            st_uart_tx_state      <= st_wait;
                            sl_tx_ready_next_data <= '1';
                            sl_tx_busy            <= '0';
                        else
                            si_full_baud_ct <= si_full_baud_ct + 1;
                        end if;
                    else
                        st_uart_tx_state <= st_stop_bit;
                    end if;
                when st_wait =>
                    if piv_uart_tx_control(ci_uart_tx_enable) = '0' then
                        st_uart_tx_state <= st_idle;
                    end if;
            end case;
        end if;
    end process proc_uart_tx;

    pol_uart_tx            <= sl_tx;
    pol_tx_ready_next_data <= sl_tx_ready_next_data;
    pol_timer_on           <= sl_timer_on;
    pol_tx_busy            <= sl_tx_busy;

end architecture rtl;