library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pearl3_soc_pkg.all;
use work.core_pkg.all;
use work.options_soc_pkg.all;
use work.options_pkg.all;

entity pearl3_top is
    port (
        pil_Mclk      : in std_logic;
        pil_nrst      : in std_logic;
        pil_DI        : in std_logic;
        pol_DO        : out std_logic;
        piv_PORTA     : in std_logic_vector(15 downto 0);
        piv_PORTB     : in std_logic_vector(15 downto 0);
        pov_DDRA      : out std_logic_vector(15 downto 0);
        pov_DDRB      : out std_logic_vector(15 downto 0);
        pov_LATA      : out std_logic_vector(15 downto 0);
        pov_LATB      : out std_logic_vector(15 downto 0);
        pov_LATD      : out std_logic_vector(15 downto 0)
    );
end entity pearl3_top;

architecture rtl of pearl3_top is

    constant ci_PMEM_ORIGIN_BIT     : integer                        := fi_get_leading_one(v_value => cv_PMEM_ORIGIN);
    constant ci_CLIC_ORIGIN_BIT     : integer                        := fi_get_leading_one(v_value => cv_CLIC_ORIGIN);
    constant ci_IO_ORIGIN_BIT       : integer                        := fi_get_leading_one(v_value => cv_IO_ORIGIN);
    constant ci_SRAM_ORIGIN_BIT     : integer                        := fi_get_leading_one(v_value => cv_SRAM_ORIGIN);

    function fs_device_ID return string is
        variable vs_device_ID : string(1 to 13) := "PRVX3XXXMMSS.";
    begin
        if cb_RV32_E = true then
            report "Embedded support added" severity warning;
            vs_device_ID(6) := 'E';
        else
            vs_device_ID(6) := 'I';
        end if;

        if cb_EXT_M = true then
            report "M Extension support added" severity warning;
            vs_device_ID(7) := 'M';
        end if;

        if cb_EXT_C = true then
            report "C Extension support added" severity warning;
            vs_device_ID(8) := 'C';
        end if;

        vs_device_ID(9 to 10) := integer'image(to_integer(unsigned(cv_PMEM_NUM_WORDS(15 downto 8))));

        if cb_MULTI_CYCLE_FETCH = true then
            report "Multi-cycle fetch" severity warning;
            vs_device_ID(11) := 'M';
        else
            report "Single-cycle fetch" severity warning;
            vs_device_ID(11) := 'S';
        end if;

        if cb_GPR_HW_BACKUP = true then
            report "Hardware backup register support added" severity warning;
            vs_device_ID(12) := 'H';
        end if;

        return vs_device_ID;
    end function;

    signal sl_global_rst            : std_logic;
    signal sl_module_sync_rst       : std_logic;

    --- pll ip module ---
    signal sl_clk_c0                : std_logic;
    signal sl_locked                : std_logic;

    --- programmer module ---
    signal sl_prg_rst               : std_logic;
    signal sl_prg_reset_out         : std_logic;
    signal sl_prg_core_start        : std_logic;
    signal sv_hif_state             : std_logic_vector(7 downto 0);
                              
    signal sl_prg_mem_req           : std_logic;
    signal sl_prg_mem_wen           : std_logic;
    signal sv_prg_mem_addr          : std_logic_vector(31 downto 0);
    signal sv_prg_mem_wdata         : std_logic_vector(31 downto 0);

    signal sl_dbg_mem_access        : std_logic;
    signal sv_dbg_mem_addr          : std_logic_vector(31 downto 0);
    signal sl_dbg_mem_write         : std_logic;
    signal sv_dbg_mem_wdata         : std_logic_vector(31 downto 0);
    signal sv_dbg_mem_rdata         : std_logic_vector(31 downto 0);
    signal sl_debug_haltreq         : std_logic;
    signal sl_debug_resumereq       : std_logic;
    signal sl_debug_halted          : std_logic;
    signal sv_debug_pc_retired      : std_logic_vector(31 downto 0);
    signal sl_debug_regreq          : std_logic;
    signal sv_debug_regno           : std_logic_vector(11 downto 0);
    signal sl_debug_write           : std_logic;
    signal sv_debug_wdata           : std_logic_vector(31 downto 0);
    signal sv_debug_rdata           : std_logic_vector(31 downto 0);
    signal sl_debug_ack             : std_logic;
    signal sl_debug_err             : std_logic;

    signal sl_sync_prg_reset        : std_logic;
    signal sl_sync_rst              : std_logic;
    signal sl_sync_core_start       : std_logic;
    signal sl_sync_prg_run          : std_logic;

    --- pmem controller ---
    signal sl_pmem_wen              : std_logic;
    signal sv_pmem_addr             : std_logic_vector(31 downto 0);
    signal sv_pmem_wdata            : std_logic_vector(31 downto 0);
    signal sv_pmem_rdata            : std_logic_vector(31 downto 0);

    --- sram controller ---
	signal sl_sram_prg_req          : std_logic;
	signal sl_sram_req              : std_logic;
	signal sl_sram_wen              : std_logic;
	signal sl_sram_ack              : std_logic;
	signal sl_sram_valid            : std_logic;
	signal sv_sram_byte_sel         : std_logic_vector(3 downto 0);
	signal sv_sram_addr             : std_logic_vector(31 downto 0);
	signal sv_sram_wdata            : std_logic_vector(31 downto 0);
	signal sv_sram_rdata            : std_logic_vector(31 downto 0);

    --- sv32x core ---
	signal sl_run_prg               : std_logic;
	signal sl_fetch_mem_valid       : std_logic;
	signal sl_fetch_mem_ack         : std_logic;
	signal sl_fetch_mem_req         : std_logic;
	signal sv_fetch_mem_rdata       : std_logic_vector(31 downto 0);
	signal sv_fetch_mem_addr        : std_logic_vector(31 downto 0);
	signal sl_mem_valid             : std_logic;
	signal sl_mem_ack               : std_logic;
	signal sl_mem_req               : std_logic;
	signal sl_mem_wen               : std_logic;
	signal sv_mem_rdata             : std_logic_vector(31 downto 0);
	signal sv_mem_wdata             : std_logic_vector(31 downto 0);
	signal sv_mem_addr              : std_logic_vector(31 downto 0);
	signal sv_mem_byte_sel          : std_logic_vector(3 downto 0);
	signal sl_soft_irq              : std_logic;
	signal sl_timer_irq             : std_logic;
	signal sl_ext_irq               : std_logic;
	signal sl_fast_irq              : std_logic;
	signal sv_fast_irq_id           : std_logic_vector(3 downto 0);
	signal sv_fast_irq_vect         : std_logic_vector(31 downto 0);
	signal sl_irq_pending           : std_logic;
	signal sl_core_debug_haltreq    : std_logic;
	signal sl_core_debug_resumereq  : std_logic;
	signal sl_core_debug_havereset  : std_logic;
	signal sl_core_debug_running    : std_logic;
	signal sl_core_debug_halted     : std_logic;
    signal sv_core_debug_pc_retired : std_logic_vector(31 downto 0);
	signal sl_core_debug_regreq     : std_logic;
	signal sv_core_debug_regno      : std_logic_vector(11 downto 0);
	signal sl_core_debug_write      : std_logic;
	signal sv_core_debug_wdata      : std_logic_vector(31 downto 0);
	signal sv_core_debug_rdata      : std_logic_vector(31 downto 0);
	signal sl_core_debug_ack        : std_logic;
	signal sl_core_debug_err        : std_logic;

    --- clic module ---
    signal sv_clic_irq_src          : std_logic_vector(7 downto 0);
    signal sv_clic_irq_clr          : std_logic_vector(7 downto 0);
    signal sl_clic_wen              : std_logic;
    signal sv_clic_addr             : std_logic_vector(4 downto 0);
    signal sv_clic_wdata            : std_logic_vector(15 downto 0);
    signal sv_clic_rdata            : std_logic_vector(15 downto 0);
    signal sl_clic_irq_done         : std_logic;
    signal sl_clic_irq_fast_irq_pin : std_logic;
    signal sl_clic_irq_ei_irq_pin   : std_logic;
    signal sv_clic_irq_id           : std_logic_vector(3 downto 0);
    signal sv_clic_irq_vect         : std_logic_vector(31 downto 0);

    --- peripheral controller module ---
    signal sl_ioctrl_wen            : std_logic;
    signal sv_ioctrl_addr           : std_logic_vector(11 downto 0);
    signal sv_ioctrl_wdata          : std_logic_vector(31 downto 0);
    signal sv_ioctrl_rdata          : std_logic_vector(31 downto 0);
    signal sv_io_irq_src            : std_logic_vector(7 downto 0);
    signal sv_io_irq_clr            : std_logic_vector(7 downto 0);
    signal sv_sync_PORTA_1          : std_logic_vector(15 downto 0);
    signal sv_PORTA                 : std_logic_vector(15 downto 0);
    signal sv_sync_PORTB_1          : std_logic_vector(15 downto 0);
    signal sv_PORTB                 : std_logic_vector(15 downto 0);
    signal sv_DDRA                  : std_logic_vector(15 downto 0);
    signal sv_DDRB                  : std_logic_vector(15 downto 0);
    signal sv_LATA                  : std_logic_vector(15 downto 0);
    signal sv_LATB                  : std_logic_vector(15 downto 0);
    signal sv_LATD                  : std_logic_vector(15 downto 0);

begin

    assert false report "Device ID.Version - " & fs_device_ID & cs_BUILD_VER severity warning;
    assert false report "Program speed is set to " & integer'image(ci_PRG_SPEED) severity warning;

    sl_global_rst <= not pil_nrst;

    -----------------------------------------------------------------------------------------------------
    ------------------------------------------PLL IP MODULE----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    inst_pll : entity work.pll
        port map(
            inclk0	=> pil_Mclk,
            c0	    => sl_clk_c0,
            locked	=> sl_locked
        );

    -----------------------------------------------------------------------------------------------------
    -------------------------------------PROGRAMMER / SYNC RESET-----------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_prg_rst                <= sl_global_rst or not sl_locked;
    sl_debug_halted           <= sl_core_debug_halted;
    sv_debug_pc_retired       <= sv_core_debug_pc_retired;
    sv_debug_rdata            <= sv_core_debug_rdata;
    sl_debug_ack              <= sl_core_debug_ack;
    sl_debug_err              <= sl_core_debug_err;

    sv_dbg_mem_rdata          <= sv_pmem_rdata when sv_dbg_mem_addr(ci_PMEM_ORIGIN_BIT) = cl_ENABLE else
        X"0000" & sv_clic_rdata when sv_dbg_mem_addr(ci_CLIC_ORIGIN_BIT) = cl_ENABLE else
        sv_ioctrl_rdata when sv_dbg_mem_addr(ci_IO_ORIGIN_BIT) = cl_ENABLE else
        sv_sram_rdata;

    inst_host_if_wrapper : entity work.host_if_wrapper
        generic map (
            gi_baud_rate         => ci_PRG_SPEED,
            gs_device_id         => fs_device_ID & cs_BUILD_VER
        )
        port map (
            pil_clk              => sl_clk_c0,
            pil_rst              => sl_prg_rst,
            pil_DI               => pil_DI,
            pol_DO               => pol_DO,
            pol_reset            => sl_prg_reset_out,
            pol_core_start       => sl_prg_core_start,
            pov_hif_state        => sv_hif_state,

            pol_mem_req          => sl_prg_mem_req,
            pol_mem_wen          => sl_prg_mem_wen,
            pov_mem_addr         => sv_prg_mem_addr,
            pov_mem_wdata        => sv_prg_mem_wdata,
                                   
            pol_dbg_mem_access   => sl_dbg_mem_access,
            pov_dbg_mem_addr     => sv_dbg_mem_addr,
            pol_dbg_mem_write    => sl_dbg_mem_write,
            pov_dbg_mem_wdata    => sv_dbg_mem_wdata,
            piv_dbg_mem_rdata    => sv_dbg_mem_rdata,
                                   
            pol_debug_haltreq    => sl_debug_haltreq,
            pol_debug_resumereq  => sl_debug_resumereq,
            pil_debug_halted     => sl_debug_halted,
            piv_debug_pc_retired => sv_debug_pc_retired,
                                   
            pol_debug_regreq     => sl_debug_regreq,
            pov_debug_regno      => sv_debug_regno,
            pol_debug_write      => sl_debug_write,
            pov_debug_wdata      => sv_debug_wdata,
            piv_debug_rdata      => sv_debug_rdata,
            pil_debug_ack        => sl_debug_ack,
            pil_debug_err        => sl_debug_err
        );

    sl_sync_prg_reset  <= sl_prg_reset_out;
    sl_sync_core_start <= sl_prg_core_start;

    inst_sync_reset : entity work.sync_reset
        port map(
            pil_clk              => sl_clk_c0,
            pil_global_reset     => sl_global_rst,
            pil_prg_reset        => sl_sync_prg_reset,
            pil_prg_run_prog     => sl_sync_core_start,
            pol_reset            => sl_sync_rst,
            pol_run_prog         => sl_sync_prg_run
        );

    sl_module_sync_rst <= sl_sync_rst or not sl_locked;

    -----------------------------------------------------------------------------------------------------
    ----------------------------------------PMEM CONTROLLER----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_pmem_wen   <= sl_prg_mem_wen and sv_prg_mem_addr(ci_PMEM_ORIGIN_BIT) when sl_prg_mem_req = cl_ENABLE else
        sl_dbg_mem_write and sv_dbg_mem_addr(ci_PMEM_ORIGIN_BIT) when sl_dbg_mem_access = cl_ENABLE else
        cl_DISABLE;
    sv_pmem_addr  <= sv_prg_mem_addr and X"0000_FFFC" when sl_prg_mem_req = cl_ENABLE else
        sv_dbg_mem_addr and X"0000_FFFC" when sl_dbg_mem_access = cl_ENABLE else
        sv_fetch_mem_addr and X"0000_FFFF";
    sv_pmem_wdata <= sv_dbg_mem_wdata when sl_dbg_mem_access = cl_ENABLE else
        sv_prg_mem_wdata;

    inst_pmem_controller : entity work.pmem_controller
        generic map (
            gv_NUM_WORDS      => cv_PMEM_NUM_WORDS,
            gs_PMEM_INIT_FILE => cs_PMEM_INIT_FILE
        )
        port map (
            pil_clk           => sl_clk_c0,
            pil_rst           => sl_module_sync_rst,
            pil_pmem_wen      => sl_pmem_wen,
            piv_pmem_addr     => sv_pmem_addr,
            piv_pmem_wdata    => sv_pmem_wdata,
            pov_pmem_rdata    => sv_pmem_rdata
        );

    -----------------------------------------------------------------------------------------------------
    ----------------------------------------SRAM CONTROLLER----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_sram_prg_req  <= sv_prg_mem_addr(ci_SRAM_ORIGIN_BIT) when sl_prg_mem_req = cl_ENABLE else
        sv_dbg_mem_addr(ci_SRAM_ORIGIN_BIT) when sl_dbg_mem_access = cl_ENABLE else
        cl_DISABLE;
    sl_sram_req      <= cl_DISABLE when sl_prg_mem_req = cl_ENABLE or sl_dbg_mem_access = cl_ENABLE else
        sl_mem_req and sv_mem_addr(ci_SRAM_ORIGIN_BIT);
    sl_sram_wen      <= sl_prg_mem_wen and sv_prg_mem_addr(ci_SRAM_ORIGIN_BIT) when sl_prg_mem_req = cl_ENABLE else
        sl_dbg_mem_write and sv_dbg_mem_addr(ci_SRAM_ORIGIN_BIT) when sl_dbg_mem_access = cl_ENABLE else
        sl_mem_wen and sv_mem_addr(ci_SRAM_ORIGIN_BIT); 
    sv_sram_byte_sel <= "1111" when sl_prg_mem_req = cl_ENABLE or sl_dbg_mem_access = cl_ENABLE else
        sv_mem_byte_sel; 
    sv_sram_addr     <= sv_prg_mem_addr and X"0000_FFFC" when sl_prg_mem_req = cl_ENABLE else
        sv_dbg_mem_addr and X"0000_FFFC" when sl_dbg_mem_access = cl_ENABLE else
        sv_mem_addr and X"0000_FFFC";
    sv_sram_wdata    <= sv_prg_mem_wdata when sl_prg_mem_req = cl_ENABLE else
        sv_dbg_mem_wdata when sl_dbg_mem_access = cl_ENABLE else
        sv_mem_wdata;

    inst_mem_controller : entity work.mem_controller
        generic map (
            gv_NUM_BYTES      => cv_SRAM_NUM_BYTES,
            gs_SRAM_INIT_FILE => cs_SRAM_INIT_FILE
        )
        port map (
            pil_clk           => sl_clk_c0,
            pil_rst           => sl_module_sync_rst,
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
    ------------------------------------------SV32X CORE-------------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_run_prg              <= sl_sync_prg_run;
    sl_fetch_mem_valid      <= cl_ENABLE;
    sl_fetch_mem_ack        <= cl_ENABLE;
    sv_fetch_mem_rdata      <= sv_pmem_rdata;

    sl_mem_ack              <= sl_sram_ack when sv_mem_addr(ci_SRAM_ORIGIN_BIT) = cl_ENABLE else
        cl_ENABLE;
    sl_mem_valid            <= sl_sram_valid when sv_mem_addr(ci_SRAM_ORIGIN_BIT) = cl_ENABLE else
        cl_ENABLE;
    sv_mem_rdata            <= sv_sram_rdata when sv_mem_addr(ci_SRAM_ORIGIN_BIT) = cl_ENABLE else
        sv_ioctrl_rdata when sv_mem_addr(ci_IO_ORIGIN_BIT) = cl_ENABLE else
        X"0000" & sv_clic_rdata;

    sl_soft_irq             <= cl_DISABLE;
    sl_timer_irq            <= cl_DISABLE;
    sl_ext_irq              <= sl_clic_irq_ei_irq_pin;
    sl_fast_irq             <= sl_clic_irq_fast_irq_pin;
    sv_fast_irq_id          <= sv_clic_irq_id;
    sv_fast_irq_vect        <= sv_clic_irq_vect;

    sl_core_debug_haltreq   <= sl_debug_haltreq;
    sl_core_debug_resumereq <= sl_debug_resumereq;
    sl_core_debug_regreq    <= sl_debug_regreq;
    sv_core_debug_regno     <= sv_debug_regno;
    sl_core_debug_write     <= sl_debug_write;
    sv_core_debug_wdata     <= sv_debug_wdata;

	inst_svx32_core : entity work.svx32_core
		port map(
			pil_clk              => sl_clk_c0,
			pil_rst              => sl_module_sync_rst,
			pil_run_prg          => sl_run_prg,
			pil_fetch_mem_valid  => sl_fetch_mem_valid,
			pil_fetch_mem_ack    => sl_fetch_mem_ack,
			pol_fetch_mem_req    => sl_fetch_mem_req,
			piv_fetch_mem_rdata  => sv_fetch_mem_rdata,
			pov_fetch_mem_addr   => sv_fetch_mem_addr,
			pil_mem_valid        => sl_mem_valid,
			pil_mem_ack          => sl_mem_ack,
			pol_mem_req          => sl_mem_req,
			pol_mem_wen          => sl_mem_wen,
			piv_mem_rdata        => sv_mem_rdata,
			pov_mem_wdata        => sv_mem_wdata,
			pov_mem_addr         => sv_mem_addr,
			pov_mem_byte_sel     => sv_mem_byte_sel,
			pil_soft_irq         => sl_soft_irq,
			pil_timer_irq        => sl_timer_irq,
			pil_ext_irq          => sl_ext_irq,
			pil_fast_irq         => sl_fast_irq,
			piv_fast_irq_id      => sv_fast_irq_id,
			piv_fast_irq_vect    => sv_fast_irq_vect,
			pol_irq_pending      => sl_irq_pending,
			pil_debug_haltreq    => sl_core_debug_haltreq,
			pil_debug_resumereq  => sl_core_debug_resumereq,
			pol_debug_havereset  => sl_core_debug_havereset,
			pol_debug_running    => sl_core_debug_running,
			pol_debug_halted     => sl_core_debug_halted,
            pov_debug_pc_retired => sv_core_debug_pc_retired,
			pil_debug_regreq     => sl_core_debug_regreq,
			piv_debug_regno      => sv_core_debug_regno,
			pil_debug_write      => sl_core_debug_write,
			piv_debug_wdata      => sv_core_debug_wdata,
			pov_debug_rdata      => sv_core_debug_rdata,
			pol_debug_ack        => sl_core_debug_ack,
			pol_debug_err        => sl_core_debug_err
		);

    -----------------------------------------------------------------------------------------------------
    ---------------------------------------------CLIC MODULE---------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sv_clic_irq_src  <= sv_io_irq_src;
    sl_clic_wen      <= sl_dbg_mem_write and sv_dbg_mem_addr(ci_CLIC_ORIGIN_BIT) when sl_dbg_mem_access = cl_ENABLE else
        sl_mem_wen and sv_mem_addr(ci_CLIC_ORIGIN_BIT);
    sv_clic_addr     <= sv_dbg_mem_addr(6 downto 2) when sl_dbg_mem_access = cl_ENABLE else
        sv_mem_addr(6 downto 2);
    sv_clic_wdata    <= sv_dbg_mem_wdata(15 downto 0) when sl_dbg_mem_access = cl_ENABLE else
        sv_mem_wdata(15 downto 0);

    sl_clic_irq_done <= sl_irq_pending;

    inst_clic_top : entity work.clic_top
        generic map (
            gv_PREM_ORIGIN       => cv_PMEM_ORIGIN
        )
        port map (
            pil_clk              => sl_clk_c0,
            pil_rst              => sl_module_sync_rst,
            piv_irq_src          => sv_clic_irq_src,
            pov_irq_clr          => sv_clic_irq_clr,
            pil_clic_wen         => sl_clic_wen,
            piv_clic_addr        => sv_clic_addr,
            piv_clic_wdata       => sv_clic_wdata,
            pov_clic_rdata       => sv_clic_rdata,
            pil_irq_done         => sl_clic_irq_done,
            pol_irq_fast_irq_pin => sl_clic_irq_fast_irq_pin,
            pol_irq_ei_irq_pin   => sl_clic_irq_ei_irq_pin,
            pov_irq_id           => sv_clic_irq_id,
            pov_irq_vect         => sv_clic_irq_vect
    );

    -----------------------------------------------------------------------------------------------------
    ----------------------------------------PERIPHERAL CONTROLLER----------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_ioctrl_wen            <= sl_dbg_mem_write and sv_dbg_mem_addr(ci_IO_ORIGIN_BIT) when sl_dbg_mem_access = cl_ENABLE else
        sl_mem_wen and sv_mem_addr(ci_IO_ORIGIN_BIT);
    sv_ioctrl_addr           <= sv_dbg_mem_addr(13 downto 2) when sl_dbg_mem_access = cl_ENABLE else
        sv_mem_addr(13 downto 2);
    sv_ioctrl_wdata          <= sv_dbg_mem_wdata when sl_dbg_mem_access = cl_ENABLE else
        sv_mem_wdata;

    sv_io_irq_clr            <= sv_clic_irq_clr;

    proc_sync_ports : process (sl_clk_c0)
    begin
        if rising_edge(sl_clk_c0) then
            sv_sync_PORTA_1 <= piv_PORTA;
            sv_PORTA        <= sv_sync_PORTA_1;

            sv_sync_PORTB_1 <= piv_PORTB;
            sv_PORTB        <= sv_sync_PORTB_1;
        end if;
    end process proc_sync_ports;

    inst_peripheral_controller : entity work.peripheral_controller
        port map(
            pil_clk          => sl_clk_c0,
            pil_rst          => sl_module_sync_rst,
            pil_ioctrl_wen   => sl_ioctrl_wen,
            piv_ioctrl_addr  => sv_ioctrl_addr,
            piv_ioctrl_wdata => sv_ioctrl_wdata,
            pov_ioctrl_rdata => sv_ioctrl_rdata,
            pov_IRQ_src      => sv_io_irq_src,
            piv_IRQ_clr      => sv_io_irq_clr,
            piv_PORTA        => sv_PORTA,
            piv_PORTB        => sv_PORTB,
            pov_DDRA         => sv_DDRA,
            pov_DDRB         => sv_DDRB,
            pov_LATA         => sv_LATA,
            pov_LATB         => sv_LATB,
            pov_LATD         => sv_LATD
        );

    pov_DDRA <= sv_DDRA;
    pov_DDRB <= sv_DDRB;

    pov_LATA <= sv_LATA;
    pov_LATB <= sv_LATB;
    pov_LATD <= sv_LATD;

end architecture;