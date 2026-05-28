library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_module is
	generic(
		gi_pwm_resolution : integer := 16
	);
	port(
		pil_clk       : in  std_logic;
		pil_rst       : in  std_logic;
		pil_pwm_en    : in  std_logic;
		piv_pwm_timer : in  std_logic_vector(gi_pwm_resolution - 1 downto 0);
		piv_pwm_Hz    : in  std_logic_vector(gi_pwm_resolution - 1 downto 0);
		piv_pwm_dc    : in  std_logic_vector(gi_pwm_resolution - 1 downto 0);
		pol_pwm       : out std_logic
	);
end entity pwm_module;

architecture rtl of pwm_module is

	constant cv_0_dc : std_logic_vector(gi_pwm_resolution - 1 downto 0) := (others => '0');
		
	signal sl_pwm : std_logic;

begin

	proc_gen_pwm : process(pil_clk, pil_rst) is
	begin
		if pil_rst = '1' then
			sl_pwm <= '0';
		elsif rising_edge(pil_clk) then
			if pil_pwm_en = '1' then
				if piv_pwm_timer = piv_pwm_Hz then
					sl_pwm <= '1';
				end if;
				if piv_pwm_timer = piv_pwm_dc then
					sl_pwm <= '0';
				end if;
				
				if piv_pwm_dc = cv_0_dc then
					sl_pwm <= '0';
				end if;
				
				if piv_pwm_dc = piv_pwm_Hz then
					sl_pwm <= '1';
				end if;
			end if;
		end if;
	end process proc_gen_pwm;

	pol_pwm <= sl_pwm;

end architecture rtl;
