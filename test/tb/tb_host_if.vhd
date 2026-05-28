library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.options_soc_pkg.all;
use work.pearl3_soc_pkg.all;

entity tb_host_if is
end entity tb_host_if;

architecture tb of tb_host_if is
    
    constant cv_start_code              : std_logic_vector := X"3A"; --- ascii character ':'
    constant ci_PMEM_ORIGIN_BIT         : integer          := fi_get_leading_one(v_value => cv_PMEM_ORIGIN);
    constant ci_CLIC_ORIGIN_BIT         : integer          := fi_get_leading_one(v_value => cv_CLIC_ORIGIN);
    constant ci_IO_ORIGIN_BIT           : integer          := fi_get_leading_one(v_value => cv_IO_ORIGIN);
    constant ci_SRAM_ORIGIN_BIT         : integer          := fi_get_leading_one(v_value => cv_SRAM_ORIGIN);

    signal pil_clk                      : std_logic := '1';
    signal pil_rst                      : std_logic := cl_RESET;
    signal pil_DI                       : std_logic := cl_ENABLE;
    signal pol_DO                       : std_logic;
    signal pol_isp_sel                  : std_logic;
    signal pil_isp_done                 : std_logic := cl_DISABLE;
    signal pol_isp_flash_hlt            : std_logic;
    signal pol_isp_next_data            : std_logic;
    signal pil_isp_tx_en                : std_logic := cl_DISABLE;
    signal piv_isp_tx_data              : std_logic_vector(7 downto 0) := (others => '0');
    signal pil_isp_next_data            : std_logic := cl_DISABLE;
    signal pol_isp_rx_valid             : std_logic;
    signal pov_isp_rx_data              : std_logic_vector(7 downto 0);
    signal pol_dbg_sel                  : std_logic;
    signal pil_dbg_done                 : std_logic := cl_DISABLE;
    signal pol_dbg_next_data            : std_logic;
    signal pil_dbg_tx_en                : std_logic := cl_DISABLE;
    signal piv_dbg_tx_data              : std_logic_vector(7 downto 0) := (others => '0');
    signal pil_dbg_next_data            : std_logic := cl_DISABLE;
    signal pol_dbg_rx_valid             : std_logic;
    signal pov_dbg_rx_data              : std_logic_vector(7 downto 0);

	constant ct_clk_period              : time := 15.625 ns;
	constant ct_bd_period               : time := 2000 ns;

    --- programmer ---
    signal pol_reset                    : std_logic;
    signal pol_core_start               : std_logic;
    signal pil_prg_sel                  : std_logic;
    signal pol_prg_done                 : std_logic;
    signal pil_prg_flash_hlt            : std_logic;
    signal pil_prg_next_data            : std_logic;                      -- host_if requesting new data to transmit
    signal pol_prg_tx_en                : std_logic;                     -- set host_if to transmit mode
    signal pov_prg_tx_data              : std_logic_vector(7 downto 0);
    signal pol_prg_next_data            : std_logic;                     -- request new data to receive
    signal pil_prg_rx_valid             : std_logic;                      -- rx data is valid
    signal piv_prg_rx_data              : std_logic_vector(7 downto 0);

	signal sl_prg_mem_req               : std_logic;
	signal sl_prg_mem_wen               : std_logic;
	signal sv_prg_mem_addr              : std_logic_vector(31 downto 0);
	signal sv_prg_mem_wdata             : std_logic_vector(31 downto 0);

    --- debugger_ctrl ---
    signal pil_dbgctrl_sel              : std_logic;
    signal pol_dbgctrl_done             : std_logic;
    signal pil_dbgctrl_next_data        : std_logic;                    -- host_if requesting new data to transmittransmit
    signal pol_dbgctrl_tx_en            : std_logic;                    -- set host_if to transmit mode
    signal pov_dbgctrl_tx_data          : std_logic_vector(7 downto 0);
    signal pol_dbgctrl_next_data        : std_logic;                    -- request new data to receiveta from host
    signal pil_dbgctrl_rx_valid         : std_logic;                    -- rx data is valid
    signal piv_dbgctrl_rx_data          : std_logic_vector(7 downto 0);
    signal pol_dbg_mem_access           : std_logic;
    signal pov_dbg_mem_addr             : std_logic_vector(31 downto 0);
    signal piv_dbg_mem_rdata            : std_logic_vector(31 downto 0);
    signal pol_debug_haltreq            : std_logic;
    signal pol_debug_resumereq          : std_logic;
    signal pil_debug_halted             : std_logic := cl_DISABLE;
    signal piv_debug_pc_retired         : std_logic_vector(31 downto 0) := (others => '0');
    signal pol_debug_regreq             : std_logic;
    signal pov_debug_regno              : std_logic_vector(11 downto 0);
    signal pol_debug_write              : std_logic;
    signal pov_debug_wdata              : std_logic_vector(31 downto 0);
    signal piv_debug_rdata              : std_logic_vector(31 downto 0) := (others => '0');
    signal pil_debug_ack                : std_logic := cl_DISABLE;
    signal pil_debug_err                : std_logic := cl_DISABLE;

    --- debug simulation ---
    signal sl_dbg_mem_access            : std_logic;
    signal sv_dbg_mem_addr              : std_logic_vector(31 downto 0);
    signal sv_dbg_mem_rdata             : std_logic_vector(31 downto 0);
    signal sl_debug_haltreq             : std_logic;
    signal sl_debug_resumereq           : std_logic;
    signal sl_debug_halted              : std_logic;
    signal sv_debug_pc_retired          : std_logic_vector(31 downto 0);
    signal sl_debug_regreq              : std_logic;
    signal sv_debug_regno               : std_logic_vector(11 downto 0);
    signal sl_debug_write               : std_logic;
    signal sv_debug_wdata               : std_logic_vector(31 downto 0);
    signal sv_debug_rdata               : std_logic_vector(31 downto 0);
    signal sl_debug_ack                 : std_logic;
    signal sl_debug_err                 : std_logic;

    --- pmem controller ---
    signal sl_pmem_wen                  : std_logic;
    signal sv_pmem_addr                 : std_logic_vector(31 downto 0);
    signal sv_pmem_wdata                : std_logic_vector(31 downto 0);
    signal sv_pmem_rdata                : std_logic_vector(31 downto 0);

    --- sram controller ---
	signal sl_sram_prg_req              : std_logic;
	signal sl_sram_req                  : std_logic;
	signal sl_sram_wen                  : std_logic;
	signal sl_sram_ack                  : std_logic;
	signal sl_sram_valid                : std_logic;
	signal sv_sram_byte_sel             : std_logic_vector(3 downto 0);
	signal sv_sram_addr                 : std_logic_vector(31 downto 0);
	signal sv_sram_wdata                : std_logic_vector(31 downto 0);
	signal sv_sram_rdata                : std_logic_vector(31 downto 0);

	--- baud rate gen ---
	constant ci_baud_tick               : integer := ((ct_bd_period / ct_clk_period) / 2 - 1);

	signal sl_brg_counter_en            : std_logic;
	signal sl_brg_counter_match_flag    : std_logic;

	--- receiver ---
	signal sl_rx_half_baud_period_pulse : std_logic := cl_DISABLE;
	signal sv_rx_data                   : std_logic_vector(7 downto 0);
	signal sl_rx_data_valid             : std_logic;
	signal sl_rx_brg_on                 : std_logic;

	signal sv_rx_HOST                   : std_logic_vector(7 downto 0);

	type tav_hex_sequence is array (integer range <>) of std_logic_vector(7 downto 0);

    constant ctav_host2prg : tav_hex_sequence(0 to 151) := (
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

    constant ctav_prg2host : tav_hex_sequence(0 to 3) := (
        X"AA", X"BB", X"CC", X"DD"
    );

    constant ctav_host2dbg : tav_hex_sequence(0 to 5) := (
        cv_dbg_log_REG,
        X"01", X"23", X"45", X"67",
        X"FF"
    );

    constant ctav_dbg2host : tav_hex_sequence(0 to 3) := (
        X"99", X"88", X"77", X"66"
    );

    --- uart transmitter procedure ---
	procedure pl_uart_tx(
		data_packet          : in std_logic_vector(7 downto 0);
		signal sl_serial_out : out std_logic
	) is

	begin

		-- Send Start Bit
		sl_serial_out <= '0';
		wait for ct_bd_period;

		-- Send Data Byte
		for ii in 0 to 7 loop
			sl_serial_out <= data_packet(ii);
			wait for ct_bd_period;
		end loop;

		-- Send Stop Bit
		sl_serial_out <= '1';
		wait for ct_bd_period;

	end procedure pl_uart_tx;

begin

	-----------------------------------------------------------------------------------------------------
	---------------------------------------------- DUT --------------------------------------------------
	-----------------------------------------------------------------------------------------------------

    pil_isp_done      <= pol_prg_done;
    pil_isp_tx_en     <= pol_prg_tx_en;
    piv_isp_tx_data   <= pov_prg_tx_data;
    pil_isp_next_data <= pol_prg_next_data;

    pil_dbg_done      <= pol_dbgctrl_done;
    pil_dbg_tx_en     <= pol_dbgctrl_tx_en;
    piv_dbg_tx_data   <= pov_dbgctrl_tx_data;
    pil_dbg_next_data <= pol_dbgctrl_next_data;

    dut_host_if : entity work.host_if
        generic map (
            gi_baud_rate => 500_000
        )
        port map (
            pil_clk           => pil_clk,
            pil_rst           => pil_rst,
            pil_DI            => pil_DI,
            pol_DO            => pol_DO,
            pol_isp_sel       => pol_isp_sel,
            pil_isp_done      => pil_isp_done,
            pol_isp_flash_hlt => pol_isp_flash_hlt,
            pol_isp_next_data => pol_isp_next_data,
            pil_isp_tx_en     => pil_isp_tx_en,
            piv_isp_tx_data   => piv_isp_tx_data,
            pil_isp_next_data => pil_isp_next_data,
            pol_isp_rx_valid  => pol_isp_rx_valid,
            pov_isp_rx_data   => pov_isp_rx_data,
            pol_dbg_sel       => pol_dbg_sel,
            pil_dbg_done      => pil_dbg_done,
            pol_dbg_next_data => pol_dbg_next_data,
            pil_dbg_tx_en     => pil_dbg_tx_en,
            piv_dbg_tx_data   => piv_dbg_tx_data,
            pil_dbg_next_data => pil_dbg_next_data,
            pol_dbg_rx_valid  => pol_dbg_rx_valid,
            pov_dbg_rx_data   => pov_dbg_rx_data
        );
    
	pil_clk     <= not pil_clk after ct_clk_period / 2;
	pil_rst     <= cl_NOTRESET after ct_clk_period;

	-----------------------------------------------------------------------------------------------------
	------------------------------------------- PROGRAMMER ----------------------------------------------
	-----------------------------------------------------------------------------------------------------

    pil_prg_sel       <= pol_isp_sel;
    pil_prg_flash_hlt <= pol_isp_flash_hlt;
    pil_prg_next_data <= pol_isp_next_data;
    pil_prg_rx_valid  <= pol_isp_rx_valid;
    piv_prg_rx_data   <= pov_isp_rx_data;

    inst_programmer : entity work.programmer
        generic map (
            gs_device_id         => "PRVX3IMC48SH.0006"
        )
        port map (
            pil_clk              => pil_clk,
            pil_rst              => pil_rst,
            pol_reset            => pol_reset,
            pol_core_start       => pol_core_start,
            pil_prg_sel          => pil_prg_sel,
            pol_prg_done         => pol_prg_done,
            pil_prg_flash_hlt    => pil_prg_flash_hlt,
            pil_prg_next_data    => pil_prg_next_data,
            pol_prg_tx_en        => pol_prg_tx_en,
            pov_prg_tx_data      => pov_prg_tx_data,
            pol_prg_next_data    => pol_prg_next_data,
            pil_prg_rx_valid     => pil_prg_rx_valid,
            piv_prg_rx_data      => piv_prg_rx_data,
            pol_mem_req          => sl_prg_mem_req,
            pol_mem_wen          => sl_prg_mem_wen,
            pov_mem_addr         => sv_prg_mem_addr,
            pov_mem_wdata        => sv_prg_mem_wdata
        );

	-----------------------------------------------------------------------------------------------------
	------------------------------------------- DEBUG CTRL ----------------------------------------------
	-----------------------------------------------------------------------------------------------------

    pil_dbgctrl_sel       <= pol_dbg_sel;
    pil_dbgctrl_next_data <= pol_dbg_next_data;
    pil_dbgctrl_rx_valid  <= pol_dbg_rx_valid;
    piv_dbgctrl_rx_data   <= pov_dbg_rx_data;

    piv_dbg_mem_rdata     <= sv_dbg_mem_rdata;
    pil_debug_halted      <= sl_debug_halted;
    piv_debug_pc_retired  <= sv_debug_pc_retired;
    piv_debug_rdata       <= sv_debug_rdata;
    pil_debug_ack         <= sl_debug_ack;
    pil_debug_err         <= sl_debug_err;

    inst_debug_ctrl : entity work.debugger_ctrl
        port map (
            pil_clk               => pil_clk,
            pil_rst               => pil_rst,
            pil_dbg_sel           => pil_dbgctrl_sel,
            pol_dbg_done          => pol_dbgctrl_done,
            pil_dbg_next_data     => pil_dbgctrl_next_data,
            pol_dbg_tx_en         => pol_dbgctrl_tx_en,
            pov_dbg_tx_data       => pov_dbgctrl_tx_data,
            pol_dbg_next_data     => pol_dbgctrl_next_data,
            pil_dbg_rx_valid      => pil_dbgctrl_rx_valid,
            piv_dbg_rx_data       => piv_dbgctrl_rx_data,
            pol_dbg_mem_access    => pol_dbg_mem_access,
            pov_dbg_mem_addr      => pov_dbg_mem_addr,
            piv_dbg_mem_rdata     => piv_dbg_mem_rdata,
            pol_debug_haltreq     => pol_debug_haltreq,
            pol_debug_resumereq   => pol_debug_resumereq,
            pil_debug_halted      => pil_debug_halted,
            piv_debug_pc_retired  => piv_debug_pc_retired,
            pol_debug_regreq      => pol_debug_regreq,
            pov_debug_regno       => pov_debug_regno,
            pol_debug_write       => pol_debug_write,
            pov_debug_wdata       => pov_debug_wdata,
            piv_debug_rdata       => piv_debug_rdata,
            pil_debug_ack         => pil_debug_ack,
            pil_debug_err         => pil_debug_err
        );
    
    sl_dbg_mem_access  <= pol_dbg_mem_access;
    sv_dbg_mem_addr    <= pov_dbg_mem_addr;
    sl_debug_haltreq   <= pol_debug_haltreq;
    sl_debug_resumereq <= pol_debug_resumereq;
    sl_debug_regreq    <= pol_debug_regreq;
    sv_debug_regno     <= pov_debug_regno;
    sl_debug_write     <= pol_debug_write;
    sv_debug_wdata     <= pov_debug_wdata;
    
    proc_debug_sim : process (pil_clk, pil_rst)
        variable vi_sim_delay : integer range 0 to 63;
    begin
        if pil_rst = cl_RESET then
            sv_dbg_mem_rdata    <= (others => '0');
            sl_debug_halted     <= cl_DISABLE;
            sv_debug_pc_retired <= X"CAAD0001";
            sv_debug_rdata      <= (others => '0');
            sl_debug_ack        <= cl_DISABLE;
            sl_debug_err        <= cl_DISABLE;
            vi_sim_delay        := 0;
        elsif rising_edge(pil_clk) then
            if sl_debug_haltreq = cl_ENABLE or sl_debug_resumereq = cl_ENABLE then
                if vi_sim_delay < 7 then
                    vi_sim_delay := vi_sim_delay + 1;
                else
                    vi_sim_delay    := 0;
                    sl_debug_halted <= cl_ENABLE;
                end if;
            elsif sl_debug_regreq = cl_ENABLE or sl_dbg_mem_access = cl_ENABLE then
                sv_debug_rdata    <= X"FA000" & sv_debug_regno;
                sv_dbg_mem_rdata  <= X"FA000" & sv_debug_regno;
                sl_debug_ack      <= cl_ENABLE;
            end if;
        end if;
    end process proc_debug_sim;

    -----------------------------------------------------------------------------------------------------
    ----------------------------------------PMEM CONTROLLER----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_pmem_wen   <= sl_prg_mem_wen and sv_prg_mem_addr(ci_PMEM_ORIGIN_BIT) when sl_prg_mem_req = cl_ENABLE else
        cl_DISABLE;
    sv_pmem_addr  <= sv_prg_mem_addr and X"0000_FFFC" when sl_prg_mem_req = cl_ENABLE else
        (others => '0');
    sv_pmem_wdata <= sv_prg_mem_wdata;

    inst_pmem_controller : entity work.pmem_controller
        generic map (
            gv_NUM_WORDS      => cv_PMEM_NUM_WORDS
        )
        port map (
            pil_clk           => pil_clk,
            pil_rst           => pil_rst,
            pil_pmem_wen      => sl_pmem_wen,
            piv_pmem_addr     => sv_pmem_addr,
            piv_pmem_wdata    => sv_pmem_wdata,
            pov_pmem_rdata    => sv_pmem_rdata
        );

    -----------------------------------------------------------------------------------------------------
    ----------------------------------------SRAM CONTROLLER----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_sram_prg_req  <= sv_prg_mem_addr(ci_SRAM_ORIGIN_BIT) when sl_prg_mem_req = cl_ENABLE else
        cl_DISABLE;
    sl_sram_req      <= cl_DISABLE;
    sl_sram_wen      <= sl_prg_mem_wen and sv_prg_mem_addr(ci_SRAM_ORIGIN_BIT) when sl_prg_mem_req = cl_ENABLE else
        cl_DISABLE; 
    sv_sram_byte_sel <= "1111" when sl_prg_mem_req = cl_ENABLE else
        "0000"; 
    sv_sram_addr     <= sv_prg_mem_addr and X"0000_FFFC" when sl_prg_mem_req = cl_ENABLE else
        (others => '0');
    sv_sram_wdata    <= sv_prg_mem_wdata when sl_prg_mem_req = cl_ENABLE else
        (others => '0');

    inst_mem_controller : entity work.mem_controller
        generic map (
            gv_NUM_BYTES      => cv_SRAM_NUM_BYTES
        )
        port map (
            pil_clk           => pil_clk,
            pil_rst           => pil_rst,
            pil_mem_prg_req   => sl_sram_prg_req,
            pil_mem_req       => sl_sram_req,
            pil_mem_wen       => sl_sram_wen,
            pol_mem_ack       => sl_sram_ack,
            pol_mem_valid     => sl_sram_valid,
                                
            piv_mem_byte_sel  => sv_sram_byte_sel,
            piv_mem_addr      => sv_sram_addr,
            piv_mem_wdata     => sv_sram_wdata,
            pov_mem_rdata     => sv_sram_rdata
        );

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
			pil_clk                 => pil_clk,
			pil_rst                 => pil_rst,
			piv_counter_control     => '1' & sl_brg_counter_en,
			piv_counter_prescale    => (others => '0'),
			piv_counter_match_value => std_logic_vector(to_unsigned(ci_baud_tick, 12)),
			pov_counter_value       => open,
			pol_counter_match_flag  => sl_brg_counter_match_flag
		);

	sl_rx_half_baud_period_pulse <= sl_brg_counter_match_flag;

	inst_receiver : entity work.uart_rx
		port map(
			pil_clk                    => pil_clk,
			pil_rst                    => pil_rst,
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
    
    proc_host : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sv_rx_HOST <= (others => '0');
        elsif rising_edge(pil_clk) then
            if sl_rx_data_valid = cl_ENABLE then
                sv_rx_HOST <= sv_rx_data;
            end if;
        end if;
    end process proc_host;
    
    proc_stimuli : process
    begin
        wait for 10 * ct_clk_period;

        ----------------------------------- programmer -----------------------------------------------

        pl_uart_tx(data_packet => cv_prg_FLASH, sl_serial_out => pil_DI);

        wait for 100 * ct_clk_period;
        assert pol_isp_sel = cl_ENABLE report "Expected ISP select to be High" severity failure;

        --- receive programmer packets from host ---
        wait until rising_edge(pol_prg_next_data); -- isp is ready to receive data

        for ii in 0 to 151 loop
		    wait for ct_clk_period * 10;
            pl_uart_tx(data_packet => ctav_host2prg(ii), sl_serial_out => pil_DI);
		end loop;
        
        wait for 100 * ct_clk_period;
        assert pol_isp_sel = cl_DISABLE report "Expected ISP select to be Low" severity failure;

        ------------------------------------- debug -----------------------------------------------

        wait for 100_000 * ct_clk_period;
        
        pl_uart_tx(data_packet => cv_dbg_enter, sl_serial_out => pil_DI);

        wait until rising_edge(pol_dbgctrl_next_data); -- debugger is ready to receive command
        assert false report "In Debug mode" severity note;

        wait for 10_000 * ct_clk_period;


        --- receive programmer packets from host ---
        for ii in 0 to 5 loop
		    wait for ct_clk_period * 1000;
            pl_uart_tx(data_packet => ctav_host2dbg(ii), sl_serial_out => pil_DI);
		end loop;

        wait for 1000_000 * ct_clk_period;
        
        -- pil_dbg_next_data <= cl_DISABLE;
        -- wait for 10 * ct_clk_period;
        -- pil_dbg_done <= cl_ENABLE;
        
        -- wait for ct_clk_period;
        -- assert pol_dbg_sel = cl_DISABLE report "Expected DBG select to be Low" severity failure;

        wait for 10_000 * ct_clk_period;
        assert false report "*** END OF SIMULATION!! ***" severity failure;
    end process proc_stimuli;

end architecture;