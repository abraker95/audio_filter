LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_signed.all;
use std.textio.all;

ENTITY audio_filter IS

    PORT (
        i_clk_50              : IN  std_logic;                     -- FPGA clk
        i_reset               : IN  std_logic;                     -- NOTE: This is active high to match sim model
        i_audioSample         : IN  std_logic_vector(31 DOWNTO 0); -- Audio sample in. For this application, assumes bits(31 downto 16) are same as bits(15 downto 0)
        i_dataReq             : IN  std_logic;                     -- Enables the internal flip flops and indicates to process a new audio sample
        o_audioSampleFiltered : OUT std_logic_vector(31 DOWNTO 0)  -- The filtered audio signal, assumes bits(31 downto 16) are same as bits(15 downto 0)
    );

END ENTITY;


ARCHITECTURE beh OF audio_filter IS

    COMPONENT audio_filter_stage1 IS
        PORT (
            i_clk_50              : IN  std_logic;                     -- FPGA clk
            i_reset               : IN  std_logic;                     -- NOTE: This is active high to match sim model
            i_audioSample         : IN  std_logic_vector(35 DOWNTO 0); -- Audio sample in. For this application, assumes bits(31 downto 16) are same as bits(15 downto 0)
            i_dataReq             : IN  std_logic;                     -- Enables the internal flip flops and indicates to precess a new audio sample
            o_audioSampleFiltered : OUT std_logic_vector(35 DOWNTO 0)  -- The filtered audio signal, assumes bits(31 downto 16) are same as bits(15 downto 0)
        );
    END COMPONENT audio_filter_stage1;

    COMPONENT audio_filter_stage2 IS
        PORT (
            i_clk_50              : IN  std_logic;                     -- FPGA clk
            i_reset               : IN  std_logic;                     -- NOTE: This is active high to match sim model
            i_audioSample         : IN  std_logic_vector(35 DOWNTO 0); -- Audio sample in. For this application, assumes bits(31 downto 16) are same as bits(15 downto 0)
            i_dataReq             : IN  std_logic;                     -- Enables the internal flip flops and indicates to precess a new audio sample
            o_audioSampleFiltered : OUT std_logic_vector(35 DOWNTO 0)  -- The filtered audio signal, assumes bits(31 downto 16) are same as bits(15 downto 0)
        );
    END COMPONENT audio_filter_stage2;

    COMPONENT audio_filter_stage3 IS
        PORT (
            i_clk_50              : IN  std_logic;                     -- FPGA clk
            i_reset               : IN  std_logic;                     -- NOTE: This is active high to match sim model
            i_audioSample         : IN  std_logic_vector(35 DOWNTO 0); -- Audio sample in. For this application, assumes bits(31 downto 16) are same as bits(15 downto 0)
            i_dataReq             : IN  std_logic;                     -- Enables the internal flip flops and indicates to precess a new audio sample
            o_audioSampleFiltered : OUT std_logic_vector(35 DOWNTO 0)  -- The filtered audio signal, assumes bits(31 downto 16) are same as bits(15 downto 0)
        );
    END COMPONENT audio_filter_stage3;

    SIGNAL stage1_to_stage2 : std_logic_vector(35 DOWNTO 0);
    SIGNAL stage2_to_stage3 : std_logic_vector(35 DOWNTO 0);

    SIGNAL filterInOneChannel : signed(15 DOWNTO 0);
    SIGNAL filterInResized    : signed(35 DOWNTO 0);
    SIGNAL filterSection_in   : signed(35 DOWNTO 0);
    SIGNAL filterOutput       : std_logic_vector(35 DOWNTO 0);

BEGIN 
    
    -- Grab just one channel from input
    filterInOneChannel <= signed(i_audioSample(15 DOWNTO 0));

    -- Simply resize the 16 bit input to 36 bits. There is an implied
    -- divide by 4 involved in this, since we are going from 15 bits to
    -- 17 bits after the implied decimal point. this will be canceled by
    -- the multiply by 4 on the output
    filterInResized <= resize(filterInOneChannel, filterInResized'length);

    -- Implement the divide by 16 which is multiplier s(1)
    filterSection_in <= shift_right(filterInResized, 4);
 
    audio_filter_stage1_inst : audio_filter_stage1
    PORT MAP (
        i_clk_50              => i_clk_50,
        i_reset               => i_reset,
        i_audioSample         => std_logic_vector(filterSection_in),
        i_dataReq             => i_dataReq,
        o_audioSampleFiltered => stage1_to_stage2
    );

    audio_filter_stage2_inst : audio_filter_stage2
    PORT MAP (
        i_clk_50              => i_clk_50,
        i_reset               => i_reset,
        i_audioSample         => stage1_to_stage2,
        i_dataReq             => i_dataReq,
        o_audioSampleFiltered => stage2_to_stage3
    );

    audio_filter_stage3_inst : audio_filter_stage3
    PORT MAP (
        i_clk_50              => i_clk_50,
        i_reset               => i_reset,
        i_audioSample         => stage2_to_stage3,
        i_dataReq             => i_dataReq,
        o_audioSampleFiltered => filterOutput
    );

    -- Grab the lowest 16 bits of your filter output and place them
    -- into the output port. There is an implied multiply by 4 here
    -- due to going from 15 bits to 17 bits after the decimal. This
    -- cancels the previous divide by 4.
    o_audioSampleFiltered <= filterOutput(15 DOWNTO 0) & filterOutput(15 DOWNTO 0);

END beh;