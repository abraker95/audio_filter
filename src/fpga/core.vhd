LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY core IS
    PORT (	CLOCK_50           					 				: in std_logic;
			KEY                					 				: in std_logic_vector (3 downto 0);
			SW                 					 				: in std_logic_vector (7 downto 0);

			DRAM_CLK,DRAM_CKE	 								: OUT STD_LOGIC;
			DRAM_ADDR			 								: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
			DRAM_BA_0,DRAM_BA_1									: OUT STD_LOGIC;
			DRAM_CS_N,DRAM_CAS_N,DRAM_RAS_N,DRAM_WE_N			: OUT STD_LOGIC;
			DRAM_DQ												: INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			DRAM_UDQM,DRAM_LDQM									: OUT STD_LOGIC;

			SRAM_ADDR			 								: OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
			SRAM_DQ												: INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			SRAM_WE_N,SRAM_OE_N,SRAM_UB_N,SRAM_LB_N,SRAM_CE_N	: OUT STD_LOGIC;

			AUD_ADCDAT 											: IN STD_LOGIC;
            AUD_ADCLRCK 										: INOUT STD_LOGIC;
            AUD_BCLK 											: INOUT  STD_LOGIC;
            AUD_DACDAT 											: OUT STD_LOGIC;
            AUD_DACLRCK 										: INOUT  STD_LOGIC;
			AUD_XCK                            		   			: OUT STD_LOGIC;

			-- the_audio_and_video_config_0
            I2C_SCLK	 										: OUT STD_LOGIC;
            I2C_SDAT	 										: INOUT STD_LOGIC;
				
			LEDR                              		    		: OUT STD_LOGIC_VECTOR(7 downto 0);
				
			GPIO_0                             		    		: INOUT STD_LOGIC_VECTOR(35 downto 0)
        );
END core;



ARCHITECTURE rtl OF core IS    
    component nios_system is
        port (  
			clk_clk                : in    std_logic                     := '0';             --              clk.clk
			reset_reset_n          : in    std_logic                     := '0';             --            reset.reset_n
			key_buttons_export     : in    std_logic                     := '0';             --      key_buttons.export
			audio_memory_ADCDAT    : in    std_logic                     := '0';             --     audio_memory.ADCDAT
			audio_memory_ADCLRCK   : in    std_logic                     := '0';             --                 .ADCLRCK
			audio_memory_BCLK      : in    std_logic                     := '0';             --                 .BCLK
			audio_memory_DACDAT    : out   std_logic;                                        --                 .DACDAT
			audio_memory_DACLRCK   : in    std_logic                     := '0';             --                 .DACLRCK
			i2c_SDAT               : inout std_logic                     := '0';             --              i2c.SDAT
			i2c_SCLK               : out   std_logic;                                        --                 .SCLK
			sdram_controller_addr  : out   std_logic_vector(11 downto 0);                    -- sdram_controller.addr
			sdram_controller_ba    : out   std_logic_vector(1 downto 0);                     --                 .ba
			sdram_controller_cas_n : out   std_logic;                                        --                 .cas_n
			sdram_controller_cke   : out   std_logic;                                        --                 .cke
			sdram_controller_cs_n  : out   std_logic;                                        --                 .cs_n
			sdram_controller_dq    : inout std_logic_vector(15 downto 0) := (others => '0'); --                 .dq
			sdram_controller_dqm   : out   std_logic_vector(1 downto 0);                     --                 .dqm
			sdram_controller_ras_n : out   std_logic;                                        --                 .ras_n
			sdram_controller_we_n  : out   std_logic;                                        --                 .we_n
			sdram_clk_clk          : out   std_logic;                                        --        sdram_clk.clk
			sram_interface_DQ      : inout std_logic_vector(15 downto 0) := (others => '0'); --   sram_interface.DQ
			sram_interface_ADDR    : out   std_logic_vector(17 downto 0);                    --                 .ADDR
			sram_interface_LB_N    : out   std_logic;                                        --                 .LB_N
			sram_interface_UB_N    : out   std_logic;                                        --                 .UB_N
			sram_interface_CE_N    : out   std_logic;                                        --                 .CE_N
			sram_interface_OE_N    : out   std_logic;                                        --                 .OE_N
			sram_interface_WE_N    : out   std_logic;                                        --                 .WE_N
			switch_0_export        : in    std_logic                     := '0'              --         switch_0.export
        );
    end component nios_system;
	 
    ----------------------------------------------------------------------------
    --               Internal Wires and Registers Declarations                --
    ----------------------------------------------------------------------------

	signal reset_n         : std_logic;
	signal count           : std_logic_vector(3 downto 0);

begin

	AUD_XCK <= count(1);
	reset_n <= KEY(0);
	 
   NiosII : nios_system
		PORT MAP(
			clk_clk                 => CLOCK_50,
			reset_reset_n           => reset_n,
			key_buttons_export      => KEY(1),
			audio_memory_ADCDAT     => AUD_ADCDAT,
			audio_memory_ADCLRCK    => AUD_ADCLRCK,
			audio_memory_BCLK       => AUD_BCLK,
			audio_memory_DACDAT     => AUD_DACDAT,
			audio_memory_DACLRCK    => AUD_DACLRCK,
			i2c_SDAT                => I2C_SDAT,
			i2c_SCLK                => I2C_SCLK,
			sdram_controller_addr   => DRAM_ADDR,
			sdram_controller_ba(0)  => DRAM_BA_0,
			sdram_controller_ba(1)  => DRAM_BA_1,
			sdram_controller_cas_n  => DRAM_CAS_N,
			sdram_controller_cke    => DRAM_CKE,
			sdram_controller_cs_n   => DRAM_CS_N,
			sdram_controller_dq     => DRAM_DQ,
			sdram_controller_dqm(0) => DRAM_LDQM,
			sdram_controller_dqm(1) => DRAM_UDQM,
			sdram_controller_ras_n  => DRAM_RAS_N,
			sdram_controller_we_n   => DRAM_WE_N,
			sdram_clk_clk           => DRAM_CLK,
			sram_interface_DQ       => SRAM_DQ,
			sram_interface_ADDR     => SRAM_ADDR,
			sram_interface_LB_N     => SRAM_LB_N,
			sram_interface_UB_N     => SRAM_UB_N,
			sram_interface_CE_N     => SRAM_CE_N,
			sram_interface_OE_N     => SRAM_OE_N,
			sram_interface_WE_N     => SRAM_WE_N,
			switch_0_export         => SW(0)
		);
			

	clkgen: process(CLOCK_50, reset_n) 
		begin

		   if (reset_n = '0') then          count <= "0000";
	    elsif (rising_edge(CLOCK_50)) then  count <= count + 1;   
		end if;

		end process;
		
END rtl;