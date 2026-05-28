library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.pearl3_soc_pkg.all;

entity host_if is
	generic (
		gi_baud_rate : integer := 115200
	);
    port (
        pil_clk           : in std_logic;
        pil_rst           : in std_logic;
        pil_DI            : in std_logic;
        pol_DO            : out std_logic;
        pov_hif_state     : out std_logic_vector(7 downto 0);

        ----------------------------------------------
        --- signals and packets to/from programmer ---
        pol_isp_sel       : out std_logic;
        pil_isp_done      : in std_logic;
		pol_isp_flash_hlt : out std_logic;

		--- transmit programmer packets to host ---
        pol_isp_next_data : out std_logic;                    -- ack sent to isp to request next data to transmit
        pil_isp_tx_en     : in std_logic;                     -- isp wants to transmit packets to host
        piv_isp_tx_data   : in std_logic_vector(7 downto 0);  -- data to be transmitted

		--- send received packets to programmer ---
        pil_isp_next_data : in std_logic;                     -- isp requests new data from host
        pol_isp_rx_valid  : out std_logic;                    -- '1' indicates valid data
        pov_isp_rx_data   : out std_logic_vector(7 downto 0); -- data from host to isp
        ----------------------------------------------

        ----------------------------------------------
        --- signals and packets to/from debugger ---
        pol_dbg_sel       : out std_logic;
        pil_dbg_done      : in std_logic;

        --- transmit debugger packets to host ---
        pol_dbg_next_data : out std_logic;                   -- ack sent to debugger to request next data transmit
        pil_dbg_tx_en     : in std_logic;                    -- debugger wants to transmit packets to host
        piv_dbg_tx_data   : in std_logic_vector(7 downto 0); -- data to be transmitted

        --- send received packets to debugger ---
        pil_dbg_next_data : in std_logic;                    -- debugger requests new data from host
        pol_dbg_rx_valid  : out std_logic;                   -- '1' indicates valid data
        pov_dbg_rx_data   : out std_logic_vector(7 downto 0) -- data from host to debugger
        ----------------------------------------------
    );
end entity;

architecture rtl of host_if is

    type t_hif_fsm is (
        idle_st,
        decode_command_st,
        isp_handler_st,
		isp_send_packet_st,
        isp_wait_st,
		isp_rec_packet_st,
        dbg_handler_st,
		dbg_send_packet_st,
        dbg_wait_st,
		dbg_rec_packet_st
    );
    signal st_hif_fsm                   : t_hif_fsm;
    signal sv_hif_state                 : std_logic_vector(7 downto 0);

	signal sl_rx_uart_en                : std_logic;
	signal sl_tx_uart_en                : std_logic;
    signal sl_sync_DI_1                 : std_logic;
    signal sl_sync_DI_2                 : std_logic;

	signal sl_isp_sel                   : std_logic;
	signal sl_isp_flash_hlt             : std_logic;
	signal sl_isp_next_tx_data          : std_logic;
	signal sl_isp_rx_valid              : std_logic;
	signal sv_isp_rx_data               : std_logic_vector(7 downto 0);

	signal sl_dbg_sel                   : std_logic;
    signal sl_dbg_next_tx_data          : std_logic;
	signal sl_dbg_rx_valid              : std_logic;
	signal sv_dbg_rx_data               : std_logic_vector(7 downto 0);

	--- baud rate gen ---
	constant ci_baud_tick               : integer := ((ci_CLK_HZ / gi_baud_rate) / 2 - 1);

	signal sl_brg_counter_en            : std_logic;
	signal sl_brg_counter_match_flag    : std_logic;

	--- receiver ---
	signal sl_rx_half_baud_period_pulse : std_logic;
	signal sv_rx_data                   : std_logic_vector(7 downto 0);
	signal sl_rx_data_valid             : std_logic;
	signal sl_rx_brg_on                 : std_logic;

	--- transmitter ---
	signal sl_tx_half_baud_period_pulse : std_logic;
	signal sv_tx_data                   : std_logic_vector(7 downto 0);
	signal sl_tx_ready_next_data        : std_logic;
	signal sl_tx_brg_on                 : std_logic;

begin

    proc_sync_DI : process(pil_clk)
    begin
        if rising_edge(pil_clk) then
            sl_sync_DI_1 <= pil_DI;
            sl_sync_DI_2 <= sl_sync_DI_1;
        end if;
    end process proc_sync_DI;

    proc_host_if_ctrl : process(pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sl_rx_uart_en       <= cl_DISABLE;
            sl_tx_uart_en       <= cl_DISABLE;
			sl_isp_sel          <= cl_DISABLE;
			sl_isp_flash_hlt    <= cl_DISABLE;
			sl_isp_next_tx_data <= cl_DISABLE;
			sl_isp_rx_valid     <= cl_DISABLE;
			sv_isp_rx_data      <= (others => '0');
			sl_dbg_sel          <= cl_DISABLE;
            sl_dbg_next_tx_data <= cl_DISABLE;
			sl_dbg_rx_valid     <= cl_DISABLE;
			sv_dbg_rx_data      <= (others => '0');
            sv_hif_state        <= (others => '0');
            st_hif_fsm          <= idle_st;
        elsif rising_edge(pil_clk) then
            sl_isp_rx_valid     <= cl_DISABLE;
            sl_isp_next_tx_data <= cl_DISABLE;
			sl_dbg_rx_valid     <= cl_DISABLE;
            sl_dbg_next_tx_data <= cl_DISABLE;
            sv_hif_state        <= (others => '0');

            case st_hif_fsm is
                when idle_st =>
					sl_rx_uart_en     <= cl_DISABLE;
					sl_tx_uart_en     <= cl_DISABLE;
					sl_isp_sel        <= cl_DISABLE;
					sl_isp_flash_hlt  <= cl_DISABLE;
                    sv_hif_state(0)   <= cl_ENABLE;

			        sl_dbg_sel        <= cl_DISABLE;

					if sl_sync_DI_2 = cl_START_BIT then
						sl_rx_uart_en <= cl_ENABLE;
						st_hif_fsm    <= decode_command_st;
					end if;
                when decode_command_st =>
                    sv_hif_state(1)   <= cl_ENABLE;

					if sl_rx_data_valid = cl_ENABLE then
						case sv_rx_data is
							when cv_prg_FLASH     =>
								sl_isp_sel        <= cl_ENABLE;
								sl_isp_flash_hlt  <= cl_DISABLE;
								st_hif_fsm        <= isp_handler_st;
							when cv_prg_FLASH_HLT =>
								sl_isp_sel        <= cl_ENABLE;
								sl_isp_flash_hlt  <= cl_ENABLE;
								st_hif_fsm        <= isp_handler_st;
							when cv_dbg_enter     =>
                                sl_dbg_sel        <= cl_ENABLE;
                                st_hif_fsm        <= dbg_handler_st;
							when others           =>
								st_hif_fsm <= idle_st;
						end case;
					end if;
                when isp_handler_st =>
                    sv_hif_state(2)   <= cl_ENABLE;

					if pil_isp_tx_en        = cl_ENABLE then
                        sl_rx_uart_en <= cl_DISABLE;
						st_hif_fsm    <= isp_send_packet_st;
                    elsif pil_isp_next_data = cl_ENABLE then
                        sl_rx_uart_en <= cl_ENABLE;
						st_hif_fsm    <= isp_rec_packet_st;
					elsif pil_isp_done      = cl_ENABLE then
					    sl_isp_sel     <= cl_DISABLE;

                        if sl_isp_flash_hlt = cl_ENABLE then
                            sl_dbg_sel <= cl_ENABLE;
                            st_hif_fsm <= dbg_handler_st;
                        else
                            st_hif_fsm <= idle_st;
                        end if;
					end if;
				when isp_send_packet_st =>
                    sv_hif_state(3)   <= cl_ENABLE;
                    sl_tx_uart_en     <= cl_ENABLE;
                    sv_tx_data        <= piv_isp_tx_data;
                    
                    if sl_tx_ready_next_data = cl_ENABLE then
                        sl_tx_uart_en       <= cl_DISABLE;
                        sl_isp_next_tx_data <= cl_ENABLE;
                        st_hif_fsm          <= isp_wait_st;
					end if;
                when isp_wait_st       =>
                    st_hif_fsm              <= isp_handler_st;
				when isp_rec_packet_st =>
                    sv_hif_state(4)   <= cl_ENABLE;

					if sl_rx_data_valid = cl_ENABLE then
						sl_isp_rx_valid <= cl_ENABLE;
						sv_isp_rx_data  <= sv_rx_data;
					end if;

					if pil_isp_next_data = cl_DISABLE then
						st_hif_fsm <= isp_handler_st;
					end if;
                when dbg_handler_st =>
                    sv_hif_state(5)   <= cl_ENABLE;

                    if pil_dbg_tx_en        = cl_ENABLE then
                        sl_rx_uart_en <= cl_DISABLE;
                        st_hif_fsm    <= dbg_send_packet_st;
                    elsif pil_dbg_next_data = cl_ENABLE then
                        sl_rx_uart_en <= cl_ENABLE;
                        st_hif_fsm    <= dbg_rec_packet_st;
                    elsif pil_dbg_done      = cl_ENABLE then
                        sl_dbg_sel     <= cl_DISABLE;
                        st_hif_fsm     <= idle_st;
                    end if;
                when dbg_send_packet_st =>
                    sv_hif_state(6)   <= cl_ENABLE;
                    sl_tx_uart_en     <= cl_ENABLE;
                    sv_tx_data        <= piv_dbg_tx_data;

                    if sl_tx_ready_next_data = cl_ENABLE then
                        sl_tx_uart_en       <= cl_DISABLE;
                        sl_dbg_next_tx_data <= cl_ENABLE;
                        st_hif_fsm          <= dbg_wait_st;
					end if;
                when dbg_wait_st       =>
                    st_hif_fsm              <= dbg_handler_st;
                when dbg_rec_packet_st =>
                    sv_hif_state(7)   <= cl_ENABLE;

					if sl_rx_data_valid = cl_ENABLE then
						sl_dbg_rx_valid <= cl_ENABLE;
						sv_dbg_rx_data  <= sv_rx_data;
					end if;

					if pil_dbg_next_data = cl_DISABLE then
						st_hif_fsm <= dbg_handler_st;
					end if;
				when others =>
                    st_hif_fsm <= idle_st;
            end case;
        end if;
    end process proc_host_if_ctrl;

	-----------------------------------------------------------------------------------------------------
	-----------------------------------------BAUD RATE GEN-----------------------------------------------
	-----------------------------------------------------------------------------------------------------

	sl_brg_counter_en <= sl_rx_brg_on or sl_tx_brg_on;

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

	-----------------------------------------------------------------------------------------------------
	-----------------------------------------SERIAL RECEIVER---------------------------------------------
	-----------------------------------------------------------------------------------------------------

	sl_rx_half_baud_period_pulse <= sl_brg_counter_match_flag;

	inst_receiver : entity work.uart_rx
		port map(
			pil_clk                    => pil_clk,
			pil_rst                    => pil_rst,
			piv_uart_rx_control        => sl_rx_uart_en & '0',
			pil_half_baud_period_pulse => sl_rx_half_baud_period_pulse,
			pil_uart_rx                => sl_sync_DI_2,
			pov_rx_data                => sv_rx_data,
			pol_bit9                   => open,
			pol_rx_data_valid          => sl_rx_data_valid,
			pol_error                  => open,
			pol_timer_on               => sl_rx_brg_on,
			pol_rx_busy                => open
		);

	-----------------------------------------------------------------------------------------------------
	----------------------------------------SERIAL TRANSMITTER-------------------------------------------
	-----------------------------------------------------------------------------------------------------

	sl_tx_half_baud_period_pulse <= sl_brg_counter_match_flag;

	inst_transmitter : entity work.uart_tx
		port map(
			pil_clk                    => pil_clk,
			pil_rst                    => pil_rst,
			piv_uart_tx_control        => sl_tx_uart_en & '0',
			pil_half_baud_period_pulse => sl_tx_half_baud_period_pulse,
			piv_tx_data                => sv_tx_data,
			pil_bit9                   => '0',
			pol_uart_tx                => pol_DO,
			pol_tx_ready_next_data     => sl_tx_ready_next_data,
			pol_timer_on               => sl_tx_brg_on,
			pol_tx_busy                => open
		);
    
    pol_isp_sel       <= sl_isp_sel;
    pol_isp_flash_hlt <= sl_isp_flash_hlt;
    pol_isp_next_data <= sl_isp_next_tx_data;
    pol_isp_rx_valid  <= sl_isp_rx_valid;
    pov_isp_rx_data   <= sv_isp_rx_data;

    pol_dbg_sel       <= sl_dbg_sel;
    pol_dbg_next_data <= sl_dbg_next_tx_data;
    pol_dbg_rx_valid  <= sl_dbg_rx_valid;
    pov_dbg_rx_data   <= sv_dbg_rx_data;

    pov_hif_state     <= sv_hif_state;

end architecture;
