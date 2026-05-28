library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.pearl3_soc_pkg.all;
use work.csr_op_unit_pkg.all;

entity tb_debugger is
end entity tb_debugger;

architecture tb of tb_debugger is

	signal pil_clk              : std_logic                      := '1';
    signal pil_rst              : std_logic                      := cl_RESET;

    signal pil_dbg_ctrl_en      : std_logic                     := cl_DISABLE;
    signal piv_dbg_ctrl_command : std_logic_vector(7 downto 0)  := (others => '0');
    signal piv_dbg_ctrl_rdata   : std_logic_vector(31 downto 0) := (others => '0');
    signal pov_dbg_ctrl_wdata   : std_logic_vector(31 downto 0);
    signal pol_dbg_ctrl_done    : std_logic;
    signal pol_dbg_ctrl_err     : std_logic;

    signal pol_dbg_mem_access   : std_logic;
    signal pov_dbg_mem_addr     : std_logic_vector(31 downto 0);
    signal piv_dbg_mem_rdata    : std_logic_vector(31 downto 0) := (others => '0');

    signal pol_debug_haltreq    : std_logic;
    signal pol_debug_resumereq  : std_logic;
    signal pil_debug_halted     : std_logic                     := cl_DISABLE;

    signal pol_debug_regreq     : std_logic;
    signal pov_debug_regno      : std_logic_vector(11 downto 0);
    signal pol_debug_write      : std_logic;
    signal pov_debug_wdata      : std_logic_vector(31 downto 0);
    signal piv_debug_rdata      : std_logic_vector(31 downto 0) := (others => '0');
    signal pil_debug_ack        : std_logic                     := cl_DISABLE;
    signal pil_debug_err        : std_logic                     := cl_DISABLE;

	constant ct_clk_period     : time                           := 8.333333333333333 ns;

begin

    dut_debugger : entity work.debugger
        port map (
            pil_clk              => pil_clk,
            pil_rst              => pil_rst,
                                   
            pil_dbg_ctrl_en      => pil_dbg_ctrl_en,
            piv_dbg_ctrl_command => piv_dbg_ctrl_command,
            piv_dbg_ctrl_rdata   => piv_dbg_ctrl_rdata,
            pov_dbg_ctrl_wdata   => pov_dbg_ctrl_wdata,
            pol_dbg_ctrl_done    => pol_dbg_ctrl_done,
            pol_dbg_ctrl_err     => pol_dbg_ctrl_err,
                                   
            pol_dbg_mem_access   => pol_dbg_mem_access,
            pov_dbg_mem_addr     => pov_dbg_mem_addr,
            piv_dbg_mem_rdata    => piv_dbg_mem_rdata,
                                   
            pol_debug_haltreq    => pol_debug_haltreq,
            pol_debug_resumereq  => pol_debug_resumereq,
            pil_debug_halted     => pil_debug_halted,
                                   
            pol_debug_regreq     => pol_debug_regreq,
            pov_debug_regno      => pov_debug_regno,
            pol_debug_write      => pol_debug_write,
            pov_debug_wdata      => pov_debug_wdata,
            piv_debug_rdata      => piv_debug_rdata,
            pil_debug_ack        => pil_debug_ack,
            pil_debug_err        => pil_debug_err
        );

	pil_clk     <= not pil_clk after ct_clk_period / 2;
	pil_rst     <= cl_NOTRESET after ct_clk_period;

    proc_stimuli : process
    begin
        wait for 10 * ct_clk_period;

        ------------------------------
        --- Debug Enter Test       ---
        --- controller to debugger ---
        pil_dbg_ctrl_en      <= cl_ENABLE;
        piv_dbg_ctrl_command <= cv_dbg_enter;
        wait for 10 * ct_clk_period;
        assert pol_debug_haltreq = cl_ENABLE report "Test FAILED : Expecting haltreq from debugger" severity failure;

        --- core to debugger ---
        pil_debug_halted <= cl_ENABLE;
        wait until pol_dbg_ctrl_done = cl_ENABLE;

        --- controller to debugger ---
        wait for ct_clk_period;
        pil_dbg_ctrl_en      <= cl_DISABLE;
        wait for ct_clk_period;
        ------------------------------


        ------------------------------
        --- Debug enable Step Test ---
        --- controller to debugger ---
        pil_dbg_ctrl_en      <= cl_ENABLE;
        piv_dbg_ctrl_command <= cv_dbg_step;
        wait for 10 * ct_clk_period;
        assert pol_debug_regreq = cl_ENABLE report "Test FAILED : Expecting regreq = 1" severity failure;
        assert pol_debug_write  = cl_ENABLE report "Test FAILED : Expecting regwrite = 1 " severity failure;
        assert pov_debug_regno  = cv_ADDR_DCSR report "Test FAILED : Expecting regno = DCSR " severity failure;
        assert pov_debug_wdata  = cv_DBG_DCSR_step report "Test FAILED : Expecting DCSR.step = 1 " severity failure;

        --- core to debugger ---
        pil_debug_ack        <= cl_ENABLE;
        wait until pol_dbg_ctrl_done = cl_ENABLE;
        assert pol_debug_regreq = cl_DISABLE report "Test FAILED : Expecting regreq = 0" severity failure;
        assert pol_debug_write  = cl_DISABLE report "Test FAILED : Expecting regwrite = 0 " severity failure;

        --- controller to debugger ---
        wait for ct_clk_period;
        pil_dbg_ctrl_en      <= cl_DISABLE;
        wait for ct_clk_period;
        ------------------------------

        wait for 10 * ct_clk_period;
        assert false report "*** Test PASSED ***" severity failure;
    end process;

end architecture;