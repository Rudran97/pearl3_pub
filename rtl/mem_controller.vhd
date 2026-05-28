library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity mem_controller is
	generic (
		gv_NUM_BYTES      : std_logic_vector := X"0000_4000";
        gs_SRAM_INIT_FILE : string           := ""
	);
	port (
		pil_clk           : in std_logic;
		pil_rst           : in std_logic;
		pil_mem_prg_req   : in std_logic;

		pil_mem_req       : in std_logic;
		pil_mem_wen       : in std_logic;
		pol_mem_ack       : out std_logic;
		pol_mem_valid     : out std_logic;

		piv_mem_byte_sel  : in std_logic_vector(3 downto 0);
		piv_mem_addr      : in std_logic_vector(31 downto 0);
		piv_mem_wdata     : in std_logic_vector(31 downto 0);
		pov_mem_rdata     : out std_logic_vector(31 downto 0)
	);
end entity mem_controller;

architecture rtl of mem_controller is

	constant cv_base_seg0   : std_logic_vector(1 downto 0) := "00";
	constant cv_base_seg1   : std_logic_vector(1 downto 0) := "01";
	constant cv_base_seg2   : std_logic_vector(1 downto 0) := "10";

	signal sl_mem_valid     : std_logic;
	signal sl_mem_ack       : std_logic;
	signal sl_mem_wen       : std_logic;
	signal sv_mem_wdata     : std_logic_vector(31 downto 0);
	signal sv_mem_byte_sel  : std_logic_vector(3 downto 0);

	signal su_address_byte0 : unsigned(31 downto 2);
	signal su_address_byte1 : unsigned(31 downto 2);
	signal su_address_byte2 : unsigned(31 downto 2);
	signal su_address_byte3 : unsigned(31 downto 2);

	signal sl_mem0_wen      : std_logic;
	signal sv_mem0_addr     : std_logic_vector(31 downto 0);
	signal sv_mem0_wdata    : std_logic_vector(7 downto 0);
	signal sv_mem0_rdata    : std_logic_vector(7 downto 0);

	signal sl_mem1_wen      : std_logic;
	signal sv_mem1_addr     : std_logic_vector(31 downto 0);
	signal sv_mem1_wdata    : std_logic_vector(7 downto 0);
	signal sv_mem1_rdata    : std_logic_vector(7 downto 0);

	signal sl_mem2_wen      : std_logic;
	signal sv_mem2_addr     : std_logic_vector(31 downto 0);
	signal sv_mem2_wdata    : std_logic_vector(7 downto 0);
	signal sv_mem2_rdata    : std_logic_vector(7 downto 0);

	signal sl_mem3_wen      : std_logic;
	signal sv_mem3_addr     : std_logic_vector(31 downto 0);
	signal sv_mem3_wdata    : std_logic_vector(7 downto 0);
	signal sv_mem3_rdata    : std_logic_vector(7 downto 0);

	type t_mem_state is (
		idle_st,
		access_valid_st
	);

	signal st_mem_state     : t_mem_state;

	alias av_mem_seg_sel    : std_logic_vector(1 downto 0) is piv_mem_addr(1 downto 0);

begin

	proc_mem_ctrl : process (pil_clk, pil_rst) is
	begin
		if pil_rst = cl_RESET then
			su_address_byte0    <= (others => '0');
			su_address_byte1    <= (others => '0');
			su_address_byte2    <= (others => '0');
			su_address_byte3    <= (others => '0');
			sl_mem_valid        <= cl_DISABLE;
			sl_mem_ack          <= cl_DISABLE;
			sl_mem_wen          <= cl_DISABLE;
			sv_mem_wdata        <= (others => '0');
			sv_mem_byte_sel     <= (others => '0');
			st_mem_state        <= idle_st;
		elsif rising_edge(pil_clk) then
			sl_mem_ack          <= cl_DISABLE;
			sl_mem_valid        <= cl_DISABLE;
			sl_mem_wen          <= cl_DISABLE;
			sv_mem_wdata        <= (others => '0');
			sv_mem_byte_sel     <= (others => '0');

			case st_mem_state is
				when idle_st =>
					if pil_mem_req = cl_ENABLE then
						sl_mem_wen      <= pil_mem_wen;
						sv_mem_wdata    <= piv_mem_wdata;
						sv_mem_byte_sel <= piv_mem_byte_sel;
						case av_mem_seg_sel is
							when cv_base_seg0 =>
								su_address_byte0 <= unsigned(piv_mem_addr(31 downto 2));
								su_address_byte1 <= unsigned(piv_mem_addr(31 downto 2));
								su_address_byte2 <= unsigned(piv_mem_addr(31 downto 2));
								su_address_byte3 <= unsigned(piv_mem_addr(31 downto 2));
							when cv_base_seg1 =>
								su_address_byte0 <= unsigned(piv_mem_addr(31 downto 2)) + 1;
								su_address_byte1 <= unsigned(piv_mem_addr(31 downto 2));
								su_address_byte2 <= unsigned(piv_mem_addr(31 downto 2));
								su_address_byte3 <= unsigned(piv_mem_addr(31 downto 2));
							when cv_base_seg2 =>
								su_address_byte0 <= unsigned(piv_mem_addr(31 downto 2)) + 1;
								su_address_byte1 <= unsigned(piv_mem_addr(31 downto 2)) + 1;
								su_address_byte2 <= unsigned(piv_mem_addr(31 downto 2));
								su_address_byte3 <= unsigned(piv_mem_addr(31 downto 2));
							when others =>
								su_address_byte0 <= unsigned(piv_mem_addr(31 downto 2)) + 1;
								su_address_byte1 <= unsigned(piv_mem_addr(31 downto 2)) + 1;
								su_address_byte2 <= unsigned(piv_mem_addr(31 downto 2)) + 1;
								su_address_byte3 <= unsigned(piv_mem_addr(31 downto 2));
						end case;

						sl_mem_ack   <= cl_ENABLE;
						st_mem_state <= access_valid_st;
					end if;
				when access_valid_st =>
					sl_mem_valid     <= cl_ENABLE;
					st_mem_state     <= idle_st;
			end case;
		end if;
	end process proc_mem_ctrl;

	sl_mem0_wen   <= pil_mem_wen when pil_mem_prg_req = cl_ENABLE else
		sv_mem_byte_sel(0) and sl_mem_wen;
	sv_mem0_addr  <= "00" & piv_mem_addr(31 downto 2) when pil_mem_prg_req = cl_ENABLE else
		"00" & std_logic_vector(su_address_byte0);
	sv_mem0_wdata <= piv_mem_wdata(7 downto 0) when pil_mem_prg_req = cl_ENABLE else
		sv_mem_wdata(7 downto 0);

    inst_mem_seg0 : entity work.mem_bank
        generic map (
            gi_mem_depth     => to_integer(unsigned(gv_NUM_BYTES)) / 4,
            gi_mem_width     => 8,
            gs_mem_init_file => gs_SRAM_INIT_FILE,
            gi_seg_number    => 0
        )
        port map (
            pil_clk          => pil_clk,
            pil_mem_wen      => sl_mem0_wen,
            piv_mem_addr     => sv_mem0_addr,
            piv_mem_wdata    => sv_mem0_wdata,
            pov_mem_rdata    => sv_mem0_rdata
        );

	sl_mem1_wen   <= pil_mem_wen when pil_mem_prg_req = cl_ENABLE else
		sv_mem_byte_sel(1) and sl_mem_wen;
	sv_mem1_addr  <= "00" & piv_mem_addr(31 downto 2) when pil_mem_prg_req = cl_ENABLE else
		"00" & std_logic_vector(su_address_byte1);
	sv_mem1_wdata <= piv_mem_wdata(15 downto 8) when pil_mem_prg_req = cl_ENABLE else
		sv_mem_wdata(15 downto 8);

    inst_mem_seg1 : entity work.mem_bank
        generic map (
            gi_mem_depth     => to_integer(unsigned(gv_NUM_BYTES)) / 4,
            gi_mem_width     => 8,
            gs_mem_init_file => gs_SRAM_INIT_FILE,
            gi_seg_number    => 1
        )
        port map (
            pil_clk          => pil_clk,
            pil_mem_wen      => sl_mem1_wen,
            piv_mem_addr     => sv_mem1_addr,
            piv_mem_wdata    => sv_mem1_wdata,
            pov_mem_rdata    => sv_mem1_rdata
        );

	sl_mem2_wen   <= pil_mem_wen when pil_mem_prg_req = cl_ENABLE else
		sv_mem_byte_sel(2) and sl_mem_wen;
	sv_mem2_addr  <= "00" & piv_mem_addr(31 downto 2) when pil_mem_prg_req = cl_ENABLE else
		"00" & std_logic_vector(su_address_byte2);
	sv_mem2_wdata <= piv_mem_wdata(23 downto 16) when pil_mem_prg_req = cl_ENABLE else
		sv_mem_wdata(23 downto 16);

    inst_mem_seg2 : entity work.mem_bank
        generic map (
            gi_mem_depth     => to_integer(unsigned(gv_NUM_BYTES)) / 4,
            gi_mem_width     => 8,
            gs_mem_init_file => gs_SRAM_INIT_FILE,
            gi_seg_number    => 2
        )
        port map (
            pil_clk          => pil_clk,
            pil_mem_wen      => sl_mem2_wen,
            piv_mem_addr     => sv_mem2_addr,
            piv_mem_wdata    => sv_mem2_wdata,
            pov_mem_rdata    => sv_mem2_rdata
        );

	sl_mem3_wen   <= pil_mem_wen when pil_mem_prg_req = cl_ENABLE else
		sv_mem_byte_sel(3) and sl_mem_wen;
	sv_mem3_addr  <= "00" & piv_mem_addr(31 downto 2) when pil_mem_prg_req = cl_ENABLE else
		"00" & std_logic_vector(su_address_byte3);
	sv_mem3_wdata <= piv_mem_wdata(31 downto 24) when pil_mem_prg_req = cl_ENABLE else
		sv_mem_wdata(31 downto 24);

    inst_mem_seg3 : entity work.mem_bank
        generic map (
            gi_mem_depth     => to_integer(unsigned(gv_NUM_BYTES)) / 4,
            gi_mem_width     => 8,
            gs_mem_init_file => gs_SRAM_INIT_FILE,
            gi_seg_number    => 3
        )
        port map (
            pil_clk          => pil_clk,
            pil_mem_wen      => sl_mem3_wen,
            piv_mem_addr     => sv_mem3_addr,
            piv_mem_wdata    => sv_mem3_wdata,
            pov_mem_rdata    => sv_mem3_rdata
        );

	pol_mem_ack   <= sl_mem_ack;
	pol_mem_valid <= sl_mem_valid;
	pov_mem_rdata <= sv_mem3_rdata & sv_mem2_rdata & sv_mem1_rdata & sv_mem0_rdata;

end architecture rtl;