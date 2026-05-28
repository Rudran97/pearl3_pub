library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.core_pkg.all;
use work.options_soc_pkg.all;
use work.pearl3_soc_pkg.all;

entity tb_pearl3_top is
end entity tb_pearl3_top;

architecture tb of tb_pearl3_top is

    constant cb_DEBUG           : boolean                        := false;
	constant cv_start_code      : std_logic_vector               := X"3A"; --- ascii character ':'
	constant ci_sequence_limit  : integer                        := 151;

	signal pil_Mclk             : std_logic                      := '1';
    signal pil_nrst             : std_logic                      := cl_SOC_RESET;
    signal pil_DI               : std_logic                      := cl_ENABLE;
    signal pol_DO               : std_logic;
    signal piv_PORTA            : std_logic_vector(15 downto 0) := (others => '1');
    signal piv_PORTB            : std_logic_vector(15 downto 0) := (others => '1');
    signal pov_DDRA             : std_logic_vector(15 downto 0);
    signal pov_DDRB             : std_logic_vector(15 downto 0);
    signal pov_LATA             : std_logic_vector(15 downto 0);
    signal pov_LATB             : std_logic_vector(15 downto 0);
    signal pov_LATD             : std_logic_vector(15 downto 0);

	type tav_hex_sequence is array (integer range <>) of std_logic_vector(7 downto 0);
	constant ctav_hex_sequence : tav_hex_sequence(0 to ci_sequence_limit) := (
        cv_start_code, X"02", X"00", X"00", X"04",
        X"10",  X"00",  X"EA",  
        cv_start_code, X"10", X"00", X"00", X"00",
        X"48",  X"65",  X"6C",  X"6C",  
        X"6F",  X"20",  X"57",  X"6F",  
        X"72",  X"6C",  X"64",  X"21",  
        X"21",  X"00",  X"00",  X"00",  
        X"92",  
        cv_start_code, X"02", X"00", X"00", X"04",
        X"80",  X"00",  X"7A",  
        cv_start_code, X"10", X"00", X"00", X"00",
        X"37",  X"04",  X"00",  X"20",  
        X"B7",  X"04",  X"00",  X"20",  
        X"A1",  X"04",  X"23",  X"20",  
        X"04",  X"00",  X"B7",  X"AF",  
        X"68",  
        cv_start_code, X"10", X"00", X"10", X"00",
        X"A5",  X"A5",  X"93",  X"8F",  
        X"5F",  X"5A",  X"88",  X"40",  
        X"13",  X"45",  X"15",  X"00",  
        X"88",  X"C0",  X"85",  X"45",  
        X"74",  
        cv_start_code, X"10", X"00", X"20", X"00",
        X"21",  X"28",  X"81",  X"45",  
        X"B7",  X"07",  X"00",  X"10",  
        X"03",  X"A7",  X"07",  X"00",  
        X"83",  X"27",  X"C4",  X"FE",  
        X"D6",  
        cv_start_code, X"10", X"00", X"30", X"00",
        X"BA",  X"97",  X"83",  X"C7",  
        X"07",  X"00",  X"C5",  X"B7",  
        X"2D",  X"45",  X"7D",  X"15",  
        X"7D",  X"FD",  X"82",  X"80",  
        X"22",  
        cv_start_code, X"04", X"00", X"40", X"00",
        X"00",  X"00",  X"00",  X"00",  
        X"BC",  
        cv_start_code, X"04", X"00", X"00", X"05",
        X"80",  X"00",  X"00",  X"00",  
        X"77",  
        cv_start_code, X"00", X"00", X"00", X"01",
        X"FF"
    );

	--- baud rate gen ---
	constant ct_bd_period               : time := 2000 ns;
	constant ct_clk_period              : time                        := 83.333 ns;
	constant ci_baud_tick               : integer := ((ct_bd_period / ct_clk_period) / 2 - 1);

	signal sl_brg_counter_en            : std_logic;
	signal sl_brg_counter_match_flag    : std_logic;

	--- receiver ---
	signal sl_rx_half_baud_period_pulse : std_logic := cl_DISABLE;
	signal sv_rx_data                   : std_logic_vector(7 downto 0);
	signal sl_rx_data_valid             : std_logic;
	signal sl_rx_brg_on                 : std_logic;
	signal sv_rx_HOST                   : std_logic_vector(7 downto 0);

    signal sl_check_device_ID           : std_logic;
    signal sl_ID_verified               : std_logic;


    --- uart transmitter procedure ---
	procedure pl_uart_tx(
		data_packet          : in std_logic_vector(7 downto 0);
		signal sl_serial_out : out std_logic
	) is
		constant c_bd_period : time := 2000 ns;

	begin

		-- Send Start Bit
		sl_serial_out <= '0';
		wait for c_bd_period;

		-- Send Data Byte
		for ii in 0 to 7 loop
			sl_serial_out <= data_packet(ii);
			wait for c_bd_period;
		end loop;

		-- Send Stop Bit
		sl_serial_out <= '1';
		wait for c_bd_period;

	end procedure pl_uart_tx;

begin

    dut_top : entity work.pearl3_top
        port map (
            pil_Mclk      => pil_Mclk,
            pil_nrst      => pil_nrst,
            pil_DI        => pil_DI,
            pol_DO        => pol_DO,
            piv_PORTA     => piv_PORTA,
            piv_PORTB     => piv_PORTB,
            pov_DDRA      => pov_DDRA,
            pov_DDRB      => pov_DDRB,
            pov_LATA      => pov_LATA,
            pov_LATB      => pov_LATB,
            pov_LATD      => pov_LATD
        );

	pil_Mclk    <= not pil_Mclk after ct_clk_period / 2;
	pil_nrst    <= cl_SOC_NOTRESET after ct_clk_period;

	-----------------------------------------------------------------------------------------------------
	-------------------------------------- HOST SIDE : UART RX ------------------------------------------
	-----------------------------------------------------------------------------------------------------

	sl_brg_counter_en <= sl_rx_brg_on;

	inst_brg_counter : entity work.counter
		generic map(
			gi_counter_width => 12,
			gi_clksrc_div    => 1
		)
		port map(
			pil_clk                 => pil_Mclk,
			pil_rst                 => not pil_nrst,
			piv_counter_control     => '1' & sl_brg_counter_en,
			piv_counter_prescale    => (others => '0'),
			piv_counter_match_value => std_logic_vector(to_unsigned(ci_baud_tick, 12)),
			pov_counter_value       => open,
			pol_counter_match_flag  => sl_brg_counter_match_flag
		);

	sl_rx_half_baud_period_pulse <= sl_brg_counter_match_flag;

	inst_receiver : entity work.uart_rx
		port map(
			pil_clk                    => pil_Mclk,
			pil_rst                    => not pil_nrst,
			piv_uart_rx_control        => cl_ENABLE & '0',
			pil_half_baud_period_pulse => sl_rx_half_baud_period_pulse,
			pil_uart_rx                => pol_DO,
			pov_rx_data                => sv_rx_data,
			pol_bit9                   => open,
			pol_rx_data_valid          => sl_rx_data_valid,
			pol_error                  => open,
			pol_timer_on               => sl_rx_brg_on,
			pol_rx_busy                => open
		);
    
    proc_host_rx : process (pil_Mclk, pil_nrst)
    begin
        if pil_nrst = cl_SOC_RESET then
            sv_rx_HOST <= (others => '0');
        elsif rising_edge(pil_Mclk) then
            if sl_rx_data_valid = cl_ENABLE then
                sv_rx_HOST <= sv_rx_data;
            end if;
        end if;
    end process proc_host_rx;

    proc_stimuli : process
        procedure pr_debug_enter is
            file f_debug_file           : text;
            variable vln_mem_line       : line;
            variable vs_hex_string      : string(1 to 8);

            constant ctav_debug_seq     : tav_hex_sequence(0 to 5) := (
                cv_dbg_enter,
                X"FF", X"F9", X"01", X"00",  -- match = 0xF9FF prescale = 0, 2 ms tot
                X"01"                        -- enable debug tot
            );
        begin
            for ii in 0 to 5 loop
                pl_uart_tx(data_packet => ctav_debug_seq(ii), sl_serial_out => pil_DI);
            end loop;

            wait for 10 * ct_clk_period;
        end procedure;

        procedure pr_debug_command (
            s_command           : in string;
            v_param             : in std_logic_vector(31 downto 0) := X"00000000";
            v_state             : in std_logic_vector(7 downto 0)  := X"00"
        ) is
            file f_debug_file           : text;
            variable vln_mem_line       : line;
            variable vtav_debug_seq     : tav_hex_sequence(0 to 5);
            variable v_padded_command   : string(1 to 9) := "         ";
        begin

            if s_command'length <= 9 then 
                v_padded_command(1 to s_command'length) := s_command;
            end if;

            case v_padded_command is
                when "resume   " =>
                    vtav_debug_seq(0) := cv_dbg_resume;
                when "exit     " =>
                    vtav_debug_seq(0) := cv_dbg_exit_step;
                when "step     " =>
                    vtav_debug_seq(0) := cv_dbg_step;
                when "pc       " =>
                    vtav_debug_seq(0) := cv_dbg_log_pc_retired;
                when "reg      " =>
                    vtav_debug_seq(0) := cv_dbg_log_REG;
                when "mem      " =>
                    vtav_debug_seq(0) := cv_dbg_log_MEM;
                when "cfg_trig0" =>
                    vtav_debug_seq(0) := cv_dbg_cfg_TRIG0;
                when "cfg_trig1" =>
                    vtav_debug_seq(0) := cv_dbg_cfg_TRIG1;
                when others =>
                    assert false report "Invalid Debug Command!" severity failure;
            end case;

            vtav_debug_seq(1) := v_param(7 downto 0);
            vtav_debug_seq(2) := v_param(15 downto 8);
            vtav_debug_seq(3) := v_param(23 downto 16);
            vtav_debug_seq(4) := v_param(31 downto 24);
            vtav_debug_seq(5) := v_state;

            for ii in 0 to 5 loop
                pl_uart_tx(data_packet => vtav_debug_seq(ii), sl_serial_out => pil_DI);
            end loop;
            
            wait for 10 * ct_clk_period;
        end procedure;

        procedure pr_resume is
            file f_debug_file           : text;
            variable vln_mem_line       : line;
            constant ctav_debug_seq     : tav_hex_sequence(0 to 5) := (
                cv_dbg_resume,
                X"AA", X"BB", X"CC", X"DD",
                X"01"
            );
        begin
            for ii in 0 to 5 loop
                pl_uart_tx(data_packet => ctav_debug_seq(ii), sl_serial_out => pil_DI);
            end loop;
            
            wait for 10 * ct_clk_period;
        end procedure;
    begin
        -- wait for 100 * ct_clk_period;

        ----------------------------------- programmer -----------------------------------------------
        -- pl_uart_tx(data_packet => cv_prg_FLASH_HLT, sl_serial_out => pil_DI);

        -- -- wait for 500 us;

        -- for ii in 0 to ci_sequence_limit loop
		-- 	pl_uart_tx(data_packet => ctav_hex_sequence(ii), sl_serial_out => pil_DI);
		-- 	wait for ct_clk_period * 50;
		-- end loop;
        ----------------------------------------------------------------------------------------------

        if cb_DEBUG = true then
            --- enter debug ---
            pr_debug_enter;
            assert false report "Entered debug mode..." severity note;
            wait for 100 us;
            -------------------
            --- set trigs ---
            wait for 100 us;
            pr_debug_command(s_command =>"cfg_trig0", v_param => X"80000204", v_state => X"01");
            assert false report "1. Trig0 set" severity note;
            wait for 100 us;

            --- continue ---
            pr_debug_command(s_command =>"exit");
            assert false report "Exit step" severity note;
            wait for 100 us;

            pr_debug_command(s_command =>"resume");
            assert false report "Continue till hit" severity note;
            wait for 100 us;
            wait for 1 ms;

            --- continue ---
            pr_debug_command(s_command =>"exit");
            assert false report "Exit step" severity note;
            wait for 100 us;

            pr_debug_command(s_command =>"resume");
            assert false report "Continue till hit" severity note;
            wait for 100 us;
        end if;

        wait for 10 ms;
        assert false report "*** END OF SIMULATION!! ***" severity failure;
    end process proc_stimuli;

end architecture;