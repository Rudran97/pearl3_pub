library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.pearl3_soc_pkg.all;
use work.csr_op_unit_pkg.all;

entity debugger_ctrl is
    port (
        pil_clk   : in std_logic;
        pil_rst   : in std_logic;

        --- signals and packets to/from host_if ---
        pil_dbg_sel       : in std_logic;
        pol_dbg_done      : out std_logic;

        --- transmit ---
        pil_dbg_next_data : in std_logic;                     -- host_if requesting new data to transmit
        pol_dbg_tx_en     : out std_logic;                    -- set host_if to transmit mode
        pov_dbg_tx_data   : out std_logic_vector(7 downto 0);

        --- receive ---
        pol_dbg_next_data : out std_logic;                    -- request new data to receiveta from host
        pil_dbg_rx_valid  : in std_logic;                     -- rx data is valid
        piv_dbg_rx_data   : in std_logic_vector(7 downto 0);

		---------------------------------
        --- debugger/memory interface ---
        pol_dbg_mem_access   : out std_logic;
        pov_dbg_mem_addr     : out std_logic_vector(31 downto 0);
        pol_dbg_mem_write    : out std_logic;
        pov_dbg_mem_wdata    : out std_logic_vector(31 downto 0);
        piv_dbg_mem_rdata    : in std_logic_vector(31 downto 0);

        --- core/debugger interface ---
        pol_debug_haltreq    : out std_logic;
        pol_debug_resumereq  : out std_logic;
        pil_debug_halted     : in std_logic;
		piv_debug_pc_retired : in std_logic_vector(31 downto 0);

        pol_debug_regreq     : out std_logic;
        pov_debug_regno      : out std_logic_vector(11 downto 0);
        pol_debug_write      : out std_logic;
        pov_debug_wdata      : out std_logic_vector(31 downto 0);
        piv_debug_rdata      : in std_logic_vector(31 downto 0);
        pil_debug_ack        : in std_logic;
        pil_debug_err        : in std_logic
    );
end entity debugger_ctrl;

architecture rtl of debugger_ctrl is
    
    type t_dbg_fsm is (
        wait_host_ready_st,
        idle_st,
        debug_enter_st,
        debug_rec_command_st,
        parse_command_st,
        dbg_log_reg_st,
        dbg_set_reg_st,
        dbg_log_mem_st,
        dbg_set_mem_st,
        dbg_set_value_st,
        dbg_log_pc_ret_st,
        dbg_step_st,
        dbg_resume_st,
        dbg_enter_st,
        dbg_exit_step_st,
        dbg_cfg_trig0_st,
        dbg_cfg_trig1_st,
        wait_on_tselect_st,
        dbg_set_tdata1_st,
        wait_on_tdata1_st,
        dbg_set_tdata2_st,
        wait_dbg_done_st,
        debug_response_st
	);
    signal st_dbg_fsm                   : t_dbg_fsm;

    signal sl_dbg_done                  : std_logic;
    signal sl_dbg_tx_en                 : std_logic;
    signal sv_dbg_tx_data               : std_logic_vector(31 downto 0);
    signal sl_dbg_rec_data              : std_logic;
    
    signal si_dbg_tx_packet_idx_ct      : integer range 0 to 63;
    signal si_dbg_rx_packet_idx_ct      : integer range 0 to 5;
    signal si_resp_byte_ct              : integer range 0 to 3;

    --- debugger fsm internal signals ---
    signal sl_en_parsing                : std_logic;
    signal sl_already_in_debug          : std_logic;
    signal sl_is_in_step                : std_logic;
    signal sv_is_in_trig                : std_logic_vector(1 downto 0); -- bit 1 represents trig1, bit 0 represents trig0
    signal sl_debug_log_reg             : std_logic;
    signal sl_debug_log_mem             : std_logic;
    signal sl_debug_log_pc_ret          : std_logic;

    signal sl_debug_tot_en              : std_logic; -- when enabled, debugger will raise timeout error if it didn't respond
                                                     -- within a specified time frame provided in the debug parameters during
                                                     -- debug entry.
    signal sl_debug_tot_start           : std_logic;
    signal sv_debug_tot_reg             : std_logic_vector(31 downto 0);
    signal sl_debug_tot_flag            : std_logic;

    signal sl_counter_on                : std_logic;
    signal sv_counter_prescale          : std_logic_vector(15 downto 0);
    signal sv_counter_match             : std_logic_vector(15 downto 0);

    type tav_dbg_command is array (0 to 5) of std_logic_vector(7 downto 0);
    signal stav_dbg_command             : tav_dbg_command; -- [0] contains command [1..4] contains parameter [5] options

    --- signals declared for debugger module ---
    signal sl_dbg_ctrl_en               : std_logic;
    signal sv_dbg_ctrl_command          : std_logic_vector(7 downto 0);
    signal sv_dbg_ctrl_rdata            : std_logic_vector(31 downto 0);
    signal sv_dbg_ctrl_wdata            : std_logic_vector(31 downto 0);
    signal sl_dbg_ctrl_done             : std_logic;
    signal sl_dbg_ctrl_err              : std_logic;
    signal sv_dbg_ctrl_set_val          : std_logic_vector(31 downto 0); -- holds the value to be written to reg/mem
    signal sl_dbg_mem_access            : std_logic;
    signal sv_dbg_mem_addr              : std_logic_vector(31 downto 0);
    signal sl_dbg_mem_write             : std_logic;
    signal sv_dbg_mem_wdata             : std_logic_vector(31 downto 0);
    signal sl_debug_haltreq             : std_logic;
    signal sl_debug_resumereq           : std_logic;
    signal sl_debug_regreq              : std_logic;
    signal sv_debug_regno               : std_logic_vector(11 downto 0);
    signal sl_debug_write               : std_logic;
    signal sv_debug_wdata               : std_logic_vector(31 downto 0);

	type tav_CSR is array (0 to 20) of std_logic_vector(11 downto 0);
	constant ctav_CSR                   : tav_CSR := (
		X"301",
		X"F11",
		X"F12",
		X"F13",
		X"F14",
		X"B02",
		X"300",
		X"304",
		X"305",
		X"344",
		X"342",
		X"341",
		X"340",
		X"343",
		X"7A0",
		X"7A1",
		X"7A2",
		X"7B0",
		X"7B1",
		X"7B2",
		X"7B3"
	);

begin

    proc_dbg : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sl_dbg_done               <= cl_DISABLE;
            sl_dbg_tx_en              <= cl_DISABLE;
            sv_dbg_tx_data            <= (others => '0');
            sl_dbg_rec_data           <= cl_DISABLE;

            sl_dbg_ctrl_en            <= cl_DISABLE;
            st_dbg_fsm                <= idle_st;

            si_dbg_tx_packet_idx_ct   <= 0;
            si_dbg_rx_packet_idx_ct   <= 0;
            si_resp_byte_ct           <= 0;
            sl_en_parsing             <= cl_DISABLE;
            sl_already_in_debug       <= cl_DISABLE;
            sl_is_in_step             <= cl_DISABLE;
            sv_is_in_trig             <= "00";
            sl_debug_log_reg          <= cl_DISABLE;
            sl_debug_log_mem          <= cl_DISABLE;
            sl_debug_log_pc_ret       <= cl_DISABLE;
            sl_debug_tot_en           <= cl_DISABLE;
            sl_debug_tot_start        <= cl_DISABLE;
            sv_debug_tot_reg          <= (others => '0');
            sv_dbg_ctrl_set_val       <= (others => '0');

            for ii in 0 to 5 loop
                stav_dbg_command(ii) <= (others => '0');
            end loop;
        elsif rising_edge(pil_clk) then
            sl_debug_tot_start  <= cl_DISABLE;

            case st_dbg_fsm is
                when wait_host_ready_st =>
                    if sl_dbg_done = cl_ENABLE then
                        if pil_dbg_sel = cl_DISABLE then
                            st_dbg_fsm <= idle_st;
                        end if;
                    else
                        st_dbg_fsm <= idle_st;
                    end if;
                when idle_st =>
                    sl_dbg_done         <= cl_DISABLE;
                    sl_dbg_tx_en        <= cl_DISABLE;
                    sl_dbg_rec_data     <= cl_DISABLE;
                    sl_en_parsing       <= cl_DISABLE;
                    sl_already_in_debug <= cl_DISABLE;
                    sl_debug_tot_en     <= cl_DISABLE;

                    if pil_dbg_sel = cl_ENABLE then
                        st_dbg_fsm <= debug_enter_st;
                    end if;
                when debug_enter_st =>
                    stav_dbg_command(0)     <= cv_dbg_enter;
                    si_dbg_rx_packet_idx_ct <= 1; -- set the idx to 1 since we already received the cmd
                    sl_en_parsing           <= cl_ENABLE;
                    --- already received the cmd and incremented the rx_packet_idx. Now receive the next 5 data ---
                    st_dbg_fsm              <= debug_rec_command_st;
                when debug_rec_command_st =>
                    if sl_en_parsing  = cl_ENABLE then
                        sl_dbg_rec_data     <= cl_ENABLE;

                        if pil_dbg_rx_valid = cl_ENABLE then
                            stav_dbg_command(si_dbg_rx_packet_idx_ct) <= piv_dbg_rx_data;

                            if si_dbg_rx_packet_idx_ct < 5 then
                                si_dbg_rx_packet_idx_ct <= si_dbg_rx_packet_idx_ct + 1;
                            else
                                si_dbg_rx_packet_idx_ct <= 0;

                                sl_dbg_rec_data <= cl_DISABLE;
                                st_dbg_fsm      <= parse_command_st;
                            end if;
                        end if;
                    else
                        sl_dbg_done <= cl_ENABLE;
                        st_dbg_fsm  <= wait_host_ready_st;
                    end if;
                when parse_command_st =>
                    if sl_en_parsing  = cl_ENABLE and sl_already_in_debug = cl_ENABLE then
                        case stav_dbg_command(0) is
                            when cv_dbg_log_REG =>
                                sl_debug_log_reg <= cl_ENABLE;
                                st_dbg_fsm       <= dbg_log_reg_st;
                            when cv_dbg_set_REG =>
                                st_dbg_fsm       <= dbg_set_reg_st;
                            when cv_dbg_log_MEM =>
                                sl_debug_log_mem <= cl_ENABLE;
                                st_dbg_fsm       <= dbg_log_mem_st;
                            when cv_dbg_set_MEM =>
                                st_dbg_fsm       <= dbg_set_mem_st;
                            when cv_dbg_set_value =>
                                st_dbg_fsm       <= dbg_set_value_st;
                            when cv_dbg_log_pc_retired =>
                                sl_debug_log_pc_ret <= cl_ENABLE;
                                st_dbg_fsm          <= dbg_log_pc_ret_st;
                            when cv_dbg_step =>
                                sl_is_in_step    <= cl_ENABLE;
                                st_dbg_fsm       <= dbg_step_st;
                            when cv_dbg_resume =>
                                st_dbg_fsm  <= dbg_resume_st;
                            when cv_dbg_exit_step =>
                                sl_is_in_step <= cl_DISABLE;
                                st_dbg_fsm    <= dbg_exit_step_st;
                            when cv_dbg_cfg_TRIG0 =>
                                sv_is_in_trig(0) <= stav_dbg_command(5)(0);
                                st_dbg_fsm       <= dbg_cfg_trig0_st;
                            when cv_dbg_cfg_TRIG1 =>
                                sv_is_in_trig(1) <= stav_dbg_command(5)(0);
                                st_dbg_fsm       <= dbg_cfg_trig1_st;
                            when cv_dbg_enter     =>
                                st_dbg_fsm     <= dbg_enter_st;
                            when others =>
                                sv_dbg_tx_data <= X"0000" & stav_dbg_command(0) & cv_host_dbg_comm_err;
                                st_dbg_fsm     <= debug_response_st;
                        end case;
                    else
                        --- when not in debug mode or the signal already_in_debug has be deasserted due to debug time out,
                        --- then only accept debug entry commands ---
                        if stav_dbg_command(0) = cv_dbg_enter then
                            st_dbg_fsm     <= dbg_enter_st;
                        else
                            sv_dbg_tx_data <= X"000000" & cv_host_noerr;
                            st_dbg_fsm     <= debug_response_st;
                        end if;
                    end if;
                when dbg_log_reg_st =>
                    sl_dbg_ctrl_en <= cl_ENABLE;
                    st_dbg_fsm     <= wait_dbg_done_st;
                    
                    if si_dbg_tx_packet_idx_ct < 32 then
                        si_dbg_tx_packet_idx_ct <= si_dbg_tx_packet_idx_ct + 1;
                        sv_dbg_ctrl_rdata       <= std_logic_vector(X"0000_0000" + to_unsigned(si_dbg_tx_packet_idx_ct, 32));
                    elsif si_dbg_tx_packet_idx_ct < 53 then
                        si_dbg_tx_packet_idx_ct <= si_dbg_tx_packet_idx_ct + 1;
                        sv_dbg_ctrl_rdata       <= X"00000" & ctav_CSR(si_dbg_tx_packet_idx_ct - 32);
                    else
                        si_dbg_tx_packet_idx_ct <= 0;
                        sl_debug_log_reg        <= cl_DISABLE;
                        sl_dbg_ctrl_en          <= cl_DISABLE;
                        st_dbg_fsm              <= debug_rec_command_st;
                    end if;
                when dbg_set_reg_st =>
                    sl_dbg_ctrl_en    <= cl_ENABLE;
                    sv_dbg_ctrl_rdata <= stav_dbg_command(4) & stav_dbg_command(3) & stav_dbg_command(2) & stav_dbg_command(1);
                    st_dbg_fsm        <= wait_dbg_done_st;
                when dbg_log_mem_st =>
                    sl_dbg_ctrl_en    <= cl_ENABLE;
                    sv_dbg_ctrl_rdata <= stav_dbg_command(4) & stav_dbg_command(3) & stav_dbg_command(2) & stav_dbg_command(1)(7 downto 2) & "00";
                    st_dbg_fsm        <= wait_dbg_done_st;
                    
                    if si_dbg_tx_packet_idx_ct < 1 then
                        si_dbg_tx_packet_idx_ct <= si_dbg_tx_packet_idx_ct + 1;
                    else
                        si_dbg_tx_packet_idx_ct <= 0;
                        sl_debug_log_mem        <= cl_DISABLE;
                        sl_dbg_ctrl_en          <= cl_DISABLE;
                        st_dbg_fsm              <= debug_rec_command_st;
                    end if;
                when dbg_set_mem_st =>
                    sl_dbg_ctrl_en    <= cl_ENABLE;
                    sv_dbg_ctrl_rdata <= stav_dbg_command(4) & stav_dbg_command(3) & stav_dbg_command(2) & stav_dbg_command(1)(7 downto 2) & "00";
                    st_dbg_fsm        <= wait_dbg_done_st;
                when dbg_set_value_st =>
                    sv_dbg_ctrl_set_val <= stav_dbg_command(4) & stav_dbg_command(3) & stav_dbg_command(2) & stav_dbg_command(1);
                    --- No need to wait in dbg_done_st as this command sets the internal register of the controller ---
                    sv_dbg_tx_data      <= X"0000" & stav_dbg_command(0) & cv_host_noerr;
                    st_dbg_fsm          <= debug_response_st;
                when dbg_log_pc_ret_st | dbg_step_st | dbg_exit_step_st =>
                    sl_dbg_ctrl_en <= cl_ENABLE;
                    st_dbg_fsm     <= wait_dbg_done_st;
                when dbg_resume_st =>
                    sl_dbg_ctrl_en <= cl_ENABLE;
                    st_dbg_fsm     <= wait_dbg_done_st;

                    if (sl_is_in_step or sv_is_in_trig(1) or sv_is_in_trig(0)) = cl_ENABLE then
                        --- if core is in step or trigger match mode then the debugger will return only on halt ---
                        stav_dbg_command(0) <= cv_dbg_next_hlt;  
                    else
                        sl_en_parsing       <= cl_DISABLE;
                        sl_already_in_debug <= cl_DISABLE;
                    end if;
                when dbg_enter_st     =>
                    if sl_already_in_debug = cl_DISABLE then
                        sl_already_in_debug <= cl_ENABLE;
                        sl_dbg_ctrl_en      <= cl_ENABLE;
                        --- configure the debug time out timer ---
                        sl_debug_tot_en     <= stav_dbg_command(5)(0); -- timer enable or disable
                        sv_debug_tot_reg    <= stav_dbg_command(4) & stav_dbg_command(3) & stav_dbg_command(2) & stav_dbg_command(1);
                        st_dbg_fsm          <= wait_dbg_done_st;
                    else
                        --- Do not execute the enter cmd if the core is already in debug mode ---
                        sv_dbg_tx_data      <= X"0000" & stav_dbg_command(0) & cv_host_dbg_comm_err;
                        st_dbg_fsm          <= debug_response_st;
                    end if;
                when dbg_cfg_trig0_st =>
                    sl_dbg_ctrl_en      <= cl_ENABLE;
                    stav_dbg_command(0) <= cv_dbg_tselect;
                    sv_dbg_ctrl_rdata   <= cv_DBG_TSELECT_TRIG0;
                    st_dbg_fsm          <= wait_on_tselect_st;
                when dbg_cfg_trig1_st =>
                    sl_dbg_ctrl_en      <= cl_ENABLE;
                    stav_dbg_command(0) <= cv_dbg_tselect;
                    sv_dbg_ctrl_rdata   <= cv_DBG_TSELECT_TRIG1;
                    st_dbg_fsm          <= wait_on_tselect_st;
                when wait_on_tselect_st =>
                    if sl_dbg_ctrl_done = cl_ENABLE then
                        sl_dbg_ctrl_en <= cl_DISABLE;
                        st_dbg_fsm     <= dbg_set_tdata1_st;
                    end if;
                when dbg_set_tdata1_st =>
                    sl_dbg_ctrl_en      <= cl_ENABLE;
                    stav_dbg_command(0) <= cv_dbg_tdata1;
                    --- TDATA1.execute_enable  : X"0000_0004" ---
                    --- TDATA1.execute_disable : X"0000_0000" ---
                    sv_dbg_ctrl_rdata   <= (2 => stav_dbg_command(5)(0), others => '0');
                    st_dbg_fsm          <= wait_on_tdata1_st;
                when wait_on_tdata1_st =>
                    if sl_dbg_ctrl_done = cl_ENABLE then
                        sl_dbg_ctrl_en  <= cl_DISABLE;
                        st_dbg_fsm      <= dbg_set_tdata2_st;
                    end if;
                when dbg_set_tdata2_st =>
                    sl_dbg_ctrl_en      <= cl_ENABLE;
                    stav_dbg_command(0) <= cv_dbg_tdata2;
                    --- trigger address aligned for compressed instruction ---
                    sv_dbg_ctrl_rdata   <= stav_dbg_command(4) & stav_dbg_command(3) & stav_dbg_command(2) & stav_dbg_command(1)(7 downto 1) & '0';
                    st_dbg_fsm          <= wait_dbg_done_st;
                when wait_dbg_done_st =>
                    sl_debug_tot_start  <= cl_ENABLE;

                    if sl_debug_tot_flag = cl_ENABLE then
                        --- if the debugger has failed to respond then disable it and raise tot error ---
                        sl_debug_tot_start  <= cl_DISABLE;
                        sl_dbg_ctrl_en      <= cl_DISABLE;
                        sl_debug_log_pc_ret <= cl_DISABLE;
                        sl_already_in_debug <= cl_DISABLE; -- TOT was set so the core has not halted yet i.e. not in debug mode
                        sv_dbg_tx_data      <= X"0000" & stav_dbg_command(0) & cv_host_dbg_tot_err;
                        st_dbg_fsm          <= debug_response_st;
                    else
                        if sl_dbg_ctrl_done = cl_ENABLE then
                            sl_dbg_ctrl_en <= cl_DISABLE;

                            if (sl_debug_log_mem or sl_debug_log_reg or sl_debug_log_pc_ret) = cl_ENABLE then
                                sl_debug_log_pc_ret <= cl_DISABLE;
                                sv_dbg_tx_data      <= sv_dbg_ctrl_wdata;
                            else
                                if sl_dbg_ctrl_err = cl_ENABLE then
                                    sv_dbg_tx_data <= X"0000" & stav_dbg_command(0) & cv_host_dbg_acc_err;
                                else
                                    sv_dbg_tx_data <= X"0000" & stav_dbg_command(0) & cv_host_noerr;
                                end if;
                            end if;

                            st_dbg_fsm <= debug_response_st;
                        end if;
                    end if;
                when debug_response_st =>
                    sl_dbg_tx_en   <= cl_ENABLE;

                    if pil_dbg_next_data = cl_ENABLE then
						if si_resp_byte_ct < 3 then
							si_resp_byte_ct <= si_resp_byte_ct + 1;
						else
							si_resp_byte_ct <= 0;
                            sl_dbg_tx_en    <= cl_DISABLE;

                            if sl_debug_log_reg = cl_ENABLE then
                                st_dbg_fsm <= dbg_log_reg_st;
                            elsif sl_debug_log_mem = cl_ENABLE then
                                st_dbg_fsm <= dbg_log_mem_st;
                            else
                                st_dbg_fsm <= debug_rec_command_st;
                            end if;
                        end if;
                    end if;
            end case;
        end if;
    end process proc_dbg;

    sl_counter_on       <= sl_debug_tot_en and sl_debug_tot_start;
    sv_counter_prescale <= sv_debug_tot_reg(31 downto 16);
    sv_counter_match    <= sv_debug_tot_reg(15 downto 0);

    inst_debug_tot : entity work.counter
        generic map(
            gi_counter_width => 16,
            gi_clksrc_div    => 1
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            piv_counter_control     => cl_ENABLE & sl_counter_on,
            piv_counter_prescale    => sv_counter_prescale,
            piv_counter_match_value => sv_counter_match,
            pov_counter_value       => open,
            pol_counter_match_flag  => sl_debug_tot_flag
        );

	-----------------------------------------------------------------------------------------------------
	-----------------------------------------DEBUGGER MODULE---------------------------------------------
	-----------------------------------------------------------------------------------------------------

    sv_dbg_ctrl_command <= stav_dbg_command(0);

    inst_debugger : entity work.debugger
        port map (
            pil_clk              => pil_clk,
            pil_rst              => pil_rst,
            pil_dbg_ctrl_en      => sl_dbg_ctrl_en,
            piv_dbg_ctrl_command => sv_dbg_ctrl_command,
            piv_dbg_ctrl_rdata   => sv_dbg_ctrl_rdata,
            pov_dbg_ctrl_wdata   => sv_dbg_ctrl_wdata,
            pol_dbg_ctrl_done    => sl_dbg_ctrl_done,
            pol_dbg_ctrl_err     => sl_dbg_ctrl_err,
            piv_dbg_ctrl_set_val => sv_dbg_ctrl_set_val,
            pol_dbg_mem_access   => sl_dbg_mem_access,
            pov_dbg_mem_addr     => sv_dbg_mem_addr,
            pol_dbg_mem_write    => sl_dbg_mem_write,
            pov_dbg_mem_wdata    => sv_dbg_mem_wdata,
            piv_dbg_mem_rdata    => piv_dbg_mem_rdata,
            pol_debug_haltreq    => sl_debug_haltreq,
            pol_debug_resumereq  => sl_debug_resumereq,
            pil_debug_halted     => pil_debug_halted,
            piv_debug_pc_retired => piv_debug_pc_retired,
            pol_debug_regreq     => sl_debug_regreq,
            pov_debug_regno      => sv_debug_regno,
            pol_debug_write      => sl_debug_write,
            pov_debug_wdata      => sv_debug_wdata,
            piv_debug_rdata      => piv_debug_rdata,
            pil_debug_ack        => pil_debug_ack,
            pil_debug_err        => pil_debug_err
        );
    
    --- Debugger to Core/Memory interface --- 
    pol_dbg_mem_access   <= sl_dbg_mem_access;
    pov_dbg_mem_addr     <= sv_dbg_mem_addr;
    pol_dbg_mem_write    <= sl_dbg_mem_write;
    pov_dbg_mem_wdata    <= sv_dbg_mem_wdata;
    pol_debug_haltreq    <= sl_debug_haltreq;
    pol_debug_resumereq  <= sl_debug_resumereq;
    pol_debug_regreq     <= sl_debug_regreq;
    pov_debug_regno      <= sv_debug_regno;
    pol_debug_write      <= sl_debug_write;
    pov_debug_wdata      <= sv_debug_wdata;

    --- Debugger to Host_if ---
    pol_dbg_done      <= sl_dbg_done;
    pol_dbg_tx_en     <= sl_dbg_tx_en;
    pov_dbg_tx_data   <= sv_dbg_tx_data(8*si_resp_byte_ct + 7 downto 8*si_resp_byte_ct);
    pol_dbg_next_data <= sl_dbg_rec_data;

end architecture;