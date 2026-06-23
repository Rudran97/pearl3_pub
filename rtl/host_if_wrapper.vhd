library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.pearl3_soc_pkg.all;
use work.csr_op_unit_pkg.all;

entity host_if_wrapper is
	generic (
		gi_baud_rate : integer          := 115200;
		gs_device_id : string (1 to 17) := "PRV32XXXMMRR.XXXX"
	);
    port (
		pil_clk              : in std_logic;
		pil_rst              : in std_logic;
		pil_DI               : in std_logic;
		pol_DO               : out std_logic;
		pol_reset            : out std_logic;
		pol_core_start       : out std_logic;
        pov_hif_state        : out std_logic_vector(7 downto 0);

		--- programmer/memory interfece ---
		pol_mem_req          : out std_logic;
		pol_mem_wen          : out std_logic;
		pov_mem_addr         : out std_logic_vector(31 downto 0);
		pov_mem_wdata        : out std_logic_vector(31 downto 0);

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
end entity host_if_wrapper;

architecture rtl of host_if_wrapper is

    --- signals declared for host_if ---
    signal sl_host_isp_sel              : std_logic;
    signal sl_host_isp_done             : std_logic;
    signal sl_host_isp_flash_hlt        : std_logic;
    signal sl_host_isp_tx_next_data     : std_logic;
    signal sl_host_isp_tx_en            : std_logic;
    signal sv_host_isp_tx_data          : std_logic_vector(7 downto 0);
    signal sl_host_isp_rx_next_data     : std_logic;
    signal sl_host_isp_rx_valid         : std_logic;
    signal sv_host_isp_rx_data          : std_logic_vector(7 downto 0);
    signal sl_host_dbg_sel              : std_logic;
    signal sl_host_dbg_done             : std_logic;
    signal sl_host_dbg_tx_next_data     : std_logic;
    signal sl_host_dbg_tx_en            : std_logic;
    signal sv_host_dbg_tx_data          : std_logic_vector(7 downto 0);
    signal sl_host_dbg_rx_next_data     : std_logic;
    signal sl_host_dbg_rx_valid         : std_logic;
    signal sv_host_dbg_rx_data          : std_logic_vector(7 downto 0);

    --- signals declared for programmer ---
    signal sl_prg_sel                   : std_logic;
    signal sl_prg_done                  : std_logic;
    signal sl_prg_flash_hlt             : std_logic;
    signal sl_prg_host_tx_done          : std_logic;
    signal sl_prg_tx_en                 : std_logic;
    signal sv_prg_tx_data               : std_logic_vector(7 downto 0);
    signal sl_prg_req_next_data         : std_logic;
    signal sl_prg_rx_valid              : std_logic;
    signal sv_prg_rx_data               : std_logic_vector(7 downto 0);

    --- signals declared for debugger_ctrl ---
    signal sl_dbg_sel                   : std_logic;
    signal sl_dbg_done                  : std_logic;
    signal sl_dbg_host_tx_done          : std_logic;
    signal sl_dbg_tx_en                 : std_logic;
    signal sv_dbg_tx_data               : std_logic_vector(7 downto 0);
    signal sl_dbg_req_next_data         : std_logic;
    signal sl_dbg_rx_valid              : std_logic;
    signal sv_dbg_rx_data               : std_logic_vector(7 downto 0);

begin

	-----------------------------------------------------------------------------------------------------
	-------------------------------------------- HOST IF ------------------------------------------------
	-----------------------------------------------------------------------------------------------------

    sl_host_isp_done           <= sl_prg_done;
    sl_host_isp_tx_en          <= sl_prg_tx_en;
    sv_host_isp_tx_data        <= sv_prg_tx_data;
    sl_host_isp_rx_next_data   <= sl_prg_req_next_data;

    sl_host_dbg_done           <= sl_dbg_done;
    sl_host_dbg_tx_en          <= sl_dbg_tx_en;
    sv_host_dbg_tx_data        <= sv_dbg_tx_data;
    sl_host_dbg_rx_next_data   <= sl_dbg_req_next_data;


    inst_host_if : entity work.host_if
        generic map (
            gi_baud_rate => gi_baud_rate
        )
        port map (
            pil_clk           => pil_clk,
            pil_rst           => pil_rst,
            pil_DI            => pil_DI,
            pol_DO            => pol_DO,
            pov_hif_state     => pov_hif_state,
            pol_isp_sel       => sl_host_isp_sel,
            pil_isp_done      => sl_host_isp_done,
            pol_isp_flash_hlt => sl_host_isp_flash_hlt,
            pol_isp_next_data => sl_host_isp_tx_next_data,
            pil_isp_tx_en     => sl_host_isp_tx_en,
            piv_isp_tx_data   => sv_host_isp_tx_data,
            pil_isp_next_data => sl_host_isp_rx_next_data,
            pol_isp_rx_valid  => sl_host_isp_rx_valid,
            pov_isp_rx_data   => sv_host_isp_rx_data,
            pol_dbg_sel       => sl_host_dbg_sel,
            pil_dbg_done      => sl_host_dbg_done,
            pol_dbg_next_data => sl_host_dbg_tx_next_data,
            pil_dbg_tx_en     => sl_host_dbg_tx_en,
            piv_dbg_tx_data   => sv_host_dbg_tx_data,
            pil_dbg_next_data => sl_host_dbg_rx_next_data,
            pol_dbg_rx_valid  => sl_host_dbg_rx_valid,
            pov_dbg_rx_data   => sv_host_dbg_rx_data
        );

	-----------------------------------------------------------------------------------------------------
	------------------------------------------- PROGRAMMER ----------------------------------------------
	-----------------------------------------------------------------------------------------------------

    sl_prg_sel                 <= sl_host_isp_sel;
    sl_prg_flash_hlt           <= sl_host_isp_flash_hlt;
    sl_prg_host_tx_done        <= sl_host_isp_tx_next_data;
    sl_prg_rx_valid            <= sl_host_isp_rx_valid;
    sv_prg_rx_data             <= sv_host_isp_rx_data;

    inst_programmer : entity work.programmer
        generic map (
            gs_device_id         => gs_device_id
        )
        port map (
            pil_clk              => pil_clk,
            pil_rst              => pil_rst,
            pol_reset            => pol_reset,
            pol_core_start       => pol_core_start,
            pil_prg_sel          => sl_prg_sel,
            pol_prg_done         => sl_prg_done,
            pil_prg_flash_hlt    => sl_prg_flash_hlt,
            pil_prg_next_data    => sl_prg_host_tx_done,
            pol_prg_tx_en        => sl_prg_tx_en,
            pov_prg_tx_data      => sv_prg_tx_data,
            pol_prg_next_data    => sl_prg_req_next_data,
            pil_prg_rx_valid     => sl_prg_rx_valid,
            piv_prg_rx_data      => sv_prg_rx_data,
            pol_mem_req          => pol_mem_req,
            pol_mem_wen          => pol_mem_wen,
            pov_mem_addr         => pov_mem_addr,
            pov_mem_wdata        => pov_mem_wdata
        );

	-----------------------------------------------------------------------------------------------------
	------------------------------------------- DEBUG CTRL ----------------------------------------------
	-----------------------------------------------------------------------------------------------------

    sl_dbg_sel                 <= sl_host_dbg_sel;
    sl_dbg_host_tx_done        <= sl_host_dbg_tx_next_data;
    sl_dbg_rx_valid            <= sl_host_dbg_rx_valid;
    sv_dbg_rx_data             <= sv_host_dbg_rx_data;

    inst_debug_ctrl : entity work.debugger_ctrl
        port map (
            pil_clk               => pil_clk,
            pil_rst               => pil_rst,
            pil_dbg_sel           => sl_dbg_sel,
            pol_dbg_done          => sl_dbg_done,
            pil_dbg_next_data     => sl_dbg_host_tx_done,
            pol_dbg_tx_en         => sl_dbg_tx_en,
            pov_dbg_tx_data       => sv_dbg_tx_data,
            pol_dbg_next_data     => sl_dbg_req_next_data,
            pil_dbg_rx_valid      => sl_dbg_rx_valid,
            piv_dbg_rx_data       => sv_dbg_rx_data,
            pol_dbg_mem_access    => pol_dbg_mem_access,
            pov_dbg_mem_addr      => pov_dbg_mem_addr,
            pol_dbg_mem_write     => pol_dbg_mem_write,
            pov_dbg_mem_wdata     => pov_dbg_mem_wdata,
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

end architecture;