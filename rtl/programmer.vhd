library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.pearl3_soc_pkg.all;

entity programmer is
	generic (
		gs_device_id : string (1 to 17) := "PRV32XXXMMRR.XXXX"
	);
	port (
		pil_clk              : in std_logic;
		pil_rst              : in std_logic;
		pol_reset            : out std_logic;
		pol_core_start       : out std_logic;

        -------------------------------------------
        --- signals and packets to/from host_if ---
		pil_prg_sel          : in std_logic;
		pol_prg_done         : out std_logic;
		pil_prg_flash_hlt    : in std_logic;

		--- transmit ---
		pil_prg_next_data    : in std_logic;                      -- host_if requesting new data to transmit
		pol_prg_tx_en        : out std_logic;                     -- set host_if to transmit mode
		pov_prg_tx_data      : out std_logic_vector(7 downto 0);

		--- receive ---
		pol_prg_next_data    : out std_logic;                     -- request new data to receive
		pil_prg_rx_valid     : in std_logic;                      -- rx data is valid
		piv_prg_rx_data      : in std_logic_vector(7 downto 0);

		--- programmer/memory interfece ---
		pol_mem_req          : out std_logic;
		pol_mem_wen          : out std_logic;
		pov_mem_addr         : out std_logic_vector(31 downto 0);
		pov_mem_wdata        : out std_logic_vector(31 downto 0)
	);
end entity;

architecture rtl of programmer is

	type t_prg_fsm is (
		pwron_reset_st,
		idle_st,
		prog_on_st,
		transmit_id_st,
		receive_code_st,
		prog_off_st,
		reset_on_st,
		reset_off_st
	);
	signal st_prg_fsm                   : t_prg_fsm;

	signal sl_reset                     : std_logic;
	signal sl_core_start                : std_logic;
	signal sl_prg_done                  : std_logic;
	signal sl_prg_tx_en                 : std_logic;
	signal sv_prg_tx_data               : std_logic_vector(7 downto 0);
	signal sl_prg_next_data             : std_logic;
	signal sl_mem_req                   : std_logic;
	signal sl_mem_wen                   : std_logic;
	signal sv_mem_addr                  : std_logic_vector(31 downto 0);
	signal sv_mem_wdata                 : std_logic_vector(31 downto 0);
	
	signal si_id_char_ct                : integer range 1 to gs_device_id'length;

	--- hex decoder ---
	signal sl_decoder_en                : std_logic;
	signal sl_hex_data_valid            : std_logic;
	signal sv_hex_data_in               : std_logic_vector(7 downto 0);
	signal sl_wen                       : std_logic;
	signal sv_address                   : std_logic_vector(31 downto 0);
	signal sv_data                      : std_logic_vector(7 downto 0);
	signal sl_eof                       : std_logic;

begin

	proc_programmer : process (pil_clk, pil_rst)
	begin
		if pil_rst = cl_RESET then
			sl_reset            <= cl_RESET;
			sl_core_start       <= cl_DISABLE;
			sl_decoder_en       <= cl_DISABLE;
			sl_mem_req          <= cl_DISABLE;
			sl_prg_done         <= cl_DISABLE;
			sl_prg_tx_en        <= cl_DISABLE;
			sl_prg_next_data    <= cl_DISABLE;
			si_id_char_ct       <= 1;
			st_prg_fsm          <= pwron_reset_st;
		elsif rising_edge(pil_clk) then
			case st_prg_fsm is
				when pwron_reset_st   =>
					sl_reset          <= cl_RESET;
					sl_core_start     <= cl_ENABLE;
					sl_decoder_en     <= cl_DISABLE;
					sl_prg_done       <= cl_DISABLE;
					sl_prg_tx_en      <= cl_DISABLE;
					sl_prg_next_data  <= cl_DISABLE;
					st_prg_fsm        <= idle_st;
				when idle_st             =>
					sl_reset          <= cl_NOTRESET;

					if pil_prg_sel = cl_ENABLE then
						sl_core_start <= cl_DISABLE;
						st_prg_fsm    <= prog_on_st;
					end if;
				when prog_on_st          =>
					sl_reset          <= cl_NOTRESET;
					sl_decoder_en     <= cl_ENABLE;
					sl_mem_req        <= cl_ENABLE;
					sl_prg_tx_en      <= cl_ENABLE;
					st_prg_fsm        <= transmit_id_st;
				when transmit_id_st      =>
					if pil_prg_next_data = cl_ENABLE then
						if si_id_char_ct < gs_device_id'length then
							si_id_char_ct <= si_id_char_ct + 1;
						else
							si_id_char_ct <= 1;
							sl_prg_tx_en  <= cl_DISABLE;
							st_prg_fsm    <= receive_code_st;
						end if;
					end if;
				when receive_code_st     =>
					sl_prg_next_data      <= cl_ENABLE;    -- receive hex code
					st_prg_fsm            <= prog_off_st;
				when prog_off_st         =>
					if sl_eof = cl_ENABLE then
						sl_prg_next_data  <= cl_DISABLE;
						sl_prg_done       <= cl_ENABLE;
						sl_mem_req        <= cl_DISABLE;
						sl_decoder_en     <= cl_DISABLE;
						st_prg_fsm        <= reset_on_st;
					end if;
				when reset_on_st         =>
					sl_core_start         <= not pil_prg_flash_hlt;
					sl_reset              <= cl_RESET;
					st_prg_fsm            <= reset_off_st;
				when reset_off_st        =>
					sl_reset              <= cl_NOTRESET;
					sl_prg_done           <= cl_DISABLE;
					st_prg_fsm            <= idle_st;
			end case;
		end if;
	end process proc_programmer;

	sv_prg_tx_data <= std_logic_vector(to_unsigned(character'pos(gs_device_id(si_id_char_ct)), 8));

	-----------------------------------------------------------------------------------------------------
	------------------------------------------DECODER MODULE---------------------------------------------
	-----------------------------------------------------------------------------------------------------

	sl_hex_data_valid <= pil_prg_rx_valid;
	sv_hex_data_in    <= piv_prg_rx_data;

	inst_hex_decode : entity work.hex_decode
		port map(
			pil_clk            => pil_clk,
			pil_rst            => pil_rst,
			pil_hex_decoder_en => sl_decoder_en,
			pil_data_valid     => sl_hex_data_valid,
			piv_data           => sv_hex_data_in,
			pol_wen            => sl_wen,
			pov_address        => sv_address,
			pov_data           => sv_data,
			pol_eof            => sl_eof
		);

	proc_mem_data : process (pil_clk, pil_rst)
	begin
		if pil_rst = cl_RESET then
			sl_mem_wen     <= cl_DISABLE;
			sv_mem_addr    <= (others => '0');
			sv_mem_wdata   <= (others => '0');
		elsif rising_edge(pil_clk) then
			sl_mem_wen     <= cl_DISABLE;

			--- Only enable wen when a complete 32 bit data has been received ---
			case sv_address(1 downto 0) is
				when "00"   =>
					sv_mem_wdata(7 downto 0)   <= sv_data;
				when "01"   =>
					sv_mem_wdata(15 downto 8)  <= sv_data;
				when "10"   =>
					sv_mem_wdata(23 downto 16) <= sv_data;
				when "11"   =>
					sl_mem_wen                 <= sl_wen;
					sv_mem_addr                <= sv_address(31 downto 2) & "00";
					sv_mem_wdata(31 downto 24) <= sv_data;
				when others =>
			end case;
		end if;
	end process proc_mem_data;

	pol_core_start      <= sl_core_start;
	pol_reset           <= sl_reset;

	pol_prg_done        <= sl_prg_done; 
	pol_prg_tx_en       <= sl_prg_tx_en;
	pov_prg_tx_data     <= sv_prg_tx_data;
	pol_prg_next_data   <= sl_prg_next_data;

	pol_mem_req         <= sl_mem_req;
	pol_mem_wen         <= sl_mem_wen;
	pov_mem_addr        <= sv_mem_addr;
	pov_mem_wdata       <= sv_mem_wdata;

end architecture;