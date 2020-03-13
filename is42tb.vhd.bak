-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;

entity is42tb is
end entity is42tb;

architecture behave of is42tb is

  signal r_fakeclock : std_logic := '0';
  signal w_dram_ncs : std_logic;
  signal w_dram_cke : std_logic;
  signal w_dram_dqm : std_logic_vector(3 downto 0);  
  signal w_dram_ncas : std_logic;
  signal w_dram_nras : std_logic;
  signal w_dram_nwe : std_logic;
  signal w_dram_clk : std_logic;
   
begin

  is42_inst : entity is42.is42driver
    generic map(
	  inclk_mhz => 50
	)
	port map(
       iclk => r_fakeclock,
	   
       dram_addr => open,
	   dram_ba => open,
	   dram_dq => open,
	   dram_dqm => w_dram_dqm,

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