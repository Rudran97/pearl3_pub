library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    generic (
        gi_counter_width : integer := 16;
        gi_clksrc_div    : integer := 6
    );
    port (
        pil_clk                 : in std_logic;
        pil_rst                 : in std_logic;
        piv_counter_control     : in std_logic_vector(1 downto 0); -- 1 -> clr match flag, 0 -> counter ON
        piv_counter_prescale    : in std_logic_vector(gi_counter_width - 1 downto 0);
        piv_counter_match_value : in std_logic_vector(gi_counter_width - 1 downto 0);
        pov_counter_value       : out std_logic_vector(gi_counter_width - 1 downto 0);
        pol_counter_match_flag  : out std_logic
    );
end entity;

architecture rtl of counter is

    signal su_counter_ct                 : unsigned(pov_counter_value'length - 1 downto 0);
    signal si_counter_prescale_clkdiv_ct : integer range 0 to 2 ** piv_counter_prescale'length - 1;
    signal sl_counter_match_flag         : std_logic;

    signal si_counter_clksrc_div_ct : integer range 0 to gi_clksrc_div - 1;

    alias al_counter_on       : std_logic is piv_counter_control(0);
    alias al_clear_match_flag : std_logic is piv_counter_control(1);

begin

    proc_timerA_counter : process (pil_clk, pil_rst) is
    begin
        if pil_rst = '1' then
            su_counter_ct                 <= (others => '0');
            si_counter_prescale_clkdiv_ct <= 0;
            si_counter_clksrc_div_ct      <= 0;
            sl_counter_match_flag         <= '0';
        elsif rising_edge(pil_clk) then
            if al_clear_match_flag = '1' then
                sl_counter_match_flag <= '0';
            end if;

            if al_counter_on = '1' then
                if si_counter_clksrc_div_ct < gi_clksrc_div - 1 then
                    si_counter_clksrc_div_ct <= si_counter_clksrc_div_ct + 1;
                else
                    si_counter_clksrc_div_ct <= 0;
                    if si_counter_prescale_clkdiv_ct < to_integer(unsigned(piv_counter_prescale)) then
                        si_counter_prescale_clkdiv_ct <= si_counter_prescale_clkdiv_ct + 1;
                    else
                        si_counter_prescale_clkdiv_ct <= 0;
                        if su_counter_ct < to_integer(unsigned(piv_counter_match_value)) then
                            su_counter_ct <= su_counter_ct + 1;
                        else
                            su_counter_ct         <= (others => '0');
                            sl_counter_match_flag <= '1';
                        end if;
                    end if;
                end if;
            else
                si_counter_clksrc_div_ct      <= 0;
                si_counter_prescale_clkdiv_ct <= 0;
                su_counter_ct                 <= (others => '0');
            end if;
        end if;
    end process proc_timerA_counter;

    pov_counter_value      <= std_logic_vector(su_counter_ct);
    pol_counter_match_flag <= sl_counter_match_flag;

end architecture;