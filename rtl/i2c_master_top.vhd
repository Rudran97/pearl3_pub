-----------------------------------------------------------------------------------------------------
--------------------------------------------I2C MASTER TOP-------------------------------------------
-----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.i2c_master_pkg.all;

entity i2c_master_top is
    port (
        pil_clk            : in std_logic;
        pil_rst            : in std_logic;
        piv_baud_rate      : in std_logic_vector(9 downto 0);
        piv_tot_rate       : in std_logic_vector(5 downto 0);
        piv_set_hold_rate  : in std_logic_vector(3 downto 0);
        piv_master_control : in std_logic_vector(6 downto 0);
        piv_tx_data        : in std_logic_vector(7 downto 0);
        pov_rx_data        : out std_logic_vector(7 downto 0);
        pil_ack            : in std_logic;
        pol_ack            : out std_logic;

        pil_scl    : in std_logic;
        pol_scl    : out std_logic;
        pol_scl_oe : out std_logic;
        pil_sda    : in std_logic;
        pol_sda    : out std_logic;
        pol_sda_oe : out std_logic;

        pol_master_if     : out std_logic;
        pol_master_bclf   : out std_logic;
        pol_master_bus_to : out std_logic;

        pol_I2C_done : out std_logic -- clears all enable signals except i2c interface enable
    );
end entity;

architecture rtl_master_top of i2c_master_top is

    type t_master_stage is (
        st_idle,
        st_master_enable,
        st_handle_start_cond,
        st_handle_stop_cond,
        st_handle_repstart_cond,
        st_handle_tx_data,
        st_handle_rx_data,
        st_handle_tx_ack,
        st_handle_rx_ack,
        st_wait_tx,
        st_wait_rx,
        st_done);
    signal st_master_stage : t_master_stage;

    signal sv_rx_data_buff : std_logic_vector(7 downto 0);
    signal sl_rx_ack       : std_logic;

    signal sl_scl    : std_logic;
    signal sl_scl_oe : std_logic;
    signal sl_sda    : std_logic;
    signal sl_sda_oe : std_logic;

    signal sl_master_if     : std_logic;
    signal sl_master_bclf   : std_logic;
    signal sl_master_bus_to : std_logic;

    signal sl_I2C_done : std_logic;

    signal si_bit_index_count : integer range 0 to 7;

    signal sl_brg_counter_en         : std_logic;
    signal sl_brg_counter_match_flag : std_logic;

    signal sl_set_hold_counter_en : std_logic;
    signal sl_set_hold_match_flag : std_logic;

    signal sl_tot_en         : std_logic;
    signal sl_tot_match_flag : std_logic;

    --- i2c master startbit ---
    signal sl_s_sen              : std_logic;
    signal sl_s_brg_pulse        : std_logic;
    signal sl_s_enable_brg_count : std_logic;
    signal sl_s_clr_sen          : std_logic;

    signal sl_s_scl_out : std_logic;
    signal sl_s_scl_oe  : std_logic;
    signal sl_s_sda_out : std_logic;
    signal sl_s_sda_oe  : std_logic;
    signal sl_s_if      : std_logic;
    signal sl_s_bclf    : std_logic;

    --- i2c master stopbit ---
    signal sl_p_pen              : std_logic;
    signal sl_p_brg_pulse        : std_logic;
    signal sl_p_enable_brg_count : std_logic;
    signal sl_p_clr_pen          : std_logic;

    signal sl_p_scl_out : std_logic;
    signal sl_p_scl_oe  : std_logic;
    signal sl_p_sda_out : std_logic;
    signal sl_p_sda_oe  : std_logic;
    signal sl_p_if      : std_logic;
    signal sl_p_bclf    : std_logic;

    --- i2c master repeated startbit ---
    signal sl_rs_rsen             : std_logic;
    signal sl_rs_brg_pulse        : std_logic;
    signal sl_rs_enable_brg_count : std_logic;
    signal sl_rs_clr_rsen         : std_logic;

    signal sl_rs_scl_out : std_logic;
    signal sl_rs_scl_oe  : std_logic;
    signal sl_rs_sda_out : std_logic;
    signal sl_rs_sda_oe  : std_logic;
    signal sl_rs_if      : std_logic;
    signal sl_rs_bclf    : std_logic;

    --- i2c master tx bit ---
    signal sl_tx_txen             : std_logic;
    signal sl_tx_brg_pulse        : std_logic;
    signal sl_tx_set_hold_pulse   : std_logic;
    signal sl_tx_data             : std_logic;
    signal sl_tx_enable_s_h_count : std_logic;
    signal sl_tx_enable_brg_count : std_logic;
    signal sl_tx_done             : std_logic;

    signal sl_tx_scl_out : std_logic;
    signal sl_tx_scl_oe  : std_logic;
    signal sl_tx_sda_out : std_logic;
    signal sl_tx_sda_oe  : std_logic;
    signal sl_tx_bclf    : std_logic;

    --- i2c master rx bit ---
    signal sl_rx_rxen             : std_logic;
    signal sl_rx_brg_pulse        : std_logic;
    signal sl_rx_data             : std_logic;
    signal sl_rx_enable_brg_count : std_logic;
    signal sl_rx_done             : std_logic;

    signal sl_rx_scl_out : std_logic;
    signal sl_rx_scl_oe  : std_logic;
    signal sl_rx_sda_oe  : std_logic;

    alias al_interface_enable : std_logic is piv_master_control(0);
    alias al_master_sen       : std_logic is piv_master_control(1);
    alias al_master_rsen      : std_logic is piv_master_control(2);
    alias al_master_pen       : std_logic is piv_master_control(3);
    alias al_master_txen      : std_logic is piv_master_control(4);
    alias al_master_rxen      : std_logic is piv_master_control(5);
    alias al_master_acken     : std_logic is piv_master_control(6);

    --- i2c master components ---

    component i2c_master_startbit is
        port (
            pil_clk              : in std_logic;
            pil_rst              : in std_logic;
            pil_sen              : in std_logic;
            pil_brg_pulse        : in std_logic;
            pol_enable_brg_count : out std_logic;
            pol_clr_sen          : out std_logic;

            pil_scl    : in std_logic;
            pol_scl    : out std_logic;
            pol_scl_oe : out std_logic;
            pil_sda    : in std_logic;
            pol_sda    : out std_logic;
            pol_sda_oe : out std_logic;

            pol_s_if   : out std_logic;
            pol_s_bclf : out std_logic
        );
    end component;

    component i2c_master_stopbit is
        port (
            pil_clk              : in std_logic;
            pil_rst              : in std_logic;
            pil_pen              : in std_logic;
            pil_brg_pulse        : in std_logic;
            pol_enable_brg_count : out std_logic;
            pol_clr_pen          : out std_logic;

            pil_scl    : in std_logic;
            pol_scl    : out std_logic;
            pol_scl_oe : out std_logic;
            pil_sda    : in std_logic;
            pol_sda    : out std_logic;
            pol_sda_oe : out std_logic;

            pol_p_if   : out std_logic;
            pol_p_bclf : out std_logic
        );
    end component;

    component i2c_master_repstartbit is
        port (
            pil_clk              : in std_logic;
            pil_rst              : in std_logic;
            pil_rsen             : in std_logic;
            pil_brg_pulse        : in std_logic;
            pol_enable_brg_count : out std_logic;
            pol_clr_rsen         : out std_logic;

            pil_scl    : in std_logic;
            pol_scl    : out std_logic;
            pol_scl_oe : out std_logic;
            pil_sda    : in std_logic;
            pol_sda    : out std_logic;
            pol_sda_oe : out std_logic;

            pol_rs_if   : out std_logic;
            pol_rs_bclf : out std_logic
        );
    end component;

    component i2c_master_tx_bit_handler is
        port (
            pil_clk            : in std_logic;
            pil_rst            : in std_logic;
            pil_txen           : in std_logic;
            pil_brg_pulse      : in std_logic;
            pil_set_hold_pulse : in std_logic;

            pil_tx_data : in std_logic;

            pol_enable_s_h_count : out std_logic;
            pol_enable_brg_count : out std_logic;

            pol_tx_done : out std_logic;

            pil_scl    : in std_logic;
            pol_scl    : out std_logic;
            pol_scl_oe : out std_logic;
            pil_sda    : in std_logic;
            pol_sda    : out std_logic;
            pol_sda_oe : out std_logic;

            pol_tx_bclf : out std_logic
        );
    end component;

    component i2c_master_rx_bit_handler is
        port (
            pil_clk       : in std_logic;
            pil_rst       : in std_logic;
            pil_rxen      : in std_logic;
            pil_brg_pulse : in std_logic;

            pol_rx_data : out std_logic;

            pol_enable_brg_count : out std_logic;
            pol_rx_done          : out std_logic;

            pil_scl    : in std_logic;
            pol_scl    : out std_logic;
            pol_scl_oe : out std_logic;
            pil_sda    : in std_logic;
            pol_sda_oe : out std_logic
        );
    end component;

begin

    proc_master_controller : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sv_rx_data_buff    <= (others => '0');
            sl_rx_ack          <= '0';
            sl_s_sen           <= '0';
            sl_p_pen           <= '0';
            sl_rs_rsen         <= '0';
            sl_tx_txen         <= '0';
            sl_tx_data         <= '0';
            sl_rx_rxen         <= '0';
            sl_scl             <= '1';
            sl_scl_oe          <= '0';
            sl_sda             <= '1';
            sl_sda_oe          <= '0';
            sl_master_if       <= '0';
            sl_master_bclf     <= '0';
            sl_master_bus_to   <= '0';
            sl_brg_counter_en  <= '0';
            sl_I2C_done        <= '0';
            sl_tot_en          <= '0';
            si_bit_index_count <= 0;
            st_master_stage    <= st_idle;
        elsif rising_edge(pil_clk) then
            case st_master_stage is
                when st_idle =>
                    sl_master_if     <= '0';
                    sl_master_bclf   <= '0';
                    sl_master_bus_to <= '0';
                    sl_I2C_done      <= '0';
                    sl_scl_oe        <= '0';
                    sl_sda_oe        <= '0';
                    if al_interface_enable = '1' then
                        st_master_stage <= st_master_enable;
                    end if;
                when st_master_enable =>
                    sl_I2C_done <= '0';
                    if al_interface_enable = '1' then
                        if al_master_sen = '1' then
                            st_master_stage <= st_handle_start_cond;
                        elsif al_master_rsen = '1' then
                            st_master_stage <= st_handle_repstart_cond;
                        elsif al_master_pen = '1' then
                            st_master_stage <= st_handle_stop_cond;
                        elsif al_master_txen = '1' then
                            st_master_stage <= st_handle_tx_data;
                        elsif al_master_rxen = '1' then
                            st_master_stage <= st_handle_rx_data;
                        elsif al_master_acken = '1' then
                            st_master_stage <= st_handle_tx_ack;
                        end if;
                    else
                        st_master_stage <= st_idle;
                    end if;
                when st_handle_start_cond =>
                    sl_tot_en <= '1';
                    if sl_tot_match_flag = '0' then
                        sl_s_sen          <= '1';
                        sl_scl            <= sl_s_scl_out;
                        sl_scl_oe         <= sl_s_scl_oe;
                        sl_sda            <= sl_s_sda_out;
                        sl_sda_oe         <= sl_s_sda_oe;
                        sl_brg_counter_en <= sl_s_enable_brg_count;
                        if sl_s_clr_sen = '1' then
                            sl_master_if    <= sl_s_if;
                            sl_master_bclf  <= sl_s_bclf;
                            sl_s_sen        <= '0';
                            sl_tot_en       <= '0';
                            st_master_stage <= st_done;
                        end if;
                    else
                        sl_master_bus_to <= '1';
                        sl_tot_en        <= '0';
                        st_master_stage  <= st_done;
                    end if;
                when st_handle_stop_cond =>
                    sl_tot_en <= '1';
                    if sl_tot_match_flag = '0' then
                        sl_p_pen          <= '1';
                        sl_scl            <= sl_p_scl_out;
                        sl_scl_oe         <= sl_p_scl_oe;
                        sl_sda            <= sl_p_sda_out;
                        sl_sda_oe         <= sl_p_sda_oe;
                        sl_brg_counter_en <= sl_p_enable_brg_count;
                        if sl_p_clr_pen = '1' then
                            sl_master_if    <= sl_p_if;
                            sl_master_bclf  <= sl_p_bclf;
                            sl_p_pen        <= '0';
                            sl_tot_en       <= '0';
                            st_master_stage <= st_done;
                        end if;
                    else
                        sl_master_bus_to <= '1';
                        sl_tot_en        <= '0';
                        st_master_stage  <= st_done;
                    end if;
                when st_handle_repstart_cond =>
                    sl_tot_en <= '1';
                    if sl_tot_match_flag = '0' then
                        sl_rs_rsen        <= '1';
                        sl_scl            <= sl_rs_scl_out;
                        sl_scl_oe         <= sl_rs_scl_oe;
                        sl_sda            <= sl_rs_sda_out;
                        sl_sda_oe         <= sl_rs_sda_oe;
                        sl_brg_counter_en <= sl_rs_enable_brg_count;
                        if sl_rs_clr_rsen = '1' then
                            sl_master_if    <= sl_rs_if;
                            sl_master_bclf  <= sl_rs_bclf;
                            sl_rs_rsen      <= '0';
                            sl_tot_en       <= '0';
                            st_master_stage <= st_done;
                        end if;
                    else
                        sl_master_bus_to <= '1';
                        sl_tot_en        <= '0';
                        st_master_stage  <= st_done;
                    end if;
                when st_handle_tx_data =>
                    sl_tot_en <= '1';
                    if sl_tot_match_flag = '0' then
                        sl_tx_txen        <= '1';
                        sl_tx_data        <= piv_tx_data(7 - si_bit_index_count);
                        sl_scl            <= sl_tx_scl_out;
                        sl_scl_oe         <= sl_tx_scl_oe;
                        sl_sda            <= sl_tx_sda_out;
                        sl_sda_oe         <= sl_tx_sda_oe;
                        sl_brg_counter_en <= sl_tx_enable_brg_count;
                        if sl_tx_done = '1' then
                            sl_tx_txen     <= '0';
                            sl_tot_en      <= '0';
                            sl_master_bclf <= sl_tx_bclf;
                            if sl_tx_bclf = '0' then
                                if si_bit_index_count < 7 then
                                    si_bit_index_count <= si_bit_index_count + 1;
                                    st_master_stage    <= st_wait_tx;
                                else
                                    si_bit_index_count <= 0;
                                    st_master_stage    <= st_handle_rx_ack;
                                end if;
                            else
                                st_master_stage <= st_done;
                            end if;
                        end if;
                    else
                        sl_master_bus_to <= '1';
                        sl_tot_en        <= '0';
                        st_master_stage  <= st_done;
                    end if;
                when st_handle_rx_data =>
                    sl_tot_en <= '1';
                    if sl_tot_match_flag = '0' then
                        sl_rx_rxen        <= '1';
                        sl_scl            <= sl_rx_scl_out;
                        sl_scl_oe         <= sl_rx_scl_oe;
                        sl_sda_oe         <= sl_rx_sda_oe;
                        sl_brg_counter_en <= sl_rx_enable_brg_count;
                        if sl_rx_done = '1' then
                            sl_rx_rxen                              <= '0';
                            sl_tot_en                               <= '0';
                            sv_rx_data_buff(7 - si_bit_index_count) <= sl_rx_data;
                            if si_bit_index_count < 7 then
                                si_bit_index_count <= si_bit_index_count + 1;
                                st_master_stage    <= st_wait_rx;
                            else
                                si_bit_index_count <= 0;
                                sl_master_if       <= '1';
                                st_master_stage    <= st_done;
                            end if;
                        end if;
                    else
                        sl_master_bus_to <= '1';
                        sl_tot_en        <= '0';
                        st_master_stage  <= st_done;
                    end if;
                when st_handle_tx_ack =>
                    sl_tot_en <= '1';
                    if sl_tot_match_flag = '0' then
                        sl_tx_txen        <= '1';
                        sl_tx_data        <= pil_ack;
                        sl_scl            <= sl_tx_scl_out;
                        sl_scl_oe         <= sl_tx_scl_oe;
                        sl_sda            <= sl_tx_sda_out;
                        sl_sda_oe         <= sl_tx_sda_oe;
                        sl_brg_counter_en <= sl_tx_enable_brg_count;
                        if sl_tx_done = '1' then
                            sl_master_if    <= not sl_tx_bclf;
                            sl_master_bclf  <= sl_tx_bclf;
                            sl_tx_txen      <= '0';
                            sl_tot_en       <= '0';
                            st_master_stage <= st_done;
                        end if;
                    else
                        sl_master_bus_to <= '1';
                        sl_tot_en        <= '0';
                        st_master_stage  <= st_done;
                    end if;
                when st_handle_rx_ack =>
                    sl_tot_en <= '0';
                    if sl_tot_match_flag = '0' then
                        sl_rx_rxen        <= '1';
                        sl_scl            <= sl_rx_scl_out;
                        sl_scl_oe         <= sl_rx_scl_oe;
                        sl_sda_oe         <= sl_rx_sda_oe;
                        sl_brg_counter_en <= sl_rx_enable_brg_count;
                        if sl_rx_done = '1' then
                            sl_master_if    <= '1';
                            sl_rx_rxen      <= '0';
                            sl_tot_en       <= '0';
                            sl_rx_ack       <= sl_rx_data;
                            st_master_stage <= st_done;
                        end if;
                    else
                        sl_master_bus_to <= '1';
                        sl_tot_en        <= '0';
                        st_master_stage  <= st_done;
                    end if;
                when st_wait_tx =>
                    if sl_tx_done = '0' then
                        st_master_stage <= st_handle_tx_data;
                    end if;
                when st_wait_rx =>
                    if sl_rx_done = '0' then
                        st_master_stage <= st_handle_rx_data;
                    end if;
                when st_done =>
                    sl_I2C_done <= '1';
                    if piv_master_control(6 downto 1) = "000000" then
                        sl_master_if     <= '0';
                        sl_master_bclf   <= '0';
                        sl_master_bus_to <= '0';
                        st_master_stage  <= st_master_enable;
                    end if;
            end case;
        end if;
    end process proc_master_controller;

    -----------------------------------------------------------------------------------------------------
    ------------------------------------------BAUD RATE GENERATOR----------------------------------------
    -----------------------------------------------------------------------------------------------------

    inst_baud_rate_generator : entity work.counter
        generic map(
            gi_counter_width => 10,
            gi_clksrc_div    => ci_clksrc_div
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            piv_counter_control     => '1' & sl_brg_counter_en,
            piv_counter_prescale => (others => '0'),
            piv_counter_match_value => piv_baud_rate,
            pov_counter_value       => open,
            pol_counter_match_flag  => sl_brg_counter_match_flag
        );

    sl_set_hold_counter_en <= sl_tx_enable_s_h_count;

    inst_set_and_hold_time : entity work.counter
        generic map(
            gi_counter_width => 8,
            gi_clksrc_div    => ci_clksrc_div
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            piv_counter_control     => '1' & sl_set_hold_counter_en,
            piv_counter_prescale => (others => '0'),
            piv_counter_match_value => piv_set_hold_rate & "0000",
            pov_counter_value       => open,
            pol_counter_match_flag  => sl_set_hold_match_flag
        );

    inst_bus_time_out_timer : entity work.counter
        generic map(
            gi_counter_width => 10,
            gi_clksrc_div    => ci_clksrc_div
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            piv_counter_control     => '1' & sl_tot_en,
            piv_counter_prescale    => "1111101000", --- 1000
            piv_counter_match_value => piv_tot_rate & "0000",
            pov_counter_value       => open,
            pol_counter_match_flag  => sl_tot_match_flag
        );

    -----------------------------------------------------------------------------------------------------
    -----------------------------------------I2C MASTER COMPONENTS---------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_s_brg_pulse <= sl_brg_counter_match_flag;

    inst_i2c_master_startbit : i2c_master_startbit
    port map(
        pil_clk              => pil_clk,
        pil_rst              => pil_rst,
        pil_sen              => sl_s_sen,
        pil_brg_pulse        => sl_s_brg_pulse,
        pol_enable_brg_count => sl_s_enable_brg_count,
        pol_clr_sen          => sl_s_clr_sen,
        pil_scl              => pil_scl,
        pol_scl              => sl_s_scl_out,
        pol_scl_oe           => sl_s_scl_oe,
        pil_sda              => pil_sda,
        pol_sda              => sl_s_sda_out,
        pol_sda_oe           => sl_s_sda_oe,
        pol_s_if             => sl_s_if,
        pol_s_bclf           => sl_s_bclf
    );

    sl_p_brg_pulse <= sl_brg_counter_match_flag;

    inst_i2c_master_stopbit : i2c_master_stopbit
    port map(
        pil_clk              => pil_clk,
        pil_rst              => pil_rst,
        pil_pen              => sl_p_pen,
        pil_brg_pulse        => sl_p_brg_pulse,
        pol_enable_brg_count => sl_p_enable_brg_count,
        pol_clr_pen          => sl_p_clr_pen,
        pil_scl              => pil_scl,
        pol_scl              => sl_p_scl_out,
        pol_scl_oe           => sl_p_scl_oe,
        pil_sda              => pil_sda,
        pol_sda              => sl_p_sda_out,
        pol_sda_oe           => sl_p_sda_oe,
        pol_p_if             => sl_p_if,
        pol_p_bclf           => sl_p_bclf
    );

    sl_rs_brg_pulse <= sl_brg_counter_match_flag;

    inst_i2c_master_repstartbit : i2c_master_repstartbit
    port map(
        pil_clk              => pil_clk,
        pil_rst              => pil_rst,
        pil_rsen             => sl_rs_rsen,
        pil_brg_pulse        => sl_rs_brg_pulse,
        pol_enable_brg_count => sl_rs_enable_brg_count,
        pol_clr_rsen         => sl_rs_clr_rsen,
        pil_scl              => pil_scl,
        pol_scl              => sl_rs_scl_out,
        pol_scl_oe           => sl_rs_scl_oe,
        pil_sda              => pil_sda,
        pol_sda              => sl_rs_sda_out,
        pol_sda_oe           => sl_rs_sda_oe,
        pol_rs_if            => sl_rs_if,
        pol_rs_bclf          => sl_rs_bclf
    );

    sl_tx_set_hold_pulse <= sl_set_hold_match_flag;
    sl_tx_brg_pulse      <= sl_brg_counter_match_flag;

    inst_i2c_master_tx_bit_handler : i2c_master_tx_bit_handler
    port map(
        pil_clk              => pil_clk,
        pil_rst              => pil_rst,
        pil_txen             => sl_tx_txen,
        pil_brg_pulse        => sl_tx_brg_pulse,
        pil_set_hold_pulse   => sl_tx_set_hold_pulse,
        pil_tx_data          => sl_tx_data,
        pol_enable_s_h_count => sl_tx_enable_s_h_count,
        pol_enable_brg_count => sl_tx_enable_brg_count,
        pol_tx_done          => sl_tx_done,
        pil_scl              => pil_scl,
        pol_scl              => sl_tx_scl_out,
        pol_scl_oe           => sl_tx_scl_oe,
        pil_sda              => pil_sda,
        pol_sda              => sl_tx_sda_out,
        pol_sda_oe           => sl_tx_sda_oe,
        pol_tx_bclf          => sl_tx_bclf
    );

    sl_rx_brg_pulse <= sl_brg_counter_match_flag;

    inst_i2c_master_rx_bit_handler : i2c_master_rx_bit_handler
    port map(
        pil_clk              => pil_clk,
        pil_rst              => pil_rst,
        pil_rxen             => sl_rx_rxen,
        pil_brg_pulse        => sl_rx_brg_pulse,
        pol_rx_data          => sl_rx_data,
        pol_enable_brg_count => sl_rx_enable_brg_count,
        pol_rx_done          => sl_rx_done,
        pil_scl              => pil_scl,
        pol_scl              => sl_rx_scl_out,
        pol_scl_oe           => sl_rx_scl_oe,
        pil_sda              => pil_sda,
        pol_sda_oe           => sl_rx_sda_oe
    );

    pov_rx_data <= sv_rx_data_buff;

    pol_ack <= sl_rx_ack;

    pol_scl    <= sl_scl;
    pol_scl_oe <= sl_scl_oe;
    pol_sda    <= sl_sda;
    pol_sda_oe <= sl_sda_oe;

    pol_master_if     <= sl_master_if;
    pol_master_bclf   <= sl_master_bclf;
    pol_master_bus_to <= sl_master_bus_to;

    pol_I2C_done <= sl_I2C_done;

end architecture;

-----------------------------------------------------------------------------------------------------
----------------------------------------------START BIT----------------------------------------------
-----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master_startbit is
    port (
        pil_clk              : in std_logic;
        pil_rst              : in std_logic;
        pil_sen              : in std_logic;
        pil_brg_pulse        : in std_logic;
        pol_enable_brg_count : out std_logic;
        pol_clr_sen          : out std_logic;

        pil_scl    : in std_logic;
        pol_scl    : out std_logic;
        pol_scl_oe : out std_logic;
        pil_sda    : in std_logic;
        pol_sda    : out std_logic;
        pol_sda_oe : out std_logic;

        pol_s_if   : out std_logic;
        pol_s_bclf : out std_logic
    );
end entity;

architecture rtl_startbit of i2c_master_startbit is

    type t_collision_detect is (st_at_start, st_at_count, st_done);
    signal st_col_detect : t_collision_detect;

    type t_gen_start is (st_idle, st_sda_set, st_scl_set, st_done);
    signal st_gen_start : t_gen_start;

    signal sl_bclf                 : std_logic;
    signal sl_bus_arbitration_flag : std_logic;

    signal sl_start_if : std_logic;

    signal sl_brg_count_en : std_logic;
    signal sl_clr_sen      : std_logic;

    signal sl_scl_out : std_logic;
    signal sl_scl_oe  : std_logic;

    signal sl_sda_out : std_logic;
    signal sl_sda_oe  : std_logic;

begin

    proc_detect_bus_collision : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_bclf                 <= '0';
            sl_bus_arbitration_flag <= '0';
            st_col_detect           <= st_at_start;
        elsif rising_edge(pil_clk) then
            case st_col_detect is
                when st_at_start =>
                    sl_bus_arbitration_flag <= '0';
                    sl_bclf                 <= '0';
                    if pil_sen = '1' then
                        if pil_scl = '0' or pil_sda = '0' then
                            sl_bclf       <= '1';
                            st_col_detect <= st_done;
                        else
                            st_col_detect <= st_at_count;
                        end if;
                    end if;
                when st_at_count =>
                    if pil_sen = '1' then
                        if pil_brg_pulse = '0' then
                            if pil_scl = '0' and pil_sda = '1' then
                                sl_bclf       <= '1';
                                st_col_detect <= st_done;
                            end if;
                            if pil_sda = '0' then           -- if sda is pulled low by another master before the end of the end of baud period
                                sl_bus_arbitration_flag <= '1'; -- bus arbitration flag is set
                                st_col_detect           <= st_done;
                            end if;
                        else
                            st_col_detect <= st_done;
                        end if;
                    else
                        st_col_detect <= st_done;
                    end if;
                when st_done =>
                    if pil_sen = '0' then
                        st_col_detect <= st_at_start;
                    end if;
            end case;
        end if;
    end process proc_detect_bus_collision;

    proc_gen_start_cond : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_start_if     <= '0';
            sl_clr_sen      <= '0';
            sl_brg_count_en <= '0';
            sl_scl_out      <= '1';
            sl_scl_oe       <= '0';
            sl_sda_out      <= '1';
            sl_sda_oe       <= '0';
            st_gen_start    <= st_idle;
        elsif rising_edge(pil_clk) then
            case st_gen_start is
                when st_idle =>
                    sl_scl_oe   <= '0';
                    sl_sda_oe   <= '0';
                    sl_start_if <= '0';
                    sl_clr_sen  <= '0';
                    if pil_sen = '1' then
                        st_gen_start <= st_sda_set;
                    end if;
                when st_sda_set =>
                    if sl_bclf = '0' then
                        sl_brg_count_en <= '1';
                        if sl_bus_arbitration_flag = '1' or pil_brg_pulse = '1' then
                            sl_brg_count_en <= '0';
                            sl_sda_out      <= '0';
                            sl_sda_oe       <= '1';
                            st_gen_start    <= st_scl_set;
                        end if;
                    else
                        st_gen_start <= st_done;
                    end if;
                when st_scl_set =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_brg_count_en <= '0';
                        sl_scl_out      <= '0';
                        sl_scl_oe       <= '1';
                        sl_start_if     <= '1';
                        st_gen_start    <= st_done;
                    end if;
                when st_done =>
                    sl_brg_count_en <= '0';
                    sl_clr_sen      <= '1';
                    if pil_sen = '0' then
                        st_gen_start <= st_idle;
                    end if;
            end case;
        end if;
    end process proc_gen_start_cond;

    pol_enable_brg_count <= sl_brg_count_en;
    pol_clr_sen          <= sl_clr_sen;

    pol_scl    <= sl_scl_out;
    pol_scl_oe <= sl_scl_oe;
    pol_sda    <= sl_sda_out;
    pol_sda_oe <= sl_sda_oe;

    pol_s_bclf <= sl_bclf;
    pol_s_if   <= sl_start_if;

end architecture;

-----------------------------------------------------------------------------------------------------
-----------------------------------------------STOP BIT----------------------------------------------
-----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master_stopbit is
    port (
        pil_clk              : in std_logic;
        pil_rst              : in std_logic;
        pil_pen              : in std_logic;
        pil_brg_pulse        : in std_logic;
        pol_enable_brg_count : out std_logic;
        pol_clr_pen          : out std_logic;

        pil_scl    : in std_logic;
        pol_scl    : out std_logic;
        pol_scl_oe : out std_logic;
        pil_sda    : in std_logic;
        pol_sda    : out std_logic;
        pol_sda_oe : out std_logic;

        pol_p_if   : out std_logic;
        pol_p_bclf : out std_logic
    );
end entity;

architecture rtl_stopbit of i2c_master_stopbit is

    type t_collision_detect is (st_sda_assertion_detect, st_scl_float_high_detect, st_sda_float_high_detect, st_stop_bit_end);
    signal st_col_detect : t_collision_detect;

    type t_gen_stop is (st_idle, st_release_scl, st_release_sda, st_stop_bit_end, st_done);
    signal st_gen_stop : t_gen_stop;

    signal sl_save_bclf : std_logic;
    signal sl_bclf      : std_logic;

    signal sl_stop_if : std_logic;

    signal sl_brg_count_en : std_logic;
    signal sl_clr_pen      : std_logic;

    signal sl_scl_out : std_logic;
    signal sl_scl_oe  : std_logic;

    signal sl_sda_out : std_logic;
    signal sl_sda_oe  : std_logic;

begin

    proc_detect_bus_collision : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_save_bclf  <= '0';
            sl_bclf       <= '0';
            st_col_detect <= st_sda_assertion_detect;
        elsif rising_edge(pil_clk) then
            case st_col_detect is
                when st_sda_assertion_detect =>
                    sl_save_bclf <= '0';
                    sl_bclf      <= '0';
                    if pil_pen = '1' then
                        if pil_brg_pulse = '1' then
                            if pil_sda = '0' then
                                st_col_detect <= st_scl_float_high_detect;
                            else
                                sl_save_bclf  <= '1';
                                st_col_detect <= st_stop_bit_end;
                            end if;
                        end if;
                    end if;
                when st_scl_float_high_detect =>
                    if pil_pen = '1' then
                        if pil_brg_pulse = '1' then
                            if pil_scl = '1' then
                                st_col_detect <= st_sda_float_high_detect;
                            else
                                sl_save_bclf  <= '1';
                                st_col_detect <= st_stop_bit_end;
                            end if;
                        end if;
                    else
                        st_col_detect <= st_stop_bit_end;
                    end if;
                when st_sda_float_high_detect =>
                    if pil_pen = '1' then
                        if pil_brg_pulse = '1' then
                            if pil_sda = '0' then
                                sl_save_bclf <= '1';
                            end if;
                            st_col_detect <= st_stop_bit_end;
                        end if;
                    else
                        st_col_detect <= st_stop_bit_end;
                    end if;
                when st_stop_bit_end =>
                    if pil_pen = '0' then
                        sl_bclf       <= sl_save_bclf;
                        st_col_detect <= st_sda_assertion_detect;
                    end if;
            end case;
        end if;
    end process proc_detect_bus_collision;

    proc_gen_stop_cond : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_stop_if      <= '0';
            sl_clr_pen      <= '0';
            sl_brg_count_en <= '0';
            sl_scl_out      <= '1';
            sl_scl_oe       <= '0';
            sl_sda_out      <= '1';
            sl_sda_oe       <= '0';
            st_gen_stop     <= st_idle;
        elsif rising_edge(pil_clk) then
            case st_gen_stop is
                when st_idle =>
                    sl_scl_oe  <= '1';
                    sl_scl_out <= '0';
                    sl_sda_oe  <= '0';
                    sl_stop_if <= '0';
                    sl_clr_pen <= '0';
                    if pil_pen = '1' then
                        sl_brg_count_en <= '1';
                        sl_sda_out      <= '0';
                        sl_sda_oe       <= '1';
                        st_gen_stop     <= st_release_scl;
                    end if;
                when st_release_scl =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_brg_count_en <= '0';
                        sl_scl_oe       <= '0';
                        st_gen_stop     <= st_release_sda;
                    end if;
                when st_release_sda =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_brg_count_en <= '0';
                        sl_sda_oe       <= '0';
                        st_gen_stop     <= st_stop_bit_end;
                    end if;
                when st_stop_bit_end =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_brg_count_en <= '0';
                        st_gen_stop     <= st_done;
                    end if;
                when st_done =>
                    sl_clr_pen <= '1';
                    if sl_save_bclf = '0' then
                        sl_stop_if <= '1';
                    end if;
                    if pil_pen = '0' then
                        st_gen_stop <= st_idle;
                    end if;
            end case;
        end if;
    end process proc_gen_stop_cond;

    pol_enable_brg_count <= sl_brg_count_en;
    pol_clr_pen          <= sl_clr_pen;

    pol_scl    <= sl_scl_out;
    pol_scl_oe <= sl_scl_oe;
    pol_sda    <= sl_sda_out;
    pol_sda_oe <= sl_sda_oe;

    pol_p_bclf <= sl_bclf;
    pol_p_if   <= sl_stop_if;

end architecture;

-----------------------------------------------------------------------------------------------------
------------------------------------------REPEATED START BIT-----------------------------------------
-----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master_repstartbit is
    port (
        pil_clk              : in std_logic;
        pil_rst              : in std_logic;
        pil_rsen             : in std_logic;
        pil_brg_pulse        : in std_logic;
        pol_enable_brg_count : out std_logic;
        pol_clr_rsen         : out std_logic;

        pil_scl    : in std_logic;
        pol_scl    : out std_logic;
        pol_scl_oe : out std_logic;
        pil_sda    : in std_logic;
        pol_sda    : out std_logic;
        pol_sda_oe : out std_logic;

        pol_rs_if   : out std_logic;
        pol_rs_bclf : out std_logic
    );
end entity;

architecture rtl_repstartbit of i2c_master_repstartbit is

    type t_collision_detect is (st_sda_assert_wait, st_sda_assert_detect, st_scl_at_count, st_done);
    signal st_col_detect : t_collision_detect;

    type t_gen_rep_start is (st_idle, st_deassert_scl, st_sda_set, st_scl_set, st_done);
    signal st_gen_rep_start : t_gen_rep_start;

    signal sl_bclf : std_logic;

    signal sl_rs_if : std_logic;

    signal sl_brg_count_en : std_logic;
    signal sl_clr_rsen     : std_logic;

    signal sl_scl_out : std_logic;
    signal sl_scl_oe  : std_logic;

    signal sl_sda_out : std_logic;
    signal sl_sda_oe  : std_logic;

begin

    proc_detect_bus_collision : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_bclf       <= '0';
            st_col_detect <= st_sda_assert_wait;
        elsif rising_edge(pil_clk) then
            case st_col_detect is
                when st_sda_assert_wait =>
                    sl_bclf <= '0';
                    if pil_rsen = '1' then
                        if pil_brg_pulse = '1' then
                            st_col_detect <= st_sda_assert_detect;
                        end if;
                    end if;
                when st_sda_assert_detect =>
                    if pil_rsen = '1' then
                        if pil_scl = '1' then
                            if pil_sda = '1' then
                                st_col_detect <= st_scl_at_count;
                            else
                                sl_bclf       <= '1';
                                st_col_detect <= st_done;
                            end if;
                        end if;
                    else
                        st_col_detect <= st_done;
                    end if;
                when st_scl_at_count =>
                    if pil_rsen = '1' then
                        if pil_brg_pulse = '0' then
                            if pil_scl = '0' then
                                sl_bclf       <= '1';
                                st_col_detect <= st_done;
                            end if;
                        else
                            st_col_detect <= st_done;
                        end if;
                    else
                        st_col_detect <= st_done;
                    end if;
                when st_done =>
                    if pil_rsen = '0' then
                        st_col_detect <= st_sda_assert_wait;
                    end if;
            end case;
        end if;
    end process proc_detect_bus_collision;

    proc_gen_rep_start_cond : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_rs_if         <= '0';
            sl_clr_rsen      <= '0';
            sl_brg_count_en  <= '0';
            sl_scl_out       <= '0';
            sl_scl_oe        <= '0';
            sl_sda_out       <= '0';
            sl_sda_oe        <= '0';
            st_gen_rep_start <= st_idle;
        elsif rising_edge(pil_clk) then
            case st_gen_rep_start is
                when st_idle =>
                    sl_scl_oe   <= '1';
                    sl_scl_out  <= '0';
                    sl_sda_oe   <= '1';
                    sl_sda_out  <= pil_sda;
                    sl_rs_if    <= '0';
                    sl_clr_rsen <= '0';
                    if pil_rsen = '1' then
                        sl_brg_count_en  <= '1';
                        sl_sda_oe        <= '0';
                        st_gen_rep_start <= st_deassert_scl;
                    end if;
                when st_deassert_scl =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_brg_count_en  <= '0';
                        sl_scl_oe        <= '0';
                        st_gen_rep_start <= st_sda_set;
                    end if;
                when st_sda_set =>
                    if sl_bclf = '0' then
                        sl_brg_count_en <= '1';
                        if pil_brg_pulse = '1' then
                            sl_brg_count_en  <= '0';
                            sl_sda_out       <= '0';
                            sl_sda_oe        <= '1';
                            st_gen_rep_start <= st_scl_set;
                        end if;
                    else
                        st_gen_rep_start <= st_done;
                    end if;
                when st_scl_set =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_brg_count_en  <= '0';
                        sl_scl_out       <= '0';
                        sl_scl_oe        <= '1';
                        sl_rs_if         <= '1';
                        st_gen_rep_start <= st_done;
                    end if;
                when st_done =>
                    sl_brg_count_en <= '0';
                    sl_clr_rsen     <= '1';
                    if pil_rsen = '0' then
                        st_gen_rep_start <= st_idle;
                    end if;
            end case;
        end if;
    end process proc_gen_rep_start_cond;

    pol_enable_brg_count <= sl_brg_count_en;
    pol_clr_rsen         <= sl_clr_rsen;

    pol_scl    <= sl_scl_out;
    pol_scl_oe <= sl_scl_oe;
    pol_sda    <= sl_sda_out;
    pol_sda_oe <= sl_sda_oe;

    pol_rs_bclf <= sl_bclf;
    pol_rs_if   <= sl_rs_if;

end architecture;

-----------------------------------------------------------------------------------------------------
--------------------------------------------TX BIT HANDLER-------------------------------------------
-----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master_tx_bit_handler is
    port (
        pil_clk            : in std_logic;
        pil_rst            : in std_logic;
        pil_txen           : in std_logic;
        pil_brg_pulse      : in std_logic;
        pil_set_hold_pulse : in std_logic;

        pil_tx_data : in std_logic;

        pol_enable_s_h_count : out std_logic;
        pol_enable_brg_count : out std_logic;

        pol_tx_done : out std_logic;

        pil_scl    : in std_logic;
        pol_scl    : out std_logic;
        pol_scl_oe : out std_logic;
        pil_sda    : in std_logic;
        pol_sda    : out std_logic;
        pol_sda_oe : out std_logic;

        pol_tx_bclf : out std_logic
    );
end entity;

architecture rtl_tx_bit_handler of i2c_master_tx_bit_handler is

    type t_collision_detect is (st_idle, st_at_scl_high, st_done);
    signal st_col_detect : t_collision_detect;

    type t_tx_bit is (st_idle, st_scl_hold_low, st_scl_high, st_data_hold, st_done);
    signal st_tx_bit : t_tx_bit;

    signal sl_bclf : std_logic;

    signal sl_tx_done : std_logic;

    signal sl_brg_count_en : std_logic;
    signal sl_s_h_count_en : std_logic;

    signal sl_scl_out : std_logic;
    signal sl_scl_oe  : std_logic;

    signal sl_sda_out : std_logic;
    signal sl_sda_oe  : std_logic;

begin

    proc_detect_bus_collision : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_bclf       <= '0';
            st_col_detect <= st_idle;
        elsif rising_edge(pil_clk) then
            case st_col_detect is
                when st_idle =>
                    sl_bclf <= '0';
                    if pil_txen = '1' then
                        if pil_brg_pulse = '1' then
                            st_col_detect <= st_at_scl_high;
                        end if;
                    end if;
                when st_at_scl_high =>
                    if pil_txen = '1' then
                        if pil_brg_pulse = '0' then
                            if sl_scl_oe = '0' and pil_scl = '1' then
                                if pil_sda /= sl_sda_out then
                                    sl_bclf       <= '1';
                                    st_col_detect <= st_done;
                                end if;
                            end if;
                        else
                            st_col_detect <= st_done;
                        end if;
                    else
                        st_col_detect <= st_done;
                    end if;
                when st_done =>
                    if pil_txen = '0' then
                        st_col_detect <= st_idle;
                    end if;
            end case;
        end if;
    end process proc_detect_bus_collision;

    proc_tx_bit : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_tx_done      <= '0';
            sl_brg_count_en <= '0';
            sl_s_h_count_en <= '0';
            sl_scl_out      <= '0';
            sl_scl_oe       <= '1';
            sl_sda_out      <= '0';
            sl_sda_oe       <= '1';
            st_tx_bit       <= st_idle;
        elsif rising_edge(pil_clk) then
            case st_tx_bit is
                when st_idle =>
                    sl_scl_oe  <= '1';
                    sl_sda_oe  <= '1';
                    sl_sda_out <= pil_sda;
                    sl_tx_done <= '0';
                    if pil_txen = '1' then
                        sl_sda_out <= pil_tx_data;
                        sl_sda_oe  <= '1';
                        sl_scl_out <= '0';
                        sl_scl_oe  <= '1';
                        st_tx_bit  <= st_scl_hold_low;
                    end if;
                when st_scl_hold_low =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_brg_count_en <= '0';
                        sl_scl_oe       <= '0';
                        st_tx_bit       <= st_scl_high;
                    end if;
                when st_scl_high =>
                    if sl_bclf = '0' then
                        sl_brg_count_en <= '1';
                        if pil_brg_pulse = '1' then
                            sl_brg_count_en <= '0';
                            sl_scl_out      <= '0';
                            sl_scl_oe       <= '1';
                            st_tx_bit       <= st_data_hold;
                        end if;
                    else
                        sl_scl_oe <= '0';
                        sl_sda_oe <= '0';
                        st_tx_bit <= st_done;
                    end if;
                when st_data_hold =>
                    sl_s_h_count_en <= '1';
                    if pil_set_hold_pulse = '1' then
                        sl_s_h_count_en <= '0';
                        st_tx_bit       <= st_done;
                    end if;
                when st_done =>
                    sl_brg_count_en <= '0';
                    sl_s_h_count_en <= '0';
                    sl_tx_done      <= '1';
                    if pil_txen = '0' then
                        st_tx_bit <= st_idle;
                    end if;
            end case;
        end if;
    end process proc_tx_bit;

    pol_enable_s_h_count <= sl_s_h_count_en;
    pol_enable_brg_count <= sl_brg_count_en;

    pol_tx_done <= sl_tx_done;

    pol_scl    <= sl_scl_out;
    pol_scl_oe <= sl_scl_oe;
    pol_sda    <= sl_sda_out;
    pol_sda_oe <= sl_sda_oe;

    pol_tx_bclf <= sl_bclf;

end architecture;

-----------------------------------------------------------------------------------------------------
--------------------------------------------RX BIT HANDLER-------------------------------------------
-----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master_rx_bit_handler is
    port (
        pil_clk       : in std_logic;
        pil_rst       : in std_logic;
        pil_rxen      : in std_logic;
        pil_brg_pulse : in std_logic;

        pol_rx_data : out std_logic;

        pol_enable_brg_count : out std_logic;
        pol_rx_done          : out std_logic;

        pil_scl    : in std_logic;
        pol_scl    : out std_logic;
        pol_scl_oe : out std_logic;
        pil_sda    : in std_logic;
        pol_sda_oe : out std_logic
    );
end entity;

architecture rtl_rx_bit_handler of i2c_master_rx_bit_handler is

    type t_rx_bit is (st_idle, st_scl_hold_low, st_scl_high, st_receive_data, st_done);
    signal st_rx_bit : t_rx_bit;

    signal sl_rx_data : std_logic;
    signal sl_rx_done : std_logic;

    signal sl_brg_count_en : std_logic;

    signal sl_scl_out : std_logic;
    signal sl_scl_oe  : std_logic;

    signal sl_sda_oe : std_logic;

begin

    proc_rx_bit : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            sl_rx_data      <= '0';
            sl_rx_done      <= '0';
            sl_brg_count_en <= '0';
            sl_scl_out      <= '0';
            sl_scl_oe       <= '1';
            sl_sda_oe       <= '0';
            st_rx_bit       <= st_idle;
        elsif rising_edge(pil_clk) then
            case st_rx_bit is
                when st_idle =>
                    sl_scl_oe  <= '1';
                    sl_sda_oe  <= '0';
                    sl_rx_done <= '0';
                    if pil_rxen = '1' then
                        sl_scl_out <= '0';
                        sl_scl_oe  <= '1';
                        st_rx_bit  <= st_scl_hold_low;
                    end if;
                when st_scl_hold_low =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_brg_count_en <= '0';
                        sl_scl_oe       <= '0';
                        st_rx_bit       <= st_scl_high;
                    end if;
                when st_scl_high =>
                    sl_brg_count_en <= '1';
                    if pil_brg_pulse = '1' then
                        sl_brg_count_en <= '0';
                        sl_scl_out      <= '0';
                        sl_scl_oe       <= '1';
                        st_rx_bit       <= st_receive_data;
                    end if;
                when st_receive_data =>
                    if pil_scl = '0' then
                        sl_rx_data <= pil_sda;
                        st_rx_bit  <= st_done;
                    end if;
                when st_done =>
                    sl_rx_done <= '1';
                    if pil_rxen = '0' then
                        st_rx_bit <= st_idle;
                    end if;
            end case;
        end if;
    end process proc_rx_bit;

    pol_enable_brg_count <= sl_brg_count_en;

    pol_rx_data <= sl_rx_data;
    pol_rx_done <= sl_rx_done;

    pol_scl    <= sl_scl_out;
    pol_scl_oe <= sl_scl_oe;
    pol_sda_oe <= sl_sda_oe;

end architecture;