library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.csr_op_unit_pkg.all;
use work.pearl3_soc_pkg.all;

entity debugger is
    port (
        pil_clk              : in std_logic;
        pil_rst              : in std_logic;

        --- controller/debugger interface ---
        pil_dbg_ctrl_en      : in std_logic;
        piv_dbg_ctrl_command : in std_logic_vector(7 downto 0);
        piv_dbg_ctrl_rdata   : in std_logic_vector(31 downto 0);
        pov_dbg_ctrl_wdata   : out std_logic_vector(31 downto 0);
        pol_dbg_ctrl_done    : out std_logic;
        pol_dbg_ctrl_err     : out std_logic;

        piv_dbg_ctrl_set_val : in std_logic_vector(31 downto 0);

        --- debugger to Memory interface ---
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
end entity debugger;

architecture rtl of debugger is

    type t_dbg_fsm is (
        idle_st,
        dbg_halted_delay_st,
        dbg_halted_st,
        dbg_wait_ack_st,
        dbg_done_st,
        wait_st
    );
    signal st_dbg_fsm : t_dbg_fsm;

    signal sl_dbg_done        : std_logic;
    signal sv_dbg_ctrl_wdata  : std_logic_vector(31 downto 0);
    signal sl_dbg_mem_req     : std_logic;
    signal sv_dbg_mem_addr    : std_logic_vector(31 downto 0);
    signal sl_dbg_mem_write   : std_logic;
    signal sv_dbg_mem_wdata   : std_logic_vector(31 downto 0);

    signal sl_debug_haltreq   : std_logic;
    signal sl_debug_resumereq : std_logic;

    signal sl_debug_regreq    : std_logic;
    signal sv_debug_regno     : std_logic_vector(11 downto 0);
    signal sl_debug_write     : std_logic;
    signal sv_debug_wdata     : std_logic_vector(31 downto 0);

begin

    proc_debugger : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sl_debug_haltreq   <= cl_DISABLE;
            sl_debug_resumereq <= cl_DISABLE;
            sl_debug_regreq    <= cl_DISABLE;
            sv_debug_regno     <= (others => '0');
            sl_debug_write     <= cl_DISABLE;
            sv_debug_wdata     <= (others => '0');
            sl_dbg_done        <= cl_DISABLE;
            sv_dbg_ctrl_wdata  <= (others => '0');
            sl_dbg_mem_req     <= cl_DISABLE;
            sv_dbg_mem_addr    <= (others => '0');
            sl_dbg_mem_write   <= cl_DISABLE;
            sv_dbg_mem_wdata   <= (others => '0');
            st_dbg_fsm         <= idle_st;
        elsif rising_edge(pil_clk) then
            case st_dbg_fsm is
                when idle_st             =>
                    sl_debug_haltreq         <= cl_DISABLE;
                    sl_debug_resumereq       <= cl_DISABLE;
                    sl_debug_regreq          <= cl_DISABLE;
                    sl_dbg_done              <= cl_DISABLE;
                    sl_dbg_mem_req           <= cl_DISABLE;

                    if pil_dbg_ctrl_en = cl_ENABLE then
                        case piv_dbg_ctrl_command is
                            when cv_dbg_log_REG    =>
                                sl_debug_regreq  <= cl_ENABLE;
                                sv_debug_regno   <= piv_dbg_ctrl_rdata(11 downto 0);
                                st_dbg_fsm       <= dbg_wait_ack_st;
                            when cv_dbg_set_REG    =>
                                sl_debug_regreq  <= cl_ENABLE;
                                sv_debug_regno   <= piv_dbg_ctrl_rdata(11 downto 0);
                                sl_debug_write   <= cl_ENABLE;
                                sv_debug_wdata   <= piv_dbg_ctrl_set_val;
                                st_dbg_fsm       <= dbg_wait_ack_st;
                            when cv_dbg_log_MEM    =>
                                sl_dbg_mem_req   <= cl_ENABLE;
                                sv_dbg_mem_addr  <= piv_dbg_ctrl_rdata;
                                st_dbg_fsm       <= dbg_wait_ack_st;
                            when cv_dbg_set_MEM    =>
                                sl_dbg_mem_req   <= cl_ENABLE;
                                sv_dbg_mem_addr  <= piv_dbg_ctrl_rdata;
                                sl_dbg_mem_write <= cl_ENABLE;
                                sv_dbg_mem_wdata <= piv_dbg_ctrl_set_val;
                                st_dbg_fsm       <= dbg_wait_ack_st;
                            when cv_dbg_log_pc_retired =>
                                st_dbg_fsm       <= dbg_done_st;
                            when cv_dbg_step       =>
                                sl_debug_regreq  <= cl_ENABLE;
                                sv_debug_regno   <= cv_ADDR_DCSR;
                                sl_debug_write   <= cl_ENABLE;
                                sv_debug_wdata   <= cv_DBG_DCSR_step;
                                st_dbg_fsm       <= dbg_wait_ack_st;
                            when cv_dbg_resume     =>
                                sl_debug_resumereq <= cl_ENABLE;
                                st_dbg_fsm         <= dbg_done_st;
                            when cv_dbg_next_hlt   =>
                                sl_debug_resumereq <= cl_ENABLE;
                                st_dbg_fsm         <= dbg_halted_delay_st;
                            when cv_dbg_enter      =>
                                sl_debug_haltreq <= cl_ENABLE;
                                st_dbg_fsm       <= dbg_halted_delay_st;
                            when cv_dbg_exit_step  =>
                                sl_debug_regreq  <= cl_ENABLE;
                                sv_debug_regno   <= cv_ADDR_DCSR;
                                sl_debug_write   <= cl_ENABLE;
                                sv_debug_wdata   <= cv_DBG_DCSR_exit_step;
                                st_dbg_fsm       <= dbg_wait_ack_st;
                            when cv_dbg_tselect    =>
                                sl_debug_regreq  <= cl_ENABLE;
                                sv_debug_regno   <= cv_ADDR_TSELECT;
                                sl_debug_write   <= cl_ENABLE;
                                sv_debug_wdata   <= piv_dbg_ctrl_rdata;
                                st_dbg_fsm       <= dbg_wait_ack_st;
                            when cv_dbg_tdata1     =>
                                sl_debug_regreq  <= cl_ENABLE;
                                sv_debug_regno   <= cv_ADDR_TDATA1;
                                sl_debug_write   <= cl_ENABLE;
                                sv_debug_wdata   <= piv_dbg_ctrl_rdata;
                                st_dbg_fsm       <= dbg_wait_ack_st;
                            when cv_dbg_tdata2     =>
                                sl_debug_regreq  <= cl_ENABLE;
                                sv_debug_regno   <= cv_ADDR_TDATA2;
                                sl_debug_write   <= cl_ENABLE;
                                sv_debug_wdata   <= piv_dbg_ctrl_rdata;
                                st_dbg_fsm       <= dbg_wait_ack_st;
                            when others            =>
                        end case;
                    end if;
                when dbg_halted_delay_st  =>
                    sl_debug_resumereq   <= cl_DISABLE;
                    st_dbg_fsm           <= dbg_halted_st;
                when dbg_halted_st        =>
                    if pil_debug_halted = cl_ENABLE or pil_dbg_ctrl_en = cl_DISABLE then
                        sl_debug_resumereq   <= cl_DISABLE;
                        sl_debug_haltreq     <= cl_DISABLE;
                        st_dbg_fsm           <= dbg_done_st;
                    end if;
                when dbg_wait_ack_st     =>
                    if pil_dbg_ctrl_en = cl_ENABLE then
                        if piv_dbg_ctrl_command = cv_dbg_log_MEM or piv_dbg_ctrl_command = cv_dbg_set_MEM then
                            sl_dbg_mem_req           <= cl_DISABLE;
                            sl_dbg_mem_write         <= cl_DISABLE;
                            st_dbg_fsm               <= dbg_done_st;
                        else
                            if pil_debug_ack = cl_ENABLE then
                                sl_debug_regreq      <= cl_DISABLE;
                                sl_debug_write       <= cl_DISABLE;
                                st_dbg_fsm           <= dbg_done_st;
                            end if;
                        end if;
                    else
                        sl_debug_regreq      <= cl_DISABLE;
                        sl_debug_write       <= cl_DISABLE;
                        st_dbg_fsm           <= dbg_done_st;
                    end if;
                when dbg_done_st         =>
                    sl_debug_resumereq       <= cl_DISABLE;
                    sl_dbg_done              <= cl_ENABLE;
                    sl_dbg_mem_req           <= cl_DISABLE;
                    st_dbg_fsm               <= wait_st;

                    if piv_dbg_ctrl_command = cv_dbg_log_REG then
                        sv_dbg_ctrl_wdata    <= piv_debug_rdata;
                    elsif piv_dbg_ctrl_command = cv_dbg_log_pc_retired then
                        sv_dbg_ctrl_wdata    <= piv_debug_pc_retired;
                    else
                        sv_dbg_ctrl_wdata    <= piv_dbg_mem_rdata;
                    end if;
                when wait_st             =>
                    if pil_dbg_ctrl_en = cl_DISABLE then
                        sl_dbg_done          <= cl_DISABLE;
                        st_dbg_fsm           <= idle_st;
                    end if;
            end case;
        end if;
    end process proc_debugger;

    pov_dbg_ctrl_wdata  <= sv_dbg_ctrl_wdata;
    pol_dbg_ctrl_done   <= sl_dbg_done;

    pol_dbg_mem_access  <= sl_dbg_mem_req;
    pov_dbg_mem_addr    <= sv_dbg_mem_addr;
    pol_dbg_mem_write   <= sl_dbg_mem_write;
    pov_dbg_mem_wdata   <= sv_dbg_mem_wdata;

    pol_debug_haltreq   <= sl_debug_haltreq;
    pol_debug_resumereq <= sl_debug_resumereq;
    
    pol_debug_regreq    <= sl_debug_regreq;
    pov_debug_regno     <= sv_debug_regno;
    pol_debug_write     <= sl_debug_write;
    pov_debug_wdata     <= sv_debug_wdata;
    pol_dbg_ctrl_err    <= pil_debug_err;

end architecture;