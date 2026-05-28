library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.timer_pkg.all;

entity dct is
    generic (
        gi_bus_width : integer := 32
    );
    port (
        pil_clk           : in std_logic;
        pil_rst           : in std_logic;
        piv_timer_control : in std_logic_vector(5 downto 0);
        piv_timer         : in std_logic_vector(gi_bus_width - 1 downto 0);
        pov_timer_flag    : out std_logic_vector(1 downto 0);
        pov_timer         : out std_logic_vector(gi_bus_width - 1 downto 0)
    );
end entity;

architecture rtl of dct is

    -- TRA registers --
    signal sv_TRA_counter_value        : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
    signal sv_TCRA_reg                 : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
    signal sv_TRA_prescale_clkdiv      : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
    signal sl_TCRA_reg_valid           : std_logic;
    signal sv_TRA_event_ct_feedbackreg : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
    signal sl_TFA_flag                 : std_logic;

    -- TRB registers --
    signal sv_TRB_counter_value        : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
    signal sv_TCRB_reg                 : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
    signal sv_TRB_prescale_clkdiv      : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
    signal sl_TCRB_reg_valid           : std_logic;
    signal sv_TRB_event_ct_feedbackreg : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
    signal sl_TFB_flag                 : std_logic;

begin

    proc_module_setup : process (pil_clk, pil_rst) is
    begin
        if pil_rst = '1' then
            sv_TCRA_reg            <= (others => '0');
            sv_TRA_prescale_clkdiv <= (others => '0');
            sl_TCRA_reg_valid      <= '0';
            sv_TCRB_reg            <= (others => '0');
            sv_TRB_prescale_clkdiv <= (others => '0');
            sl_TCRB_reg_valid      <= '0';
        elsif rising_edge(pil_clk) then
            if sl_TCRA_reg_valid = '1' then -- turn off TCRA valid signal 
                sl_TCRA_reg_valid <= '0';
            end if;

            if sl_TCRB_reg_valid = '1' then -- turn off TCRB valid signal 
                sl_TCRB_reg_valid <= '0';
            end if;

            if piv_timer_control(ctr_dct_con.i_TRA_set) = '1' then
                sv_TCRA_reg            <= piv_timer(gi_bus_width - 1 downto gi_bus_width / 2);
                sv_TRA_prescale_clkdiv <= piv_timer(gi_bus_width / 2 - 1 downto 0);
                sl_TCRA_reg_valid      <= '1';
            end if;

            if piv_timer_control(ctr_dct_con.i_TRB_set) = '1' then
                sv_TCRB_reg            <= piv_timer(gi_bus_width - 1 downto gi_bus_width / 2);
                sv_TRB_prescale_clkdiv <= piv_timer(gi_bus_width / 2 - 1 downto 0);
                sl_TCRB_reg_valid      <= '1';
            end if;
        end if;
    end process proc_module_setup;

    inst_timerA_counter : entity work.counter
        generic map(
            gi_counter_width => gi_bus_width / 2,
            gi_clksrc_div    => ci_clksrc_div
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            piv_counter_control     => piv_timer_control(ctr_dct_con.i_clr_TFA) & piv_timer_control(ctr_dct_con.i_TRAON),
            piv_counter_prescale    => sv_TRA_prescale_clkdiv,
            piv_counter_match_value => sv_TCRA_reg,
            pov_counter_value       => sv_TRA_counter_value,
            pol_counter_match_flag  => sl_TFA_flag
        );

    inst_timerB_counter : entity work.counter
        generic map(
            gi_counter_width => gi_bus_width / 2,
            gi_clksrc_div    => ci_clksrc_div
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            piv_counter_control     => piv_timer_control(ctr_dct_con.i_clr_TFB) & piv_timer_control(ctr_dct_con.i_TRBON),
            piv_counter_prescale    => sv_TRB_prescale_clkdiv,
            piv_counter_match_value => sv_TCRB_reg,
            pov_counter_value       => sv_TRB_counter_value,
            pol_counter_match_flag  => sl_TFB_flag
        );

    proc_timerA_counter_hold : process (pil_clk, pil_rst) is
    begin
        if pil_rst = '1' then
            sv_TRA_event_ct_feedbackreg <= (others => '0');
        elsif rising_edge(pil_clk) then
            if piv_timer_control(ctr_dct_con.i_TRAON) = '1' then
                sv_TRA_event_ct_feedbackreg <= sv_TRA_counter_value;
            end if;
        end if;
    end process proc_timerA_counter_hold;

    proc_timerB_counter_hold : process (pil_clk, pil_rst) is
    begin
        if pil_rst = '1' then
            sv_TRB_event_ct_feedbackreg <= (others => '0');
        elsif rising_edge(pil_clk) then
            if piv_timer_control(ctr_dct_con.i_TRBON) = '1' then
                sv_TRB_event_ct_feedbackreg <= sv_TRB_counter_value;
            end if;
        end if;
    end process proc_timerB_counter_hold;

    pov_timer_flag(ctr_dct_flag.i_TFB) <= sl_TFB_flag;
    pov_timer_flag(ctr_dct_flag.i_TFA) <= sl_TFA_flag;

    pov_timer <= sv_TRB_event_ct_feedbackreg & sv_TRA_event_ct_feedbackreg;

end architecture;