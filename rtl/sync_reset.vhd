library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_reset is
	port(
		pil_clk          : in  std_logic;
		pil_global_reset : in  std_logic;
		pil_prg_reset    : in  std_logic;
		pil_prg_run_prog : in  std_logic;
		pol_reset        : out std_logic;
		pol_run_prog     : out std_logic
	);
end entity sync_reset;

architecture rtl of sync_reset is

	signal sl_reset_delay : std_logic := '0';
	signal sl_reset       : std_logic;

	signal sl_run_prog : std_logic;

begin

	proc_sync_reset : process(pil_clk) is
	begin
		if rising_edge(pil_clk) then
			if pil_global_reset = '1' then
				sl_reset_delay <= '1';
				sl_reset       <= sl_reset_delay;
				sl_run_prog    <= '0';
			else
				sl_reset    <= pil_prg_reset;
				sl_run_prog <= pil_prg_run_prog;
			end if;
		end if;
	end process proc_sync_reset;

	pol_reset    <= sl_reset;
	pol_run_prog <= sl_run_prog;

end architecture rtl;
