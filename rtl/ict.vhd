library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.timer_pkg.all;

entity ict is
	generic (
		gi_bus_width : integer := 32
	);
	port (
		pil_clk           : in std_logic;
		pil_rst           : in std_logic;
		piv_timer_control : in std_logic_vector(11 downto 0);
		piv_port          : in std_logic_vector(3 downto 0);
		piv_timer         : in std_logic_vector(gi_bus_width - 1 downto 0);
		pov_timer_flag    : out std_logic_vector(1 downto 0);
		pov_timer         : out std_logic_vector(gi_bus_width - 1 downto 0)
	);
end entity ict;

architecture rtl of ict is

	-- TR registers --
	signal sv_timer_counter_control   : std_logic_vector(1 downto 0);
	signal sv_TR_counter_value        : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
	signal sv_TCR_reg                 : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
	signal sv_TR_prescale_clkdiv      : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
	signal sl_TCR_reg_valid           : std_logic;
	signal sv_TR_event_ct_feedbackreg : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
	signal sl_TF_flag                 : std_logic;

	constant cl_TCIC_timer_mode : std_logic := '0';

	-- Input capture registers --
	signal sl_capture_counter_en       : std_logic;
	signal sl_TIC_capture_start_edge   : std_logic;
	signal sl_TIC_capture_end_edge     : std_logic;
	signal sv_TIC_counter_value        : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
	signal sv_TICC_reg                 : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
	signal sv_TIC_prescale_clkdiv      : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
	signal sl_TIC_reg_valid            : std_logic;
	signal sv_TIC_event_ct_feedbackreg : std_logic_vector((gi_bus_width / 2) - 1 downto 0);
	signal sl_TIC_flag                 : std_logic;

	signal sl_input_capture_en        : std_logic;
	signal sl_start_clr_ICF           : std_logic;
	signal sl_end_clr_ICF             : std_logic;
	signal sl_TIC_event_capture_valid : std_logic;

	constant cl_TCIC_capture_mode : std_logic := '1';

	--- start input capture module ---
	signal sv_start_input_capture_control : std_logic_vector(5 downto 0);
	signal sl_start_trigger               : std_logic;
	signal sl_start_IC                    : std_logic;
	signal si_start_trigger_pin           : integer range 0 to 3;

	--- end input capture module ---
	signal sv_end_input_capture_control : std_logic_vector(5 downto 0);
	signal sl_end_trigger               : std_logic;
	signal sl_end_IC                    : std_logic;
	signal si_end_trigger_pin           : integer range 0 to 3;

begin

	sv_start_input_capture_control <= sl_input_capture_en & sl_TIC_capture_start_edge & '0' & sl_start_clr_ICF & "00";
	sl_start_trigger               <= piv_port(si_start_trigger_pin);

	inst_start_input_capture_module : entity work.input_capture_unit
		port map(
			pil_clk                   => pil_clk,
			pil_rst                   => pil_rst,
			piv_input_capture_control => sv_start_input_capture_control,
			pil_trigger               => sl_start_trigger,
			pol_ICF                   => sl_start_IC,
			pol_ne_ICF                => open,
			pol_pe_ICF                => open
		);

	sv_end_input_capture_control <= sl_input_capture_en & sl_TIC_capture_end_edge & '0' & sl_end_clr_ICF & "00";
	sl_end_trigger               <= piv_port(si_end_trigger_pin);

	inst_end_input_capture_module : entity work.input_capture_unit
		port map(
			pil_clk                   => pil_clk,
			pil_rst                   => pil_rst,
			piv_input_capture_control => sv_end_input_capture_control,
			pil_trigger               => sl_end_trigger,
			pol_ICF                   => sl_end_IC,
			pol_ne_ICF                => open,
			pol_pe_ICF                => open
		);

	proc_module_setup : process (pil_clk, pil_rst) is
	begin
		if pil_rst = '1' then
			sv_TCR_reg                <= (others => '0');
			sv_TR_prescale_clkdiv     <= (others => '0');
			sl_TCR_reg_valid          <= '0';
			sl_TIC_capture_start_edge <= '0';
			sl_TIC_capture_end_edge   <= '0';
			sv_TICC_reg               <= (others => '0');
			sv_TIC_prescale_clkdiv    <= (others => '0');
			si_start_trigger_pin      <= 0;
			si_end_trigger_pin        <= 0;
			sl_TIC_reg_valid          <= '0';
		elsif rising_edge(pil_clk) then
			if sl_TCR_reg_valid = '1' then -- turn off TCRA valid signal 
				sl_TCR_reg_valid <= '0';
			end if;

			if sl_TIC_reg_valid = '1' then -- turn off TIC valid signal 
				sl_TIC_reg_valid <= '0';
			end if;

			if piv_timer_control(ctr_ict_con.i_TR_set) = '1' then
				sv_TCR_reg            <= piv_timer(gi_bus_width - 1 downto gi_bus_width / 2);
				sv_TR_prescale_clkdiv <= piv_timer(gi_bus_width / 2 - 1 downto 0);
				sl_TCR_reg_valid      <= '1';
			end if;

			if piv_timer_control(ctr_ict_con.i_TIC_set) = '1' then
				sl_TIC_capture_start_edge <= piv_timer_control(ctr_ict_con.i_TIC_capture_start_edge);
				sl_TIC_capture_end_edge   <= piv_timer_control(ctr_ict_con.i_TIC_capture_end_edge);
				sv_TICC_reg               <= piv_timer(gi_bus_width - 1 downto gi_bus_width / 2);
				sv_TIC_prescale_clkdiv    <= piv_timer(gi_bus_width / 2 - 1 downto 0);
				si_start_trigger_pin      <= to_integer(unsigned(piv_timer_control(ctr_ict_con.i_capture_start_pinBit1 downto ctr_ict_con.i_capture_start_pinBit0)));
				si_end_trigger_pin        <= to_integer(unsigned(piv_timer_control(ctr_ict_con.i_capture_end_pinBit1 downto ctr_ict_con.i_capture_end_pinBit0)));
				sl_TIC_reg_valid          <= '1';
			end if;
		end if;
	end process proc_module_setup;

	sv_timer_counter_control <= piv_timer_control(ctr_ict_con.i_Timer_flag_clr) & (piv_timer_control(ctr_ict_con.i_TICRON) and not piv_timer_control(ctr_ict_con.i_TCIC_mode));

	inst_timer_counter : entity work.counter
		generic map(
			gi_counter_width => gi_bus_width / 2,
			gi_clksrc_div    => ci_clksrc_div
		)
		port map(
			pil_clk                 => pil_clk,
			pil_rst                 => pil_rst,
			piv_counter_control     => sv_timer_counter_control,
			piv_counter_prescale    => sv_TR_prescale_clkdiv,
			piv_counter_match_value => sv_TCR_reg,
			pov_counter_value       => sv_TR_counter_value,
			pol_counter_match_flag  => sl_TF_flag
		);

	inst_capture_counter : entity work.counter
		generic map(
			gi_counter_width => gi_bus_width / 2,
			gi_clksrc_div    => ci_clksrc_div
		)
		port map(
			pil_clk                 => pil_clk,
			pil_rst                 => pil_rst,
			piv_counter_control     => '0' & sl_capture_counter_en,
			piv_counter_prescale    => sv_TIC_prescale_clkdiv,
			piv_counter_match_value => sv_TICC_reg,
			pov_counter_value       => sv_TIC_counter_value,
			pol_counter_match_flag  => open
		);

	proc_timer_counter_hold : process (pil_clk, pil_rst) is
	begin
		if pil_rst = '1' then
			sv_TR_event_ct_feedbackreg <= (others => '0');
		elsif rising_edge(pil_clk) then
			if piv_timer_control(ctr_ict_con.i_TICRON) = '1' and piv_timer_control(ctr_ict_con.i_TCIC_mode) = cl_TCIC_timer_mode then
				sv_TR_event_ct_feedbackreg <= std_logic_vector(sv_TR_counter_value);
			end if;
		end if;
	end process proc_timer_counter_hold;

	proc_input_capture_hold : process (pil_clk, pil_rst) is
	begin
		if pil_rst = '1' then
			sv_TIC_event_ct_feedbackreg <= (others => '0');
			sl_start_clr_ICF            <= '0';
			sl_end_clr_ICF              <= '0';
			sl_TIC_flag                 <= '0';
			sl_TIC_event_capture_valid  <= '0';
			sl_input_capture_en         <= '0';
			sl_capture_counter_en       <= '0';
		elsif rising_edge(pil_clk) then
			sl_start_clr_ICF           <= '0';
			sl_end_clr_ICF             <= '0';
			sl_TIC_event_capture_valid <= '0';

			if piv_timer_control(ctr_ict_con.i_TIC_flag_clr) = '1' then
				sl_TIC_flag           <= '0';
				sl_capture_counter_en <= '0';
			end if;

			if sl_start_IC = '1' then
				sl_capture_counter_en <= '1';
			end if;

			if sl_end_IC = '1' and sl_start_IC = '1' then
				sl_start_clr_ICF           <= '1';
				sl_end_clr_ICF             <= '1';
				sl_TIC_event_capture_valid <= '1';
				sl_TIC_flag                <= '1';
			end if;

			if piv_timer_control(ctr_ict_con.i_TICRON) = '1' and piv_timer_control(ctr_ict_con.i_TCIC_mode) = cl_TCIC_capture_mode then
				sl_input_capture_en <= '1';
				if sl_TIC_event_capture_valid = '1' then
					sv_TIC_event_ct_feedbackreg <= std_logic_vector(sv_TIC_counter_value);
				end if;
			else
				sl_input_capture_en <= '0';
			end if;
		end if;
	end process proc_input_capture_hold;

	pov_timer_flag(ctr_ict_flag.i_TIC) <= sl_TIC_flag;
	pov_timer_flag(ctr_ict_flag.i_TF)  <= sl_TF_flag;

	pov_timer <= sv_TIC_event_ct_feedbackreg & sv_TR_event_ct_feedbackreg;

end architecture rtl;