LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
USE ieee.numeric_std.all;


ENTITY audio_filter_stage1 IS

    PORT (
        i_clk_50              : IN  std_logic;                     -- FPGA clk
        i_reset               : IN  std_logic;                     -- NOTE: This is active high to match sim model
        i_audioSample         : IN  std_logic_vector(35 DOWNTO 0); -- Audio single channel sample in
        i_dataReq             : IN  std_logic;                     -- Enables the internal flip flops and indicates to precess a new audio sample
        o_audioSampleFiltered : OUT std_logic_vector(35 DOWNTO 0)  -- Audio single channel sample out
    );

END ENTITY;


ARCHITECTURE beh OF audio_filter_stage1 IS

    COMPONENT d_flip_flop IS
    GENERIC ( num_bits : natural );
    PORT (
        i_clk     : IN  std_logic;
        i_reset   : IN  std_logic;
        i_dataReq : IN  std_logic;
        i_data    : IN  std_logic_vector(num_bits - 1 DOWNTO 0);
        o_data    : OUT std_logic_vector(num_bits - 1 DOWNTO 0)
    );
    END COMPONENT d_flip_flop;

    COMPONENT filter_mult IS
	PORT
	(
		dataa  : IN  std_logic_vector(35 DOWNTO 0);
		datab  : IN  std_logic_vector(35 DOWNTO 0);
		result : OUT std_logic_vector(71 DOWNTO 0)
	);
    END COMPONENT filter_mult;

    SIGNAL s_add1 : std_logic_vector(35 DOWNTO 0);
    SIGNAL s_add2 : std_logic_vector(35 DOWNTO 0);
    
    SIGNAL s1_a21 : std_logic_vector(71 DOWNTO 0);     SIGNAL s2_a21 : std_logic_vector(35 DOWNTO 0);
    SIGNAL s1_b11 : std_logic_vector(71 DOWNTO 0);     SIGNAL s2_b11 : std_logic_vector(35 DOWNTO 0);
    SIGNAL s1_b21 : std_logic_vector(71 DOWNTO 0);     SIGNAL s2_b21 : std_logic_vector(35 DOWNTO 0);
    
    SIGNAL s_z1   : std_logic_vector(35 DOWNTO 0);

    CONSTANT A21  : std_logic_vector(35 DOWNTO 0) := x"FFFFE2E15";  -- a(2)(1) = -0.9100000 -> 0xFFFFE2E15
    CONSTANT B11  : std_logic_vector(35 DOWNTO 0) := x"0000001B7";  -- b(1)(1) =  0.0033507 -> 0x0000001B7
    CONSTANT B21  : std_logic_vector(35 DOWNTO 0) := x"0000001B7";  -- b(2)(1) =  0.0033507 -> 0x0000001B7

BEGIN

    s2_a21 <= s1_a21(52 DOWNTO 17);
    s2_b11 <= s1_b11(52 DOWNTO 17);
    s2_b21 <= s1_b21(52 DOWNTO 17);

    
    a_21 : filter_mult
    PORT MAP (
        dataa  => s_z1,
        datab  => A21,
        result => s1_a21
    );
   
    b_11 : filter_mult
    PORT MAP (
        dataa  => s_add1,
        datab  => B11,
        result => s1_b11
    );
    
    b_21 : filter_mult
    PORT MAP (
        dataa  => s_z1,
        datab  => B21,
        result => s1_b21
    );

    z1 : d_flip_flop
    GENERIC MAP ( num_bits => 36 )
    PORT MAP (
        i_clk          => i_clk_50,
        i_reset        => i_reset,
        i_dataReq      => i_dataReq,
        i_data         => s_add1,
        o_data         => s_z1
    );

    s_add1 <= std_logic_vector(signed(i_audioSample) - signed(s2_a21));
    s_add2 <= std_logic_vector(signed(s2_b11) + signed(s2_b21));
    o_audioSampleFiltered <= s_add2;

END beh;