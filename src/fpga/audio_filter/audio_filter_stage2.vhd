LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
USE ieee.numeric_std.all;


ENTITY audio_filter_stage2 IS

    PORT (
        i_clk_50              : IN  std_logic;                     -- FPGA clk
        i_reset               : IN  std_logic;                     -- NOTE: This is active high to match sim model
        i_audioSample         : IN  std_logic_vector(35 DOWNTO 0); -- Audio single channel sample in
        i_dataReq             : IN  std_logic;                     -- Enables the internal flip flops and indicates to precess a new audio sample
        o_audioSampleFiltered : OUT std_logic_vector(35 DOWNTO 0)  -- Audio single channel sample out
    );

END ENTITY;


ARCHITECTURE beh OF audio_filter_stage2 IS

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
    
    SIGNAL s1_a22 : std_logic_vector(71 DOWNTO 0);    SIGNAL s2_a22 : std_logic_vector(35 DOWNTO 0);
    SIGNAL s1_a32 : std_logic_vector(71 DOWNTO 0);    SIGNAL s2_a32 : std_logic_vector(35 DOWNTO 0);
    
    SIGNAL s1_b12 : std_logic_vector(71 DOWNTO 0);    SIGNAL s2_b12 : std_logic_vector(35 DOWNTO 0);
    SIGNAL s1_b22 : std_logic_vector(71 DOWNTO 0);    SIGNAL s2_b22 : std_logic_vector(35 DOWNTO 0);
    SIGNAL s1_b32 : std_logic_vector(71 DOWNTO 0);    SIGNAL s2_b32 : std_logic_vector(35 DOWNTO 0);

    SIGNAL s_z1   : std_logic_vector(35 DOWNTO 0);
    SIGNAL s_z2   : std_logic_vector(35 DOWNTO 0);

    CONSTANT A22  : std_logic_vector(35 DOWNTO 0) := x"FFFFC2155";  -- a(2)(2) = -1.9349000 -> 0xFFFFC2155
    CONSTANT A32  : std_logic_vector(35 DOWNTO 0) := x"00001E316";  -- a(3)(2) =  0.9435300 -> 0x00001E316
    CONSTANT B12  : std_logic_vector(35 DOWNTO 0) := x"00000015A";  -- b(1)(2) =  0.0026446 -> 0x00000015A
    CONSTANT B22  : std_logic_vector(35 DOWNTO 0) := x"0000002B5";  -- b(2)(2) =  0.0052893 -> 0x0000002B5
    CONSTANT B32  : std_logic_vector(35 DOWNTO 0) := x"00000015A";  -- b(3)(2) =  0.0026446 -> 0x00000015A

BEGIN 
    
    s2_a22 <= s1_a22(52 DOWNTO 17);
    s2_a32 <= s1_a32(52 DOWNTO 17);

    s2_b12 <= s1_b12(52 DOWNTO 17);
    s2_b22 <= s1_b22(52 DOWNTO 17);
    s2_b32 <= s1_b32(52 DOWNTO 17);


    a_22 : filter_mult
    PORT MAP (
        dataa  => std_logic_vector(s_z1),
        datab  => A22,
        result => s1_a22
    );

    a_32 : filter_mult
    PORT MAP (
        dataa  => s_z2,
        datab  => A32,
        result => s1_a32
    );
    
    b_22 : filter_mult
    PORT MAP (
        dataa  => s_z1,
        datab  => B22,
        result => s1_b22
    );

    b_32 : filter_mult
    PORT MAP (
        dataa  => s_z2,
        datab  => B32,
        result => s1_b32
    );

    b_12 : filter_mult
    PORT MAP (
        dataa  => s_add2,
        datab  => x"00000015A",   
        result => s1_b12
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

    s_add1 <= std_logic_vector(signed(i_audioSample) - signed(s2_a22));
    s_add2 <= std_logic_vector(signed(s_add1) - signed(s2_a32));
    s_add3 <= std_logic_vector(signed(s2_b12) + signed(s2_b22));
    s_add4 <= std_logic_vector(signed(s_add3) + signed(s2_b32));
    o_audioSampleFiltered <= s_add4;

END beh;