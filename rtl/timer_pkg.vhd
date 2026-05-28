library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package timer_pkg is

	constant ci_clksrc_div : integer := 1;

	--- dct signal bit map ---

	type tr_dct_flag is record
		i_TFA : integer;
		i_TFB : integer;
	end record tr_dct_flag;

	type tr_dct_con is record
		i_TRAON   : integer;
		i_TRBON   : integer;
		i_TRA_set : integer;
		i_TRB_set : integer;
		i_clr_TFA : integer;
		i_clr_TFB : integer;
	end record tr_dct_con;

	constant ctr_dct_flag : tr_dct_flag := (
		i_TFA => 0,
		i_TFB => 1
	);

	constant ctr_dct_con : tr_dct_con := (
		i_TRAON   => 0,
		i_TRBON   => 1,
		i_TRA_set => 2,
		i_TRB_set => 3,
		i_clr_TFA => 4,
		i_clr_TFB => 5
	);

	--- ict signal bit map ---

	type tr_ict_flag is record
		i_TF  : integer;
		i_TIC : integer;
	end record tr_ict_flag;

	type tr_ict_con is record
		i_TICRON                 : integer;
		i_TCIC_mode              : integer;
		i_TIC_capture_start_edge : integer;
		i_TIC_capture_end_edge   : integer;
		i_TIC_set                : integer;
		i_TR_set                 : integer;
		i_capture_start_pinBit0  : integer;
		i_capture_start_pinBit1  : integer;
		i_capture_end_pinBit0    : integer;
		i_capture_end_pinBit1    : integer;
		i_Timer_flag_clr         : integer;
		i_TIC_flag_clr           : integer;
	end record tr_ict_con;

	constant ctr_ict_flag : tr_ict_flag := (
		i_TF  => 0,
		i_TIC => 1
	);

	constant ctr_ict_con : tr_ict_con := (
		i_TICRON                 => 0,
		i_TCIC_mode              => 1,
		i_TIC_capture_start_edge => 2,
		i_TIC_capture_end_edge   => 3,
		i_TIC_set                => 4,
		i_TR_set                 => 5,
		i_capture_start_pinBit0  => 6,
		i_capture_start_pinBit1  => 7,
		i_capture_end_pinBit0    => 8,
		i_capture_end_pinBit1    => 9,
		i_Timer_flag_clr         => 10,
		i_TIC_flag_clr           => 11
	);

end package timer_pkg;