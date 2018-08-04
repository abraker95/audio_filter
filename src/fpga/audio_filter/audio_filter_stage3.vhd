LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
USE ieee.numeric_std.all;


ENTITY audio_filter_stage3 IS

    PORT (
        i_clk_50              : IN  std_logic;                     -- FPGA clk
        i_reset               : IN  std_logic;                     -- NOTE: This is active high to match sim model
        i_audioSample         : IN  std_logic_vector(35 DOWNTO 0); -- Audio single channel sample in
        i_dataReq             : IN  std_logic;                     -- Enables the internal flip flops and indicates to precess a new audio sample
        o_audioSampleFiltered : OUT std_logic_vector(35 DOWNTO 0)  -- Audio single channel sample out
    );

END ENTITY;


ARCHITECTURE beh OF audio_filter_stage3 IS

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

    SIGNAL s_s1   : std_logic_vector(35 DOWNTO 0);
    SIGNAL s_add1 : std_logic_vector(35 DOWNTO 0);
    SIGNAL s_add2 : std_logic_vector(35 DOWNTO 0);
    SIGNAL s_add3 : std_logic_vector(35 DOWNTO 0);
    SIGNAL s_add4 : std_logic_vector(35 DOWNTO 0);

    SIGNAL s1_b13 : std_logic_vector(71 DOWNTO 0);   SIGNAL s2_b13  : std_logic_vector(35 DOWNTO 0);
    SIGNAL s1_b23 : std_logic_vector(71 DOWNTO 0);   SIGNAL s2_b23  : std_logic_vector(35 DOWNTO 0);
    SIGNAL s1_b33 : std_logic_vector(71 DOWNTO 0);   SIGNAL s2_b33  : std_logic_vector(35 DOWNTO 0);

    SIGNAL s1_a23 : std_logic_vector(71 DOWNTO 0);   SIGNAL s2_a23  : std_logic_vector(35 DOWNTO 0);
    SIGNAL s1_a33 : std_logic_vector(71 DOWNTO 0);   SIGNAL s2_a33  : std_logic_vector(35 DOWNTO 0);
    
    SIGNAL s_z1   : std_logic_vector(35 DOWNTO 0);
    SIGNAL s_z2   : std_logic_vector(35 DOWNTO 0);

    CONSTANT A23  : std_logic_vector(35 DOWNTO 0) := x"FFFFC4C99";  -- a(2)(3) = -1.8504000 -> 0xFFFFC4C99
    CONSTANT A33  : std_logic_vector(35 DOWNTO 0) := x"00001B79B";  -- a(3)(3) =  0.8586100 -> 0x00001B79B
    CONSTANT B13  : std_logic_vector(35 DOWNTO 0) := x"00000800A";  -- b(1)(3) =  0.2500800 -> 0x00000800A
    CONSTANT B23  : std_logic_vector(35 DOWNTO 0) := x"000010013";  -- b(2)(3) =  0.5001500 -> 0x000010013
    CONSTANT B33  : std_logic_vector(35 DOWNTO 0) := x"00000800A";  -- b(3)(3) =  0.2500800 -> 0x00000800A

BEGIN

    s2_b13 <= s1_b13(52 DOWNTO 17);
    s2_b23 <= s1_b23(52 DOWNTO 17);
    s2_b33 <= s1_b33(52 DOWNTO 17);

    s2_a23 <= s1_a23(52 DOWNTO 17);
    s2_a33 <= s1_a33(52 DOWNTO 17);
    
    
    b_13 : filter_mult
    PORT MAP (
        dataa  => s_add2,
        datab  => x"00000800A",
        result => s1_b13
    );
    
    b_23 : filter_mult
    PORT MAP (
        dataa  => s_z1,
        datab  => x"000010013",
        result => s1_b23
    );
    
    b_33 : filter_mult
    PORT MAP (
        dataa  => s_z2,
        datab  => x"00000800A",
        result => s1_b33
    );

    a_23 : filter_mult
    PORT MAP (
        dataa  => s_z1,
        datab  => x"FFFFC4C99",
        result => s1_a23
    );

    a_33 : filter_mult
    PORT MAP (
        dataa  => s_z2,
        datab  => x"00001B78B",
        result => s1_a33
    );

    z1 : d_flip_flop
    GENERIC MAP ( num_bits => 36 )
    PORT MAP (
        i_clk          => i_clk_50,
        i_reset        => i_reset,
        i_dataReq      => i_dataReq,
        i_data         => s_add2,
        o_data         => s_z1
    );

    z2 : d_flip_flop
    GENERIC MAP ( num_bits => 36 )
    PORT MAP (
        i_clk          => i_clk_50,
        i_reset        => i_reset,
        i_dataReq      => i_dataReq,
        i_data         => s_z1,
        o_data         => s_z2
    );

    s_add1 <= std_logic_vector(signed(i_audioSample) - signed(s2_a23));
    s_add2 <= std_logic_vector(signed(s_add1) - signed(s2_a33));
    s_add3 <= std_logic_vector(signed(s2_b13) + signed(s2_b23));
    s_add4 <= std_logic_vector(signed(s_add3) + signed(s2_b33));
    o_audioSampleFiltered <= s_add4;

END beh;