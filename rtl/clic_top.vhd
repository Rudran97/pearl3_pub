library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.clic_pkg.all;
use work.pearl3_soc_pkg.all;

entity clic_top is
    generic (
        gv_PREM_ORIGIN       : std_logic_vector(31 downto 0) := X"8000_0000"
    );
    port (
        pil_clk              : in std_logic;
        pil_rst              : in std_logic;

        --- external src and clic interface ---
        piv_irq_src          : in std_logic_vector(7 downto 0);
        pov_irq_clr          : out std_logic_vector(7 downto 0); -- clic requests the source to clear the interrupt

        --- Core and CLIC Interface ---
        pil_clic_wen         : in std_logic;
        piv_clic_addr        : in std_logic_vector(4 downto 0);
        piv_clic_wdata       : in std_logic_vector(15 downto 0);
        pov_clic_rdata       : out std_logic_vector(15 downto 0);

        pil_irq_done         : in std_logic;
        pol_irq_fast_irq_pin : out std_logic;
        pol_irq_ei_irq_pin   : out std_logic;
        pov_irq_id           : out std_logic_vector(3 downto 0);
        pov_irq_vect         : out std_logic_vector(31 downto 0)
    );
end entity clic_top;

architecture rtl of clic_top is

    constant ci_INTCON            : integer := 16;
    constant ci_IRQID             : integer := 17;
    constant ci_INTSRC            : integer := 18;
    constant ci_INTCLR            : integer := 19;
    constant ci_INTSTAT           : integer := 20;

    constant ci_INTCON_gie_bit    : integer := 0;  -- global interrupt enable bit
    constant ci_INTCON_EIPin_bit  : integer := 2;  -- when '1' all IRQ is routed to EI pin
                                                   -- when '0' all IRQ is routed to fast IRQ pin
    constant ci_INTSTAT_IRQ_STATE : integer := 0;  -- intended to be read only. It holds the
                                                   -- current state of the irq pin

    type tav_clic_config is array (0 to 31) of std_logic_vector(15 downto 0);
    signal stav_clic_config       : tav_clic_config;

    signal stav_clic_int_prio     : tav_int_prio(0 to 7);
    signal stav_clic_int_isr_vec  : tav_int_isr_vector(0 to 7);

    signal sv_clic_irq_clr        : std_logic_vector(7 downto 0);
    signal sl_clic_irq_en         : std_logic;
    signal sl_clic_irq            : std_logic;
    signal sv_clic_irq_id         : std_logic_vector(3 downto 0);
    signal sv_clic_irq_vect       : std_logic_vector(31 downto 0);

begin
    
    proc_clic_mem : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            for ii in 0 to stav_clic_config'high loop
                stav_clic_config(ii) <= (others => '0');
            end loop;
        elsif rising_edge(pil_clk) then
            if pil_clic_wen = cl_ENABLE then
                stav_clic_config(to_integer(unsigned(piv_clic_addr))) <= piv_clic_wdata;
            end if;

            if sl_clic_irq = cl_PENDING then
                stav_clic_config(ci_IRQID)              <= (others => '0');
                stav_clic_config(ci_IRQID)(3 downto 0)  <= sv_clic_irq_id;
                stav_clic_config(ci_INTCLR)(7 downto 0) <= sv_clic_irq_clr;
            end if;

            stav_clic_config(ci_INTSTAT)(ci_INTSTAT_IRQ_STATE) <= sl_clic_irq;
            stav_clic_config(ci_INTSRC)(7 downto 0)            <= piv_irq_src;
        end if;
    end process proc_clic_mem;

    pov_clic_rdata <= stav_clic_config(to_integer(unsigned(piv_clic_addr)));

    gen_clic_int_prio : for ii in 0 to 7 generate
        stav_clic_int_isr_vec(ii) <= gv_PREM_ORIGIN(31 downto 16) & stav_clic_config(ii);
    end generate;
    
    gen_clic_int_isr_vec : for ii in 0 to 7 generate
        stav_clic_int_prio(ii)    <= stav_clic_config(ii + 8)(2 downto 0);
    end generate;
    
    sl_clic_irq_en <= stav_clic_config(ci_INTCON)(ci_INTCON_gie_bit);
    
    inst_clic : entity work.clic
        port map (
            pil_clk              => pil_clk,
            pil_rst              => pil_rst,
            pitav_int_prio       => stav_clic_int_prio,
            pitav_int_isr_vector => stav_clic_int_isr_vec,
            piv_irq_src          => piv_irq_src,
            pov_irq_clr          => sv_clic_irq_clr,
            pil_clic_irq_en      => sl_clic_irq_en,
            pil_irq_done         => pil_irq_done,
            pol_irq              => sl_clic_irq,
            pov_irq_id           => sv_clic_irq_id,
            pov_irq_vect         => sv_clic_irq_vect
    );

    pov_irq_clr           <= sv_clic_irq_clr;
    pol_irq_fast_irq_pin  <= sl_clic_irq when stav_clic_config(ci_INTCON)(ci_INTCON_EIPin_bit) = cl_DISABLE else
        cl_DISABLE;
    pol_irq_ei_irq_pin    <= sl_clic_irq when stav_clic_config(ci_INTCON)(ci_INTCON_EIPin_bit) = cl_ENABLE else
        cl_DISABLE;
    pov_irq_id            <= sv_clic_irq_id;
    pov_irq_vect          <= sv_clic_irq_vect;

end architecture;