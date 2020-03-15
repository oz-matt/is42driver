library IEEE;
use IEEE.std_logic_1164.all;

entity is42proc is
  port (
   iclk : in std_logic;
  
   data_miso : out std_logic_vector(31 downto 0);
  
   dram_dqm : out std_logic_vector(3 downto 0);  
   dram_ba : out std_logic_vector(1 downto 0);  
   dram_addr : out std_logic_vector(12 downto 0);  
   dram_ncs : out std_logic;
   dram_cke : out std_logic;
   dram_ncas : out std_logic;
   dram_nras : out std_logic;
   dram_nwe : out std_logic;
   dram_clk : out std_logic;
   dram_dataq : inout std_logic_vector(31 downto 0)
  
  );
end entity;

architecture rwlooptest of is42proc is
  
  signal r_addr : std_logic_vector(12 downto 0) := "0000000000000";
  signal r_data_mosi : std_logic_vector(31 downto 0) := X"00000000";
  signal r_ba : std_logic_vector(1 downto 0) := "00";
  signal r_exec : std_logic := '0';
  signal r_wbit : std_logic := '1';
  
  -- Clock counter
  signal clkctr: natural range 0 to (5500) := 0;
  
  -- is42proc FSM
  type PROCFSM is (WAITIS42INIT, TESTWRITE, TWWAIT, WAITFORREAD, 
      TESTREAD, TRWAIT);
  signal curr_state : PROCFSM := WAITIS42INIT;
  
begin

  is42_inst : entity work.is42driver
   port map(
       iclk => iclk,
	   rdy => open,
	   
	   in_addr => r_addr,
	   in_mosi => r_data_mosi,
	   in_ba => r_ba,
    	in_exec => r_exec,
	   in_wbit => r_wbit,
	   
	   out_miso => data_miso,
	   
       dram_addr => dram_addr,
	   dram_ba => dram_ba,
	   dram_dqm => dram_dqm,
       dram_dq => dram_dataq,
	   
	   dram_ncas => dram_ncas,
       dram_cke => dram_cke,
       dram_clk => dram_clk,
       dram_ncs => dram_ncs,
       dram_nras => dram_nras,
       dram_nwe => dram_nwe
    );


   process (iclk) is
   begin
	
	  if rising_edge(iclk) then
	    case curr_state is
		 
		   when WAITIS42INIT =>
			  if clkctr > 5250 then
		       clkctr <= 0;
				 curr_state <= TESTWRITE;
		     else
		       clkctr <= clkctr + 1;
		     end if;
			  
			when TESTWRITE =>
			  r_exec <= '1';
           r_addr <= "0000000000111";
           r_data_mosi <= X"ABABABAB";
           r_ba <= "10";
           r_wbit <= '1';
			  curr_state <= TWWAIT;
			  
			when TWWAIT =>
           r_exec <= '0';
           r_addr <= "0000000000000";
           r_data_mosi <= X"00000000";
           r_ba <= "00";
           r_wbit <= '0';
           if clkctr > 2 then
		       clkctr <= 0;
				 curr_state <= WAITFORREAD;
		     else
		       clkctr <= clkctr + 1;
		     end if;
			  
			when WAITFORREAD =>
           if clkctr > 9 then
		       clkctr <= 0;
				 curr_state <= TESTREAD;
		     else
		       clkctr <= clkctr + 1;
		     end if;
			  
			when TESTREAD =>
			  r_exec <= '1';
           r_addr <= "0000000000111";
           r_ba <= "10";
           r_wbit <= '0';
			  curr_state <= TRWAIT;
			  
			when TRWAIT =>
           r_exec <= '0';
           r_addr <= "0000000000000";
           r_ba <= "00";
           r_wbit <= '0';
           if clkctr > 2 then
		       clkctr <= 0;
				 --curr_state <= WAITFORREAD;
		     else
		       clkctr <= clkctr + 1;
		     end if;
			  
			  
		 end case;
	  
	  end if;  
   
   end process;
   
end rwlooptest;