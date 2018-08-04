LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY d_flip_flop IS

    GENERIC ( num_bits : natural );
    PORT 
    (
        i_clk     : IN  std_logic;
        i_reset   : IN  std_logic;
        i_dataReq : IN  std_logic;
        i_data    : IN  std_logic_vector(num_bits - 1 DOWNTO 0);
        o_data    : OUT std_logic_vector(num_bits - 1 DOWNTO 0)
    );

END d_flip_flop;


ARCHITECTURE beh OF d_flip_flop IS

BEGIN 
    
    PROCESS(i_reset, i_clk, i_dataReq)
    BEGIN
        IF rising_edge(i_clk) THEN
            IF    i_reset = '0'   THEN o_data <= ( OTHERS => '0' );
            ELSIF i_dataReq = '1' THEN o_data <= i_data;
            END IF;
        END IF;
    END PROCESS; 

END beh;