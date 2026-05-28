library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hex_decode is
    port (
        pil_clk            : in std_logic;
        pil_rst            : in std_logic;
        pil_hex_decoder_en : in std_logic;
        pil_data_valid     : in std_logic;
        piv_data           : in std_logic_vector(7 downto 0);
        pol_wen            : out std_logic;
        pov_address        : out std_logic_vector(31 downto 0);
        pov_data           : out std_logic_vector(7 downto 0);
        pol_eof            : out std_logic
    );
end entity;

architecture rtl of hex_decode is

    type t_hex_decode_state is (st_idle, st_word_count, st_address, st_record_type, st_data, st_check_sum);
    signal st_hex_decode_state : t_hex_decode_state;

    --- start code symbol ---

    constant cv_start_code : std_logic_vector(7 downto 0) := X"3A"; --- ascii character ':'

    --- record types ---

    constant cv_record_type_data : std_logic_vector(7 downto 0) := X"00"; -- record : Data
    constant cv_record_type_eof  : std_logic_vector(7 downto 0) := X"01"; -- record : End Of File
    constant cv_record_type_ela  : std_logic_vector(7 downto 0) := X"04"; -- record : Extended Linear Address

    signal su_base_address : unsigned(31 downto 0);
    signal su_address_out  : unsigned(31 downto 0);

    signal su_data_length : unsigned(7 downto 0);
    signal sv_record_type : std_logic_vector(7 downto 0);

    signal sv_data : std_logic_vector(7 downto 0);

    signal sl_wen : std_logic;
    signal sl_eof : std_logic;

    signal si_byte_ct : integer range 0 to 31;

begin

    proc_hex_decoder : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            su_base_address     <= (others => '0');
            su_address_out      <= (others => '0');
            su_data_length      <= (others => '0');
            sv_record_type      <= (others => '0');
            sv_data             <= (others => '0');
            sl_wen              <= '0';
            sl_eof              <= '0';
            si_byte_ct          <= 0;
            st_hex_decode_state <= st_idle;
        elsif rising_edge(pil_clk) then
            sl_wen <= '0';
            sl_eof <= '0';
            if pil_hex_decoder_en = '1' then
                case st_hex_decode_state is
                    when st_idle =>
                        si_byte_ct     <= 0;
                        su_data_length <= (others => '0');
                        su_address_out <= (others => '0');
                        sv_record_type <= (others => '0');
                        if pil_data_valid = '1' then
                            if piv_data = cv_start_code then
                                st_hex_decode_state <= st_word_count;
                            end if;
                        end if;
                    when st_word_count =>
                        if pil_data_valid = '1' then
                            su_data_length      <= unsigned(piv_data);
                            st_hex_decode_state <= st_address;
                        end if;
                    when st_address =>
                        if pil_data_valid = '1' then
                            if si_byte_ct < 1 then
                                su_base_address(15 downto 8) <= unsigned(piv_data);
                                si_byte_ct                   <= si_byte_ct + 1;
                                st_hex_decode_state          <= st_address;
                            else
                                si_byte_ct                  <= 0;
                                su_base_address(7 downto 0) <= unsigned(piv_data);
                                st_hex_decode_state         <= st_record_type;
                            end if;
                        end if;
                    when st_record_type =>
                        if pil_data_valid = '1' then
                            sv_record_type      <= piv_data;
                            st_hex_decode_state <= st_data;
                        end if;
                    when st_data =>
                        case sv_record_type is
                            when cv_record_type_data =>
                                if su_data_length = X"00" then
                                    st_hex_decode_state <= st_check_sum;
                                else
                                    if pil_data_valid = '1' then
                                        su_address_out <= su_base_address + to_unsigned(si_byte_ct, 32);
                                        sv_data        <= piv_data;
                                        sl_wen         <= '1';
                                        if si_byte_ct < to_integer(su_data_length) - 1 then
                                            si_byte_ct          <= si_byte_ct + 1;
                                            st_hex_decode_state <= st_data;
                                        else
                                            si_byte_ct          <= 0;
                                            st_hex_decode_state <= st_check_sum;
                                        end if;
                                    end if;
                                end if;
                            when cv_record_type_eof =>
                                st_hex_decode_state <= st_check_sum;
                            when cv_record_type_ela =>
                                if pil_data_valid = '1' then
                                    if si_byte_ct < 1 then
                                        su_base_address(31 downto 24) <= unsigned(piv_data);
                                        si_byte_ct                    <= si_byte_ct + 1;
                                        st_hex_decode_state           <= st_data;
                                    else
                                        si_byte_ct                    <= 0;
                                        su_base_address(23 downto 16) <= unsigned(piv_data);
                                        st_hex_decode_state           <= st_check_sum;
                                    end if;
                                end if;
                            when others =>
                                st_hex_decode_state <= st_check_sum;
                        end case;
                    when st_check_sum =>
                        if pil_data_valid = '1' then
                            if sv_record_type = cv_record_type_eof then
                                sl_eof <= '1';
                            end if;
                            st_hex_decode_state <= st_idle;
                        end if;
                end case;
            else
                st_hex_decode_state <= st_idle;
            end if;
        end if;
    end process proc_hex_decoder;

    pol_eof <= sl_eof;

    pol_wen     <= sl_wen;
    pov_address <= std_logic_vector(su_address_out);
    pov_data    <= sv_data;

end architecture;