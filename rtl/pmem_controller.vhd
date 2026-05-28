library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity pmem_controller is
    generic (
        gv_NUM_WORDS      : std_logic_vector(31 downto 0) := X"0000_3000"; -- 48k Bytes
        gs_PMEM_INIT_FILE : string                        := ""
    );
    port (
        pil_clk           : in std_logic;
        pil_rst           : in std_logic;
        pil_pmem_wen      : in std_logic;
        piv_pmem_addr     : in std_logic_vector(31 downto 0);
        piv_pmem_wdata    : in std_logic_vector(31 downto 0);
        pov_pmem_rdata    : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of pmem_controller is

    --- Number of Half_words = Number of Words * 2 ---
    constant cv_NUM_HALF_WORDS : std_logic_vector(31 downto 0) := gv_NUM_WORDS(30 downto 0) & '0';

	signal sv_mem0_addr        : std_logic_vector(31 downto 0);
	signal sv_mem0_wdata       : std_logic_vector(15 downto 0);
	signal sv_mem0_rdata       : std_logic_vector(15 downto 0);

	signal sv_mem1_addr        : std_logic_vector(31 downto 0);
	signal sv_mem1_wdata       : std_logic_vector(15 downto 0);
	signal sv_mem1_rdata       : std_logic_vector(15 downto 0);

    signal sv_curr_addr        : std_logic_vector(31 downto 0);
    signal sv_next_addr        : std_logic_vector(31 downto 0);
    signal sv_req_addr         : std_logic_vector(31 downto 0);

begin

    proc_get_pmem_addr : process (piv_pmem_addr)
    begin
        sv_curr_addr <= piv_pmem_addr;
        sv_next_addr <= std_logic_vector(unsigned(piv_pmem_addr) + 2);
    end process proc_get_pmem_addr;

    proc_align_pmem_addr : process (sv_curr_addr, sv_next_addr)
    begin
        sv_mem0_addr <= "00" & sv_next_addr(31 downto 2);
        sv_mem1_addr <= "00" & sv_curr_addr(31 downto 2);
    end process proc_align_pmem_addr;

    proc_req_addr : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sv_req_addr <= (others => '0');
        elsif rising_edge(pil_clk) then
            --- save the current address which the core has requested to prefetch ---
            sv_req_addr <= piv_pmem_addr;
        end if;
    end process proc_req_addr;

    sv_mem0_wdata <= piv_pmem_wdata(15 downto 0);

    inst_mem_seg0 : entity work.mem_bank
        generic map (
            gi_mem_depth     => to_integer(unsigned(cv_NUM_HALF_WORDS)) / 2,
            gi_mem_width     => 16,
            gs_mem_init_file => gs_PMEM_INIT_FILE,
            gi_seg_number    => 0
        )
        port map (
            pil_clk          => pil_clk,
            pil_mem_wen      => pil_pmem_wen,
            piv_mem_addr     => sv_mem0_addr,
            piv_mem_wdata    => sv_mem0_wdata,
            pov_mem_rdata    => sv_mem0_rdata
        );

    sv_mem1_wdata <= piv_pmem_wdata(31 downto 16);

    inst_mem_seg1 : entity work.mem_bank
        generic map (
            gi_mem_depth     => to_integer(unsigned(cv_NUM_HALF_WORDS)) / 2,
            gi_mem_width     => 16,
            gs_mem_init_file => gs_PMEM_INIT_FILE,
            gi_seg_number    => 1
        )
        port map (
            pil_clk          => pil_clk,
            pil_mem_wen      => pil_pmem_wen,
            piv_mem_addr     => sv_mem1_addr,
            piv_mem_wdata    => sv_mem1_wdata,
            pov_mem_rdata    => sv_mem1_rdata
        );

    pov_pmem_rdata <= sv_mem0_rdata & sv_mem1_rdata when sv_req_addr(1 downto 0) = "10" else
        sv_mem1_rdata & sv_mem0_rdata;

end architecture;