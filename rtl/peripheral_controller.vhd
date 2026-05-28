library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

use work.peripheral_controller_pkg.all;

use work.timer_pkg.all;
use work.uart_controller_pkg.all;
use work.i2c_master_pkg.all;
use work.spi_master_pkg.all;

entity peripheral_controller is
    port (
        pil_clk            : in std_logic;
        pil_rst            : in std_logic;
        pil_ioctrl_wen     : in std_logic;
        piv_ioctrl_addr    : in std_logic_vector(11 downto 0);
        piv_ioctrl_wdata   : in std_logic_vector(31 downto 0);
        pov_ioctrl_rdata   : out std_logic_vector(31 downto 0);
        --- Interrupts ---
        pov_IRQ_src        : out std_logic_vector(7 downto 0);
        piv_IRQ_clr        : in std_logic_vector(7 downto 0);
        --- GPIO ---
        piv_PORTA          : in std_logic_vector(15 downto 0);
        piv_PORTB          : in std_logic_vector(15 downto 0);
        pov_DDRA           : out std_logic_vector(15 downto 0);
        pov_DDRB           : out std_logic_vector(15 downto 0);
        pov_LATA           : out std_logic_vector(15 downto 0);
        pov_LATB           : out std_logic_vector(15 downto 0);
        pov_LATD           : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of peripheral_controller is

    type tav_pctrl_mem is array (0 to 127) of std_logic_vector(15 downto 0);
    signal stav_pctrl_mem : tav_pctrl_mem;

    signal sv_pctrl_data_out : std_logic_vector(31 downto 0);

    --- GPIO registers ---
    signal sv_DDRA : std_logic_vector(15 downto 0);
    signal sv_DDRB : std_logic_vector(15 downto 0);

    signal sv_LATA : std_logic_vector(15 downto 0);
    signal sv_LATB : std_logic_vector(15 downto 0);
    signal sv_LATD : std_logic_vector(15 downto 0);

    signal sv_interrupt_flags    : std_logic_vector(31 downto 0); -- holds the interrupt source flags from each peripheral units.
    signal sv_interrupt_clr_maps : std_logic_vector(31 downto 0); -- holds the int clr signal coming in. The register bits are ordered corresponding to each peripheral.

    signal sv_INT_src : std_logic_vector(7 downto 0); -- actual output register for remapped interrupt sources.

    --- timer unit ---

    type tav_DCT_control is array (0 to 3) of std_logic_vector(5 downto 0);
    type tav_DCT_in is array (0 to 3) of std_logic_vector(31 downto 0);
    type tav_DCT_flag is array (0 to 3) of std_logic_vector(1 downto 0);
    type tav_DCT_out is array (0 to 3) of std_logic_vector(31 downto 0);

    signal stav_DCT_control : tav_DCT_control;
    signal stav_DCT_in      : tav_DCT_in;
    signal stav_DCT_flag    : tav_DCT_flag;
    signal stav_DCT_out     : tav_DCT_out;

    type tav_ICT_control is array (0 to 1) of std_logic_vector(11 downto 0);
    type tav_ICT_port is array (0 to 1) of std_logic_vector(3 downto 0);
    type tav_ICT_in is array (0 to 1) of std_logic_vector(31 downto 0);
    type tav_ICT_flag is array (0 to 1) of std_logic_vector(1 downto 0);
    type tav_ICT_out is array (0 to 1) of std_logic_vector(31 downto 0);

    signal stav_ICT_control : tav_ICT_control;
    signal stav_ICT_port    : tav_ICT_port;
    signal stav_ICT_in      : tav_ICT_in;
    signal stav_ICT_flag    : tav_ICT_flag;
    signal stav_ICT_out     : tav_ICT_out;

    --- uart unit ---

    type tav_UART_control is array (0 to 1) of std_logic_vector(2 downto 0);
    type tav_UART_half_bd is array (0 to 1) of std_logic_vector(15 downto 0);
    type tav_UART_tx_data is array (0 to 1) of std_logic_vector(8 downto 0);
    type tav_UART_rx_data is array (0 to 1) of std_logic_vector(8 downto 0);
    type tal_UART_rx is array (0 to 1) of std_logic;
    type tal_UART_tx is array (0 to 1) of std_logic;
    type tal_UART_RXIF is array (0 to 1) of std_logic;
    type tal_UART_TXIF is array (0 to 1) of std_logic;
    type tal_UART_FERR is array (0 to 1) of std_logic;

    signal stav_UART_control : tav_UART_control;
    signal stav_UART_half_bd : tav_UART_half_bd;
    signal stav_UART_tx_data : tav_UART_tx_data;
    signal stav_UART_rx_data : tav_UART_rx_data;
    signal stal_UART_rx      : tal_UART_rx;
    signal stal_UART_tx      : tal_UART_tx;
    signal stal_UART_RXIF    : tal_UART_RXIF;
    signal stal_UART_TXIF    : tal_UART_TXIF;
    signal stal_UART_FERR    : tal_UART_FERR;

    --- i2c unit ---

    signal sv_I2C_master_control : std_logic_vector(6 downto 0);
    signal sv_I2C_baud_rate      : std_logic_vector(9 downto 0);
    signal sv_I2C_tot_rate       : std_logic_vector(5 downto 0);
    signal sv_I2C_set_hold_rate  : std_logic_vector(3 downto 0);
    signal sv_I2C_tx_data        : std_logic_vector(7 downto 0);
    signal sv_I2C_rx_data        : std_logic_vector(7 downto 0);
    signal sl_I2C_ack_tx         : std_logic;
    signal sl_I2C_ack_rx         : std_logic;

    signal sl_I2C_scl_in  : std_logic;
    signal sl_I2C_scl_out : std_logic;
    signal sl_I2C_scl_oe  : std_logic;
    signal sl_I2C_sda_in  : std_logic;
    signal sl_I2C_sda_out : std_logic;
    signal sl_I2C_sda_oe  : std_logic;

    signal sl_I2C_master_if     : std_logic;
    signal sl_I2C_master_bclf   : std_logic;
    signal sl_I2C_master_bus_to : std_logic;
    signal sl_I2C_master_done   : std_logic;

    --- spi unit ---

    signal sv_SPI_baud_rate      : std_logic_vector(9 downto 0);
    signal sv_SPI_master_control : std_logic_vector(2 downto 0);
    signal sv_SPI_tx_data        : std_logic_vector(7 downto 0);
    signal sv_SPI_rx_data        : std_logic_vector(7 downto 0);
    signal sl_SPI_sclk           : std_logic;
    signal sl_SPI_sdo            : std_logic;
    signal sl_SPI_sdi            : std_logic;
    signal sl_SPI_nss            : std_logic;
    signal sl_SPI_master_if      : std_logic;

    --- external trigger unit ---

    type tav_EXT_trigger_control is array (0 to 3) of std_logic_vector(5 downto 0);
    type tal_EXT_in is array (0 to 3) of std_logic;
    type tal_EXT_ICF is array (0 to 3) of std_logic;

    signal stav_EXT_trigger_control : tav_EXT_trigger_control;
    signal stal_EXT_in              : tal_EXT_in;
    signal stal_EXT_ICF             : tal_EXT_ICF;

    --- pwm unit ---

    type tal_PWM_en is array (0 to 5) of std_logic;
    type tav_PWM_timer is array (0 to 5) of std_logic_vector(11 downto 0);
    type tav_PWM_Hz is array (0 to 5) of std_logic_vector(11 downto 0);
    type tav_PWM_DC is array (0 to 5) of std_logic_vector(11 downto 0);
    type tal_PWM_out is array (0 to 5) of std_logic;

    signal stal_PWM_en    : tal_PWM_en;
    signal stav_PWM_timer : tav_PWM_timer;
    signal stav_PWM_Hz    : tav_PWM_Hz;
    signal stav_PWM_DC    : tav_PWM_DC;
    signal stal_PWM_out   : tal_PWM_out;

begin

    proc_pctrl : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            for ii in 0 to 127 loop
                stav_pctrl_mem(ii) <= (others => '0');
            end loop;
            stav_pctrl_mem(ci_DDRA) <= (others => '1');
            stav_pctrl_mem(ci_DDRB) <= (others => '1');
            sv_DDRA                 <= (others => '1');
            sv_DDRB                 <= (others => '1');
        elsif rising_edge(pil_clk) then
            --- resetting control bits ---
            stav_pctrl_mem(ci_T0CON)(ctr_dct_con.i_clr_TFB downto ctr_dct_con.i_TRA_set)             <= (others => '0');
            stav_pctrl_mem(ci_T1CON)(ctr_dct_con.i_clr_TFB downto ctr_dct_con.i_TRA_set)             <= (others => '0');
            stav_pctrl_mem(ci_T2CON)(ctr_dct_con.i_clr_TFB downto ctr_dct_con.i_TRA_set)             <= (others => '0');
            stav_pctrl_mem(ci_T3CON)(ctr_dct_con.i_clr_TFB downto ctr_dct_con.i_TRA_set)             <= (others => '0');
            stav_pctrl_mem(ci_T4CON)(ctr_ict_con.i_TIC_flag_clr downto ctr_ict_con.i_Timer_flag_clr) <= "00";
            stav_pctrl_mem(ci_T4CON)(ctr_ict_con.i_TR_set downto ctr_ict_con.i_TIC_set)              <= "00";
            stav_pctrl_mem(ci_T5CON)(ctr_ict_con.i_TIC_flag_clr downto ctr_ict_con.i_Timer_flag_clr) <= "00";
            stav_pctrl_mem(ci_T5CON)(ctr_ict_con.i_TR_set downto ctr_ict_con.i_TIC_set)              <= "00";

            stav_pctrl_mem(ci_I2C0CON0)(ctr_i2c_con0.i_CLRF)                                         <= cl_DISABLE;
            stav_pctrl_mem(ci_SPI0CON0)(ctr_spi_con0.i_CLRF)                                         <= cl_DISABLE;
            ---
            if pil_ioctrl_wen = cl_ENABLE then
                stav_pctrl_mem(to_integer(unsigned(piv_ioctrl_addr(6 downto 0))))                    <= piv_ioctrl_wdata(15 downto 0);
            end if;
            --- gpio ---
            stav_pctrl_mem(ci_PORTA)                                                                 <= piv_PORTA;
            stav_pctrl_mem(ci_PORTB)                                                                 <= piv_PORTB;
            --- uart ---
            stav_pctrl_mem(ci_URT0RX)(8 downto 0)                                                    <= stav_UART_rx_data(0);
            stav_pctrl_mem(ci_URT1RX)(8 downto 0)                                                    <= stav_UART_rx_data(1);
            stav_pctrl_mem(ci_URT0CON)(ctr_uart_con.i_RXIF)                                          <= stal_UART_RXIF(0);
            stav_pctrl_mem(ci_URT1CON)(ctr_uart_con.i_RXIF)                                          <= stal_UART_RXIF(1);
            stav_pctrl_mem(ci_URT0CON)(ctr_uart_con.i_TXIF)                                          <= stal_UART_TXIF(0);
            stav_pctrl_mem(ci_URT1CON)(ctr_uart_con.i_TXIF)                                          <= stal_UART_TXIF(1);
            stav_pctrl_mem(ci_URT0CON)(ctr_uart_con.i_FERR)                                          <= stal_UART_FERR(0);
            stav_pctrl_mem(ci_URT1CON)(ctr_uart_con.i_FERR)                                          <= stal_UART_FERR(1);
            --- i2c ---
            if stav_pctrl_mem(ci_I2C0CON0)(ctr_i2c_con0.i_CLRF) = cl_ENABLE then
                stav_pctrl_mem(ci_I2C0CON0)(ctr_i2c_con0.i_ACKEN downto ctr_i2c_con0.i_SEN)          <= (others => '0');
            end if;

            stav_pctrl_mem(ci_I2C0RX)(7 downto 0)                                                    <= sv_I2C_rx_data;
            stav_pctrl_mem(ci_I2C0CON0)(ctr_i2c_con0.i_DN downto ctr_i2c_con0.i_ACKSTAT)             <= sl_I2C_master_done & sl_I2C_master_bus_to & sl_I2C_master_bclf & sl_I2C_master_if & sl_I2C_ack_rx;
            --- spi ---
            if stav_pctrl_mem(ci_SPI0CON0)(ctr_spi_con0.i_CLRF) = cl_ENABLE or sv_interrupt_clr_maps(ctr_int_map.i_SPI0IF) = cl_ENABLE then
                --- turn off the spi module which clears the flag ---
                stav_pctrl_mem(ci_SPI0CON0)(ctr_spi_con0.i_EN)                                       <= cl_DISABLE; 
            end if;

            stav_pctrl_mem(ci_SPI0RX)(7 downto 0)                                                    <= sv_SPI_rx_data;
            stav_pctrl_mem(ci_SPI0CON0)(ctr_spi_con0.i_IF)                                           <= sl_SPI_master_if;
            --- Alt functions at PORT A ---
            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_URT0_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTA)(to_integer(unsigned(stav_pctrl_mem(ci_URT0CON)(ctr_uart_con.i_TX_SEL3 downto ctr_uart_con.i_TX_SEL0))))     <= stal_UART_tx(0);
            end if;

            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_I2C0_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTA)(to_integer(unsigned(stav_pctrl_mem(ci_I2C0CON2)(ctr_i2c_con2.i_SCL_SEL3 downto ctr_i2c_con2.i_SCL_SEL0))))  <= sl_I2C_scl_out;
                stav_pctrl_mem(ci_ALTOUTA)(to_integer(unsigned(stav_pctrl_mem(ci_I2C0CON2)(ctr_i2c_con2.i_SDA_SEL3 downto ctr_i2c_con2.i_SDA_SEL0))))  <= sl_I2C_sda_out;
            end if;

            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_PWM0_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTA)(to_integer(unsigned(stav_pctrl_mem(ci_PWM0CON)(ctr_pwm_con.i_PWM_SEL3 downto ctr_pwm_con.i_PWM_SEL0))))     <= stal_PWM_out(0);
            end if;

            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_PWM1_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTA)(to_integer(unsigned(stav_pctrl_mem(ci_PWM1CON)(ctr_pwm_con.i_PWM_SEL3 downto ctr_pwm_con.i_PWM_SEL0))))     <= stal_PWM_out(1);
            end if;

            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_PWM2_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTA)(to_integer(unsigned(stav_pctrl_mem(ci_PWM2CON)(ctr_pwm_con.i_PWM_SEL3 downto ctr_pwm_con.i_PWM_SEL0))))     <= stal_PWM_out(2);
            end if;

            --- Alt function at PORT B ---
            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_URT1_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTB)(to_integer(unsigned(stav_pctrl_mem(ci_URT1CON)(ctr_uart_con.i_TX_SEL3 downto ctr_uart_con.i_TX_SEL0))))     <= stal_UART_tx(1);
            end if;

            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_SPI0_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTB)(to_integer(unsigned(stav_pctrl_mem(ci_SPI0CON1)(ctr_spi_con1.i_SCLK_SEL3 downto ctr_spi_con1.i_SCLK_SEL0)))) <= sl_SPI_sclk;
                stav_pctrl_mem(ci_ALTOUTB)(to_integer(unsigned(stav_pctrl_mem(ci_SPI0CON1)(ctr_spi_con1.i_SDO_SEL3 downto ctr_spi_con1.i_SDO_SEL0))))   <= sl_SPI_sdo;
                stav_pctrl_mem(ci_ALTOUTB)(to_integer(unsigned(stav_pctrl_mem(ci_SPI0CON1)(ctr_spi_con1.i_SS_SEL3 downto ctr_spi_con1.i_SS_SEL0))))     <= sl_SPI_nss;
            end if;

            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_PWM3_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTB)(to_integer(unsigned(stav_pctrl_mem(ci_PWM3CON)(ctr_pwm_con.i_PWM_SEL3 downto ctr_pwm_con.i_PWM_SEL0))))      <= stal_PWM_out(3);
            end if;

            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_PWM4_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTB)(to_integer(unsigned(stav_pctrl_mem(ci_PWM4CON)(ctr_pwm_con.i_PWM_SEL3 downto ctr_pwm_con.i_PWM_SEL0))))      <= stal_PWM_out(4);
            end if;

            if stav_pctrl_mem(ci_ALTOUTEN)(ctr_altout_en.i_PWM5_ALT_EN) = cl_ENABLE then
                stav_pctrl_mem(ci_ALTOUTB)(to_integer(unsigned(stav_pctrl_mem(ci_PWM5CON)(ctr_pwm_con.i_PWM_SEL3 downto ctr_pwm_con.i_PWM_SEL0))))      <= stal_PWM_out(5);
            end if;

            stav_pctrl_mem(ci_T0BUFL) <= stav_DCT_out(0)(15 downto 0);
            stav_pctrl_mem(ci_T0BUFH) <= stav_DCT_out(0)(31 downto 16);
            stav_pctrl_mem(ci_T1BUFL) <= stav_DCT_out(1)(15 downto 0);
            stav_pctrl_mem(ci_T1BUFH) <= stav_DCT_out(1)(31 downto 16);
            stav_pctrl_mem(ci_T2BUFL) <= stav_DCT_out(2)(15 downto 0);
            stav_pctrl_mem(ci_T2BUFH) <= stav_DCT_out(2)(31 downto 16);
            stav_pctrl_mem(ci_T3BUFL) <= stav_DCT_out(3)(15 downto 0);
            stav_pctrl_mem(ci_T3BUFH) <= stav_DCT_out(3)(31 downto 16);

            stav_pctrl_mem(ci_T4BUFL) <= stav_ICT_out(0)(15 downto 0);
            stav_pctrl_mem(ci_T4BUFH) <= stav_ICT_out(0)(31 downto 16);
            stav_pctrl_mem(ci_T5BUFL) <= stav_ICT_out(1)(15 downto 0);
            stav_pctrl_mem(ci_T5BUFH) <= stav_ICT_out(1)(31 downto 16);

            stav_pctrl_mem(ci_TFREG) <= X"0" & stav_ICT_flag(1) & stav_ICT_flag(0) & stav_DCT_flag(3) & stav_DCT_flag(2) & stav_DCT_flag(1) & stav_DCT_flag(0);

            ----------------------------------------------------------------

            sv_pctrl_data_out <= X"0000" & stav_pctrl_mem(to_integer(unsigned(piv_ioctrl_addr(6 downto 0))));

            sv_DDRA <= stav_pctrl_mem(ci_DDRA);

            if stav_pctrl_mem(ci_I2C0CON0)(ctr_i2c_con0.i_EN) = cl_ENABLE then
                sv_DDRA(to_integer(unsigned(stav_pctrl_mem(ci_I2C0CON2)(ctr_i2c_con2.i_SCL_SEL3 downto ctr_i2c_con2.i_SCL_SEL0)))) <= not sl_I2C_scl_oe;
                sv_DDRA(to_integer(unsigned(stav_pctrl_mem(ci_I2C0CON2)(ctr_i2c_con2.i_SDA_SEL3 downto ctr_i2c_con2.i_SDA_SEL0)))) <= not sl_I2C_sda_oe;
            end if;

            sv_DDRB <= stav_pctrl_mem(ci_DDRB);

            sv_LATA <= stav_pctrl_mem(ci_LATA);
            sv_LATB <= stav_pctrl_mem(ci_LATB);
            sv_LATD <= stav_pctrl_mem(ci_LATD);
        end if;
    end process proc_pctrl;

    -----------------------------------------------------------------------------------------------------
    ---------------------------------------INTERRUPT SOURCE MAPPING--------------------------------------
    -----------------------------------------------------------------------------------------------------

    proc_interrupt_map : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sv_interrupt_clr_maps <= (others => '0');
            sv_interrupt_flags    <= (others => '0');
            sv_INT_src            <= (others => '0');
        elsif rising_edge(pil_clk) then
            sv_interrupt_clr_maps <= (others => '0');
            sv_INT_src            <= (others => '0');

            sv_interrupt_clr_maps(to_integer(unsigned(stav_pctrl_mem(ci_INT0MAP)(4 downto 0)))) <= piv_IRQ_clr(0);
            sv_interrupt_clr_maps(to_integer(unsigned(stav_pctrl_mem(ci_INT1MAP)(4 downto 0)))) <= piv_IRQ_clr(1);
            sv_interrupt_clr_maps(to_integer(unsigned(stav_pctrl_mem(ci_INT2MAP)(4 downto 0)))) <= piv_IRQ_clr(2);
            sv_interrupt_clr_maps(to_integer(unsigned(stav_pctrl_mem(ci_INT3MAP)(4 downto 0)))) <= piv_IRQ_clr(3);
            sv_interrupt_clr_maps(to_integer(unsigned(stav_pctrl_mem(ci_INT4MAP)(4 downto 0)))) <= piv_IRQ_clr(4);
            sv_interrupt_clr_maps(to_integer(unsigned(stav_pctrl_mem(ci_INT5MAP)(4 downto 0)))) <= piv_IRQ_clr(5);
            sv_interrupt_clr_maps(to_integer(unsigned(stav_pctrl_mem(ci_INT6MAP)(4 downto 0)))) <= piv_IRQ_clr(6);
            sv_interrupt_clr_maps(to_integer(unsigned(stav_pctrl_mem(ci_INT7MAP)(4 downto 0)))) <= piv_IRQ_clr(7);

            sv_interrupt_flags <= X"0" & "00" & stal_EXT_ICF(3) & stal_EXT_ICF(2) & stal_EXT_ICF(1) & stal_EXT_ICF(0) & sl_SPI_master_if & sl_I2C_master_done & sl_I2C_master_bus_to & sl_I2C_master_bclf & sl_I2C_master_if & stal_UART_TXIF(1) & stal_UART_RXIF (1) & stal_UART_TXIF(0) & stal_UART_RXIF (0) & stav_ICT_flag(1) & stav_ICT_flag(0) & stav_DCT_flag(3) & stav_DCT_flag(2) & stav_DCT_flag(1) & stav_DCT_flag(0) & '0';

            sv_INT_src(0) <= sv_interrupt_flags(to_integer(unsigned(stav_pctrl_mem(ci_INT0MAP)(4 downto 0))));
            sv_INT_src(1) <= sv_interrupt_flags(to_integer(unsigned(stav_pctrl_mem(ci_INT1MAP)(4 downto 0))));
            sv_INT_src(2) <= sv_interrupt_flags(to_integer(unsigned(stav_pctrl_mem(ci_INT2MAP)(4 downto 0))));
            sv_INT_src(3) <= sv_interrupt_flags(to_integer(unsigned(stav_pctrl_mem(ci_INT3MAP)(4 downto 0))));
            sv_INT_src(4) <= sv_interrupt_flags(to_integer(unsigned(stav_pctrl_mem(ci_INT4MAP)(4 downto 0))));
            sv_INT_src(5) <= sv_interrupt_flags(to_integer(unsigned(stav_pctrl_mem(ci_INT5MAP)(4 downto 0))));
            sv_INT_src(6) <= sv_interrupt_flags(to_integer(unsigned(stav_pctrl_mem(ci_INT6MAP)(4 downto 0))));
            sv_INT_src(7) <= sv_interrupt_flags(to_integer(unsigned(stav_pctrl_mem(ci_INT7MAP)(4 downto 0))));
        end if;
    end process proc_interrupt_map;

    -----------------------------------------------------------------------------------------------------
    --------------------------------------DUAL COMPARE TIMER MODULE--------------------------------------
    -----------------------------------------------------------------------------------------------------

    stav_DCT_control(0)(ctr_dct_con.i_clr_TFA)                            <= stav_pctrl_mem(ci_T0CON)(ctr_dct_con.i_clr_TFA) or sv_interrupt_clr_maps(ctr_int_map.i_T0FA);
    stav_DCT_control(0)(ctr_dct_con.i_clr_TFB)                            <= stav_pctrl_mem(ci_T0CON)(ctr_dct_con.i_clr_TFB) or sv_interrupt_clr_maps(ctr_int_map.i_T0FB);
    stav_DCT_control(0)(ctr_dct_con.i_TRB_set downto ctr_dct_con.i_TRAON) <= stav_pctrl_mem(ci_T0CON)(ctr_dct_con.i_TRB_set downto ctr_dct_con.i_TRAON);

    stav_DCT_control(1)(ctr_dct_con.i_clr_TFA)                            <= stav_pctrl_mem(ci_T1CON)(ctr_dct_con.i_clr_TFA) or sv_interrupt_clr_maps(ctr_int_map.i_T1FA);
    stav_DCT_control(1)(ctr_dct_con.i_clr_TFB)                            <= stav_pctrl_mem(ci_T1CON)(ctr_dct_con.i_clr_TFB) or sv_interrupt_clr_maps(ctr_int_map.i_T1FB);
    stav_DCT_control(1)(ctr_dct_con.i_TRB_set downto ctr_dct_con.i_TRAON) <= stav_pctrl_mem(ci_T1CON)(ctr_dct_con.i_TRB_set downto ctr_dct_con.i_TRAON);

    stav_DCT_control(2)(ctr_dct_con.i_clr_TFA)                            <= stav_pctrl_mem(ci_T2CON)(ctr_dct_con.i_clr_TFA) or sv_interrupt_clr_maps(ctr_int_map.i_T2FA);
    stav_DCT_control(2)(ctr_dct_con.i_clr_TFB)                            <= stav_pctrl_mem(ci_T2CON)(ctr_dct_con.i_clr_TFB) or sv_interrupt_clr_maps(ctr_int_map.i_T2FB);
    stav_DCT_control(2)(ctr_dct_con.i_TRB_set downto ctr_dct_con.i_TRAON) <= stav_pctrl_mem(ci_T2CON)(ctr_dct_con.i_TRB_set downto ctr_dct_con.i_TRAON);

    stav_DCT_control(3)(ctr_dct_con.i_clr_TFA)                            <= stav_pctrl_mem(ci_T3CON)(ctr_dct_con.i_clr_TFA) or sv_interrupt_clr_maps(ctr_int_map.i_T3FA);
    stav_DCT_control(3)(ctr_dct_con.i_clr_TFB)                            <= stav_pctrl_mem(ci_T3CON)(ctr_dct_con.i_clr_TFB) or sv_interrupt_clr_maps(ctr_int_map.i_T3FB);
    stav_DCT_control(3)(ctr_dct_con.i_TRB_set downto ctr_dct_con.i_TRAON) <= stav_pctrl_mem(ci_T3CON)(ctr_dct_con.i_TRB_set downto ctr_dct_con.i_TRAON);

    stav_DCT_in(0) <= stav_pctrl_mem(ci_T0H) & stav_pctrl_mem(ci_T0L);
    stav_DCT_in(1) <= stav_pctrl_mem(ci_T1H) & stav_pctrl_mem(ci_T1L);
    stav_DCT_in(2) <= stav_pctrl_mem(ci_T2H) & stav_pctrl_mem(ci_T2L);
    stav_DCT_in(3) <= stav_pctrl_mem(ci_T3H) & stav_pctrl_mem(ci_T3L);

    gen_DCT_modules : for ii in 0 to 3 generate
        inst_DCT : entity work.dct
            generic map(
                gi_bus_width => 32
            )
            port map(
                pil_clk           => pil_clk,
                pil_rst           => pil_rst,
                piv_timer_control => stav_DCT_control(ii),
                piv_timer         => stav_DCT_in(ii),
                pov_timer_flag    => stav_DCT_flag(ii),
                pov_timer         => stav_DCT_out(ii)
            );
    end generate;

    -----------------------------------------------------------------------------------------------------
    --------------------------------------TIMER INPUT CAPTURE MODULE-------------------------------------
    -----------------------------------------------------------------------------------------------------

    stav_ICT_control(0)(ctr_ict_con.i_Timer_flag_clr)                                  <= stav_pctrl_mem(ci_T4CON)(ctr_ict_con.i_Timer_flag_clr) or sv_interrupt_clr_maps(ctr_int_map.i_T4F);
    stav_ICT_control(0)(ctr_ict_con.i_TIC_flag_clr)                                    <= stav_pctrl_mem(ci_T4CON)(ctr_ict_con.i_TIC_flag_clr) or sv_interrupt_clr_maps(ctr_int_map.i_T4ICF);
    stav_ICT_control(0)(ctr_ict_con.i_capture_end_pinBit1 downto ctr_ict_con.i_TICRON) <= stav_pctrl_mem(ci_T4CON)(ctr_ict_con.i_capture_end_pinBit1 downto ctr_ict_con.i_TICRON);

    stav_ICT_control(1)(ctr_ict_con.i_Timer_flag_clr)                                  <= stav_pctrl_mem(ci_T5CON)(ctr_ict_con.i_Timer_flag_clr) or sv_interrupt_clr_maps(ctr_int_map.i_T5F);
    stav_ICT_control(1)(ctr_ict_con.i_TIC_flag_clr)                                    <= stav_pctrl_mem(ci_T5CON)(ctr_ict_con.i_TIC_flag_clr) or sv_interrupt_clr_maps(ctr_int_map.i_T5ICF);
    stav_ICT_control(1)(ctr_ict_con.i_capture_end_pinBit1 downto ctr_ict_con.i_TICRON) <= stav_pctrl_mem(ci_T5CON)(ctr_ict_con.i_capture_end_pinBit1 downto ctr_ict_con.i_TICRON);

    stav_ICT_port(0) <= stav_pctrl_mem(ci_PORTB)(3 downto 0);
    stav_ICT_port(1) <= stav_pctrl_mem(ci_PORTB)(7 downto 4);

    stav_ICT_in(0) <= stav_pctrl_mem(ci_T4H) & stav_pctrl_mem(ci_T4L);
    stav_ICT_in(1) <= stav_pctrl_mem(ci_T5H) & stav_pctrl_mem(ci_T5L);

    gen_ICT_modules : for ii in 0 to 1 generate
        inst_ict : entity work.ict
            generic map(
                gi_bus_width => 32
            )
            port map(
                pil_clk           => pil_clk,
                pil_rst           => pil_rst,
                piv_timer_control => stav_ICT_control(ii),
                piv_port          => stav_ICT_port(ii),
                piv_timer         => stav_ICT_in(ii),
                pov_timer_flag    => stav_ICT_flag(ii),
                pov_timer         => stav_ICT_out(ii)
            );
    end generate;

    -----------------------------------------------------------------------------------------------------
    -----------------------------------EXTERNAL INTERRUPT TRIGGER UNIT-----------------------------------
    -----------------------------------------------------------------------------------------------------

    stav_EXT_trigger_control(0) <= stav_pctrl_mem(ci_EXT0CON)(ctr_ext_con.i_EN) & stav_pctrl_mem(ci_EXT0CON)(ctr_ext_con.i_TRIG_EG) & '0' & sv_interrupt_clr_maps(ctr_int_map.i_EXT0IN) & "00";
    stav_EXT_trigger_control(1) <= stav_pctrl_mem(ci_EXT1CON)(ctr_ext_con.i_EN) & stav_pctrl_mem(ci_EXT1CON)(ctr_ext_con.i_TRIG_EG) & '0' & sv_interrupt_clr_maps(ctr_int_map.i_EXT1IN) & "00";
    stav_EXT_trigger_control(2) <= stav_pctrl_mem(ci_EXT2CON)(ctr_ext_con.i_EN) & stav_pctrl_mem(ci_EXT2CON)(ctr_ext_con.i_TRIG_EG) & '0' & sv_interrupt_clr_maps(ctr_int_map.i_EXT2IN) & "00";
    stav_EXT_trigger_control(3) <= stav_pctrl_mem(ci_EXT3CON)(ctr_ext_con.i_EN) & stav_pctrl_mem(ci_EXT3CON)(ctr_ext_con.i_TRIG_EG) & '0' & sv_interrupt_clr_maps(ctr_int_map.i_EXT3IN) & "00";

    stal_EXT_in(0)              <= stav_pctrl_mem(ci_PORTA)(to_integer(unsigned(stav_pctrl_mem(ci_EXT0CON)(ctr_ext_con.i_TRIG_SEL3 downto ctr_ext_con.i_TRIG_SEL0))));
    stal_EXT_in(1)              <= stav_pctrl_mem(ci_PORTA)(to_integer(unsigned(stav_pctrl_mem(ci_EXT1CON)(ctr_ext_con.i_TRIG_SEL3 downto ctr_ext_con.i_TRIG_SEL0))));
    stal_EXT_in(2)              <= stav_pctrl_mem(ci_PORTB)(to_integer(unsigned(stav_pctrl_mem(ci_EXT2CON)(ctr_ext_con.i_TRIG_SEL3 downto ctr_ext_con.i_TRIG_SEL0))));
    stal_EXT_in(3)              <= stav_pctrl_mem(ci_PORTB)(to_integer(unsigned(stav_pctrl_mem(ci_EXT3CON)(ctr_ext_con.i_TRIG_SEL3 downto ctr_ext_con.i_TRIG_SEL0))));

    gen_external_trigger_unit : for ii in 0 to 3 generate
        inst_external_trigger_unit : entity work.input_capture_unit
            port map(
                pil_clk                   => pil_clk,
                pil_rst                   => pil_rst,
                piv_input_capture_control => stav_EXT_trigger_control(ii),
                pil_trigger               => stal_EXT_in(ii),
                pol_ICF                   => stal_EXT_ICF(ii),
                pol_ne_ICF                => open,
                pol_pe_ICF                => open
            );
    end generate;

    -----------------------------------------------------------------------------------------------------
    ----------------------------------------UART CONTROLLER----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    stav_UART_control(0) <= stav_pctrl_mem(ci_URT0CON)(ctr_uart_con.i_ENBIT9 downto ctr_uart_con.i_TXEN);
    stav_UART_control(1) <= stav_pctrl_mem(ci_URT1CON)(ctr_uart_con.i_ENBIT9 downto ctr_uart_con.i_TXEN);

    stav_UART_half_bd(0) <= stav_pctrl_mem(ci_URT0BRG);
    stav_UART_half_bd(1) <= stav_pctrl_mem(ci_URT1BRG);

    stav_UART_tx_data(0) <= stav_pctrl_mem(ci_URT0TX)(8 downto 0);
    stav_UART_tx_data(1) <= stav_pctrl_mem(ci_URT1TX)(8 downto 0);

    stal_UART_rx(0) <= stav_pctrl_mem(ci_PORTA)(to_integer(unsigned(stav_pctrl_mem(ci_URT0CON)(ctr_uart_con.i_RX_SEL3 downto ctr_uart_con.i_RX_SEL0))));
    stal_UART_rx(1) <= stav_pctrl_mem(ci_PORTB)(to_integer(unsigned(stav_pctrl_mem(ci_URT1CON)(ctr_uart_con.i_RX_SEL3 downto ctr_uart_con.i_RX_SEL0))));

    gen_UART_modules : for ii in 0 to 1 generate
        inst_uart_controller : entity work.uart_controller
            port map(
                pil_clk            => pil_clk,
                pil_rst            => pil_rst,
                piv_uart_control   => stav_UART_control(ii),
                piv_half_baud_rate => stav_UART_half_bd(ii),
                piv_tx_data        => stav_UART_tx_data(ii),
                pov_rx_data        => stav_UART_rx_data(ii),
                pil_uart_rx        => stal_UART_rx(ii),
                pol_uart_tx        => stal_UART_tx(ii),
                pol_uart_RXIF      => stal_UART_RXIF (ii),
                pol_uart_TXIF      => stal_UART_TXIF (ii),
                pol_frame_error    => stal_UART_FERR(ii),
                pol_uart_rx_busy   => open,
                pol_uart_tx_busy   => open
            );
    end generate;

    -----------------------------------------------------------------------------------------------------
    -------------------------------------I2C MASTER INTERFACE--------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sv_I2C_baud_rate      <= stav_pctrl_mem(ci_I2C0CON1)(ctr_i2c_con1.i_BRG9 downto ctr_i2c_con1.i_BRG0);
    sv_I2C_tot_rate       <= stav_pctrl_mem(ci_I2C0CON1)(ctr_i2c_con1.i_TOT5 downto ctr_i2c_con1.i_TOT0);
    sv_I2C_set_hold_rate  <= stav_pctrl_mem(ci_I2C0CON2)(ctr_i2c_con2.i_SHTM3 downto ctr_i2c_con2.i_SHTM0);
    sv_I2C_master_control <= stav_pctrl_mem(ci_I2C0CON0)(ctr_i2c_con0.i_ACKEN downto ctr_i2c_con0.i_EN);

    sv_I2C_tx_data <= stav_pctrl_mem(ci_I2C0TX)(7 downto 0);
    sl_I2C_ack_tx  <= stav_pctrl_mem(ci_I2C0CON0)(ctr_i2c_con0.i_ACKDAT);
    sl_I2C_scl_in  <= stav_pctrl_mem(ci_PORTA)(to_integer(unsigned(stav_pctrl_mem(ci_I2C0CON2)(ctr_i2c_con2.i_SCL_SEL3 downto ctr_i2c_con2.i_SCL_SEL0))));
    sl_I2C_sda_in  <= stav_pctrl_mem(ci_PORTA)(to_integer(unsigned(stav_pctrl_mem(ci_I2C0CON2)(ctr_i2c_con2.i_SDA_SEL3 downto ctr_i2c_con2.i_SDA_SEL0))));

    inst_i2c_master_top : entity work.i2c_master_top
        port map(
            pil_clk            => pil_clk,
            pil_rst            => pil_rst,
            piv_baud_rate      => sv_I2C_baud_rate,
            piv_tot_rate       => sv_I2C_tot_rate,
            piv_set_hold_rate  => sv_I2C_set_hold_rate,
            piv_master_control => sv_I2C_master_control,
            piv_tx_data        => sv_I2C_tx_data,
            pov_rx_data        => sv_I2C_rx_data,
            pil_ack            => sl_I2C_ack_tx,
            pol_ack            => sl_I2C_ack_rx,
            pil_scl            => sl_I2C_scl_in,
            pol_scl            => sl_I2C_scl_out,
            pol_scl_oe         => sl_I2C_scl_oe,
            pil_sda            => sl_I2C_sda_in,
            pol_sda            => sl_I2C_sda_out,
            pol_sda_oe         => sl_I2C_sda_oe,
            pol_master_if      => sl_I2C_master_if,
            pol_master_bclf    => sl_I2C_master_bclf,
            pol_master_bus_to  => sl_I2C_master_bus_to,
            pol_I2C_done       => sl_I2C_master_done
        );

    -----------------------------------------------------------------------------------------------------
    -------------------------------------SPI MASTER INTERFACE--------------------------------------------
    -----------------------------------------------------------------------------------------------------

    sv_SPI_baud_rate      <= stav_pctrl_mem(ci_SPI0CON0)(ctr_spi_con0.i_BRG9 downto ctr_spi_con0.i_BRG0);
    sv_SPI_master_control <= stav_pctrl_mem(ci_SPI0CON0)(ctr_spi_con0.i_CKP downto ctr_spi_con0.i_EN);

    sv_SPI_tx_data <= stav_pctrl_mem(ci_SPI0TX)(7 downto 0);

    sl_SPI_sdi <= stav_pctrl_mem(ci_PORTB)(to_integer(unsigned(stav_pctrl_mem(ci_SPI0CON1)(ctr_spi_con1.i_SDI_SEL3 downto ctr_spi_con1.i_SDI_SEL0))));

    inst_spi_master_top : entity work.spi_master_top
        port map(
            pil_clk            => pil_clk,
            pil_rst            => pil_rst,
            piv_baud_rate      => sv_SPI_baud_rate,
            piv_master_control => sv_SPI_master_control,
            piv_tx_data        => sv_SPI_tx_data,
            pov_rx_data        => sv_SPI_rx_data,
            pol_sclk           => sl_SPI_sclk,
            pol_sdo            => sl_SPI_sdo,
            pil_sdi            => sl_SPI_sdi,
            pol_nss            => sl_SPI_nss,
            pol_master_if      => sl_SPI_master_if
        );

    -----------------------------------------------------------------------------------------------------
    ------------------------------------------PWM MODULES------------------------------------------------
    -----------------------------------------------------------------------------------------------------

    stal_PWM_en(0) <= stav_pctrl_mem(ci_T1CON)(ctr_dct_con.i_TRAON);
    stal_PWM_en(1) <= stav_pctrl_mem(ci_T1CON)(ctr_dct_con.i_TRBON);
    stal_PWM_en(2) <= stav_pctrl_mem(ci_T2CON)(ctr_dct_con.i_TRAON);
    stal_PWM_en(3) <= stav_pctrl_mem(ci_T2CON)(ctr_dct_con.i_TRBON);
    stal_PWM_en(4) <= stav_pctrl_mem(ci_T3CON)(ctr_dct_con.i_TRAON);
    stal_PWM_en(5) <= stav_pctrl_mem(ci_T3CON)(ctr_dct_con.i_TRBON);

    stav_PWM_timer(0) <= stav_pctrl_mem(ci_T1BUFL)(11 downto 0);
    stav_PWM_timer(1) <= stav_pctrl_mem(ci_T1BUFH)(11 downto 0);
    stav_PWM_timer(2) <= stav_pctrl_mem(ci_T2BUFL)(11 downto 0);
    stav_PWM_timer(3) <= stav_pctrl_mem(ci_T2BUFH)(11 downto 0);
    stav_PWM_timer(4) <= stav_pctrl_mem(ci_T3BUFL)(11 downto 0);
    stav_PWM_timer(5) <= stav_pctrl_mem(ci_T3BUFH)(11 downto 0);

    stav_PWM_Hz(0) <= stav_pctrl_mem(ci_PWM0CON)(ctr_pwm_con.i_PWM_PR11 downto ctr_pwm_con.i_PWM_PR0);
    stav_PWM_Hz(1) <= stav_pctrl_mem(ci_PWM1CON)(ctr_pwm_con.i_PWM_PR11 downto ctr_pwm_con.i_PWM_PR0);
    stav_PWM_Hz(2) <= stav_pctrl_mem(ci_PWM2CON)(ctr_pwm_con.i_PWM_PR11 downto ctr_pwm_con.i_PWM_PR0);
    stav_PWM_Hz(3) <= stav_pctrl_mem(ci_PWM3CON)(ctr_pwm_con.i_PWM_PR11 downto ctr_pwm_con.i_PWM_PR0);
    stav_PWM_Hz(4) <= stav_pctrl_mem(ci_PWM4CON)(ctr_pwm_con.i_PWM_PR11 downto ctr_pwm_con.i_PWM_PR0);
    stav_PWM_Hz(5) <= stav_pctrl_mem(ci_PWM5CON)(ctr_pwm_con.i_PWM_PR11 downto ctr_pwm_con.i_PWM_PR0);

    stav_PWM_DC(0) <= stav_pctrl_mem(ci_PWM0DC)(11 downto 0);
    stav_PWM_DC(1) <= stav_pctrl_mem(ci_PWM1DC)(11 downto 0);
    stav_PWM_DC(2) <= stav_pctrl_mem(ci_PWM2DC)(11 downto 0);
    stav_PWM_DC(3) <= stav_pctrl_mem(ci_PWM3DC)(11 downto 0);
    stav_PWM_DC(4) <= stav_pctrl_mem(ci_PWM4DC)(11 downto 0);
    stav_PWM_DC(5) <= stav_pctrl_mem(ci_PWM5DC)(11 downto 0);

    gen_pwm_modules : for ii in 0 to 5 generate
        inst_pwm_module : entity work.pwm_module
            generic map(
                gi_pwm_resolution => 12
            )
            port map(
                pil_clk       => pil_clk,
                pil_rst       => pil_rst,
                pil_pwm_en    => stal_PWM_en(ii),
                piv_pwm_timer => stav_PWM_timer(ii),
                piv_pwm_Hz    => stav_PWM_Hz(ii),
                piv_pwm_dc    => stav_PWM_dc(ii),
                pol_pwm       => stal_PWM_out(ii)
            );
    end generate;

    pov_ioctrl_rdata <= sv_pctrl_data_out;
    pov_IRQ_src      <= sv_INT_src;
    pov_DDRA         <= sv_DDRA;
    pov_DDRB         <= sv_DDRB;

    gen_LATA : for ii in 0 to 15 generate
        pov_LATA(ii) <= stav_pctrl_mem(ci_ALTOUTA)(ii) when stav_pctrl_mem(ci_ALTOUTACON)(ii) = cl_ENABLE else sv_LATA(ii);
    end generate;

    gen_LATB : for ii in 0 to 15 generate
        pov_LATB(ii) <= stav_pctrl_mem(ci_ALTOUTB)(ii) when stav_pctrl_mem(ci_ALTOUTBCON)(ii) = cl_ENABLE else sv_LATB(ii);
    end generate;

    pov_LATD         <= sv_LATD;

end architecture;