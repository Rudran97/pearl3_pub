library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

package pearl3_soc_pkg is

	--- Programmer commands ---
	constant cv_prg_FLASH          : std_logic_vector(7 downto 0) := X"AA";
	constant cv_prg_FLASH_HLT      : std_logic_vector(7 downto 0) := X"AD";

	--- Host debugger commands ---
	constant cv_dbg_log_REG        : std_logic_vector(7 downto 0) := X"DA";
	constant cv_dbg_log_MEM        : std_logic_vector(7 downto 0) := X"DB";
	constant cv_dbg_log_pc_retired : std_logic_vector(7 downto 0) := X"D6";
	constant cv_dbg_step           : std_logic_vector(7 downto 0) := X"DC";
	constant cv_dbg_resume         : std_logic_vector(7 downto 0) := X"DD";
	constant cv_dbg_enter          : std_logic_vector(7 downto 0) := X"DE";
	constant cv_dbg_exit_step      : std_logic_vector(7 downto 0) := X"DF";
	constant cv_dbg_cfg_TRIG0      : std_logic_vector(7 downto 0) := X"D0";
	constant cv_dbg_cfg_TRIG1      : std_logic_vector(7 downto 0) := X"D1";

	--- Debugger internal commands ---
	constant cv_dbg_next_hlt       : std_logic_vector(7 downto 0) := X"D5";
	constant cv_dbg_tselect        : std_logic_vector(7 downto 0) := X"D7";
	constant cv_dbg_tdata1         : std_logic_vector(7 downto 0) := X"D8";
	constant cv_dbg_tdata2         : std_logic_vector(7 downto 0) := X"D9";

	--- Reply to host ---
	constant cv_host_noerr         : std_logic_vector(7 downto 0) := X"00";
	constant cv_host_dbg_tot_err   : std_logic_vector(7 downto 0) := X"AF";
	constant cv_host_dbg_comm_err  : std_logic_vector(7 downto 0) := X"02";
	constant cv_host_dbg_acc_err   : std_logic_vector(7 downto 0) := X"03";

	--- Debug commands to core ---
	constant cv_DBG_DCSR_step      : std_logic_vector(31 downto 0) := X"0000_0004";
	constant cv_DBG_DCSR_exit_step : std_logic_vector(31 downto 0) := X"0000_0000";
	constant cv_DBG_TDATA1_ex_EN   : std_logic_vector(31 downto 0) := X"0000_0004";
	constant cv_DBG_TDATA1_ex_nEN  : std_logic_vector(31 downto 0) := X"0000_0000";
	constant cv_DBG_TSELECT_TRIG0  : std_logic_vector(31 downto 0) := X"0000_0000";
	constant cv_DBG_TSELECT_TRIG1  : std_logic_vector(31 downto 0) := X"0000_0001";

	-----------------------------------------------------------------------------------------------------
	-----------------------------General Constants / Types / Functions-----------------------------------
	-----------------------------------------------------------------------------------------------------

	constant cl_START_BIT    : std_logic := '0';
	constant ci_CLK_HZ       : integer   := 64_000_000;
    constant cl_GPIO_OUT     : std_logic := cl_DISABLE;
    constant cl_GPIO_IN      : std_logic := cl_ENABLE;
	constant cl_SOC_RESET    : std_logic := cl_DISABLE;
	constant cl_SOC_NOTRESET : std_logic := cl_ENABLE;

end package;

package body pearl3_soc_pkg is
end package body;