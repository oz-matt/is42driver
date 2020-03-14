-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;

entity is42tb is
end entity is42tb;

architecture behave of is42tb is

  signal r_fakeclock : std_logic := '0';
  
  signal r_addr : std_logic_vector(12 downto 0) := "0000000000000";
  signal r_data_mosi : std_logic_vector(31 downto 0) := X"00000000";
  signal r_exec : std_logic := '0';
  signal r_wbit : std_logic := '1';

  signal w_rdy : std_logic;
  signal w_data_miso : std_logic_vector(31 downto 0);

  signal w_dram_dqm : std_logic_vector(3 downto 0);  
  signal w_dram_ba : std_logic_vector(1 downto 0);  
  signal w_dram_addr : std_logic_vector(12 downto 0);  
  signal w_dram_ncs : std_logic;
  signal w_dram_cke : std_logic;
  signal w_dram_ncas : std_logic;
  signal w_dram_nras : std_logic;
  signal w_dram_nwe : std_logic;
  signal w_dram_clk : std_logic;
  signal w_dram_dataq : std_logic_vector(31 downto 0);
  
  
begin

  is42_inst : entity work.is42driver
   port map(
       iclk => r_fakeclock,
	   rdy => w_rdy,
	   
	   in_addr => r_addr,
	   in_mosi => r_data_mosi,
	   in_exec => r_exec,
	   in_wbit => r_wbit,
	   
	   out_miso => w_data_miso,
	   
       dram_addr => w_dram_addr,
	   dram_ba => w_dram_ba,
	   dram_dqm => w_dram_dqm,
       dram_dq => w_dram_dataq,
	   
	   dram_ncas => w_dram_ncas,
       dram_cke => w_dram_cke,
       dram_clk => w_dram_clk,
       dram_ncs => w_dram_ncs,
       dram_nras => w_dram_nras,
       dram_nwe => w_dram_nwe
    );


  r_fakeclock <= not r_fakeclock after 10 ns;

   process is
   begin
   
   wait for 20 us;
   
   end process;
   
end behave;