LIBRARY ieee;
USE ieee.std_logic_1164.all;


ENTITY synchronizer IS
    GENERIC ( sig_width: integer := 1 );
    PORT (
        i_clk    : IN  std_logic;
        i_input  : IN  std_logic_vector(sig_width-1 DOWNTO 0);
        o_output : OUT std_logic_vector(sig_width-1 DOWNTO 0)
    );
END ENTITY synchronizer;


ARCHITECTURE synchronizer_arch OF synchronizer IS

    SIGNAL s_in  : std_logic_vector(sig_width-1 DOWNTO 0);
    SIGNAL s_out : std_logic_vector(sig_width-1 DOWNTO 0);

BEGIN

    sync_proc : PROCESS (i_clk) BEGIN
      If (rising_edge(i_clk)) THEN
        s_in  <= i_input;
        s_out <= s_in;
      END IF;
    END PROCESS sync_proc;

    o_output <= s_out;

END ARCHITECTURE synchronizer_arch;

