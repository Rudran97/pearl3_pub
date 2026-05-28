library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package options_soc_pkg is

    --- User options ---
    constant cv_PMEM_NUM_WORDS : std_logic_vector(31 downto 0) := X"0000_3000"; -- 48k Bytes
    constant cv_SRAM_NUM_BYTES : std_logic_vector(31 downto 0) := X"0000_4000"; -- 16k Bytes
    constant ci_PRG_SPEED      : integer                       := 115200;
    -- constant cv_PMEM_NUM_WORDS : std_logic_vector(31 downto 0) := X"0000_0A00";
    -- constant cv_SRAM_NUM_BYTES : std_logic_vector(31 downto 0) := X"0000_0A00";
    -- constant ci_PRG_SPEED      : integer                       := 50_0000;
    constant cs_PMEM_INIT_FILE : string                        := "../../test/sw/pmem_init.hex";
    constant cs_SRAM_INIT_FILE : string                        := "../../test/sw/sram_init.hex";
    constant cv_PMEM_ORIGIN    : std_logic_vector(31 downto 0) := X"8000_0000";
    constant cv_CLIC_ORIGIN    : std_logic_vector(31 downto 0) := X"4000_0000";
    constant cv_IO_ORIGIN      : std_logic_vector(31 downto 0) := X"2000_0000";
    constant cv_SRAM_ORIGIN    : std_logic_vector(31 downto 0) := X"1000_0000";
    constant cs_BUILD_VER      : string                        := "0090";
    
end package;