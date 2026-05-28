library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity input_capture_unit is
    port(
        pil_clk                   : in  std_logic;
        pil_rst                   : in  std_logic;
        piv_input_capture_control : in  std_logic_vector(5 downto 0);
        pil_trigger               : in  std_logic;
        pol_ICF                   : out std_logic; -- input capture flag
        pol_ne_ICF                : out std_logic;
        pol_pe_ICF                : out std_logic
    );
end entity input_capture_unit;

architecture rtl of input_capture_unit is

    constant ci_ena_int      : integer := 5;
    constant ci_trigger_edge : integer := 4;
    constant ci_both_edge    : integer := 3;  -- when disabled, the trigger would happer at the edge
                                              -- specified by trigger_edge
    constant ci_clr_ICF      : integer := 2;
    constant ci_clr_ne_ICF   : integer := 1;
    constant ci_clr_pe_ICF   : integer := 0;

    signal sl_trigger_old : std_logic;

    signal sl_ICF    : std_logic;
    signal sl_ne_ICF : std_logic;
    signal sl_pe_ICF : std_logic;

begin

    proc_trigger_capture : process(pil_clk, pil_rst) is
    begin
        if pil_rst = '1' then
            sl_ICF         <= '0';
            sl_ne_ICF      <= '0';
            sl_pe_ICF      <= '0';
            sl_trigger_old <= '0';
        elsif rising_edge(pil_clk) then
            sl_trigger_old <= pil_trigger;
            if piv_input_capture_control(ci_ena_int) = '1' then
                if piv_input_capture_control(ci_both_edge) = '0' then
                    if pil_trigger = piv_input_capture_control(ci_trigger_edge) and pil_trigger /= sl_trigger_old then
                        sl_ICF <= '1';
                    end if;
                else
                    if pil_trigger /= sl_trigger_old then
                        sl_ICF <= '1';

                        if pil_trigger = '1' then
                            sl_pe_ICF <= '1';
                        else
                            sl_ne_ICF <= '1';
                        end if;
                    end if;
                end if;

                if piv_input_capture_control(ci_clr_ICF) = '1' then
                    sl_ICF <= '0';
                end if;

                if piv_input_capture_control(ci_clr_ne_ICF) = '1' then
                    sl_ne_ICF <= '0';
                end if;

                if piv_input_capture_control(ci_clr_pe_ICF) = '1' then
                    sl_pe_ICF <= '0';
                end if;
            end if;
        end if;
    end process proc_trigger_capture;

    pol_ICF    <= sl_ICF;
    pol_ne_ICF <= sl_ne_ICF;
    pol_pe_ICF <= sl_pe_ICF;

end architecture rtl;
