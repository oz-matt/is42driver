-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;

entity is42driver is
  generic (
    inclk_mhz : positive  
  );
  port (
  
    iclk : in std_logic;
    
	dram_addr : out std_logic_vector(12 downto 0);
	dram_ba : out std_logic_vector(1 downto 0);
	dram_dq : inout std_logic_vector(31 downto 0);
	dram_dqm : out std_logic_vector(3 downto 0);

    dram_ncas : out std_logic;
    dram_cke : out std_logic;
    dram_clk : out std_logic;
    dram_ncs : out std_logic;
    dram_nras : out std_logic;
    dram_nwe : out std_logic
  );
end is42driver;

architecture RTL of is42driver is
 
  signal r_dram_ncs : std_logic := '0';
  signal r_dram_cke : std_logic := '0';
  signal r_dram_ncas : std_logic := '0';
  signal r_dram_nras : std_logic := '0';
  signal r_dram_nwe : std_logic := '0';
  
  signal r_dram_dqm : std_logic_vector(3 downto 0) := "0000";
  signal r_dram_addr : std_logic_vector(12 downto 0) := "0000000000000";
  signal r_dram_ba : std_logic_vector(1 downto 0) := "00";
  
  -- State machine nodes
  
  type DRAM_STATE is (INIT, IGNITION, STARTWAIT100US, STARTINITIALNOP,
		FINISHWAIT, INITPRECHARGE, WAITTRD, AUTORE1, WAITAR1, AUTORENOP, 
		WAITAR2, AUTORE2);
  signal curr_state: DRAM_STATE := INIT;
  
  -- IS24 commands
  
  constant cmd_nop : std_logic_vector(4 downto 0) := "10111";
  constant cmd_bst : std_logic_vector(4 downto 0) := "10110";
  constant cmd_read : std_logic_vector(4 downto 0) := "10101";
  constant cmd_write : std_logic_vector(4 downto 0) := "10100";
  constant cmd_act : std_logic_vector(4 downto 0) := "10011";
  constant cmd_pre : std_logic_vector(4 downto 0) := "10010";
  constant cmd_mrs : std_logic_vector(4 downto 0) := "10000";
  constant cmd_aref : std_logic_vector(4 downto 0) := "10001"; -- Requires CKE high for >=1 clkcycle prior (no transition allowed)
  
  -- Clock counter
  signal clkctr: natural range 0 to (inclk_mhz * 101) := 0;


begin

  dram_machine : process (iclk) is
  
  procedure sendcmd (
    constant cmd_bundle : in std_logic_vector(4 downto 0)
  ) is
  begin
    r_dram_cke <= cmd_bundle(4);
    r_dram_ncs <= cmd_bundle(3);
	r_dram_nras <= cmd_bundle(2);
	r_dram_ncas <= cmd_bundle(1);
	r_dram_nwe <= cmd_bundle(0);
  end sendcmd;


  begin


	if rising_edge(iclk) then
	  
	  case curr_state is
	    when INIT =>
		  curr_state <= IGNITION;
		  
		when IGNITION =>
		  r_dram_cke <= '1';
		  r_dram_dqm <= "1111";
		  curr_state <= STARTWAIT100US;
		  
		when STARTWAIT100US =>
		  if clkctr > (inclk_mhz * 5) then
		    clkctr <= 0;
		    curr_state <= STARTINITIALNOP;
	      else
			clkctr <= clkctr + 1;
		  end if;
		
		when STARTINITIALNOP =>
		  sendcmd(cmd_nop);
          curr_state <= FINISHWAIT;		
		
		when FINISHWAIT =>
		  if clkctr > (inclk_mhz * 100) then
		    clkctr <= 0;
		    curr_state <= INITPRECHARGE;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when INITPRECHARGE =>
		  sendcmd(cmd_pre);
		  r_dram_addr(10) <= '1'; -- Precharge all banks
		  curr_state <= WAITTRD;
		  
		when WAITTRD =>
		  if clkctr > (inclk_mhz * 1) then -- Wait minimum 18ns
		    clkctr <= 0;
		    curr_state <= AUTORE1;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when AUTORE1 =>
		  sendcmd(cmd_aref);
		  curr_state => WAITAR1;
		  
		when WAITAR1 =>
		  if clkctr > (inclk_mhz * 1) then -- Wait minimum 18ns
		    clkctr <= 0;
		    curr_state <= AUTORENOP;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when AUTORENOP =>
		  sendcmd(cmd_nop);
		  curr_state => WAITAR1;

        when WAITAR2 =>
		  if clkctr > (inclk_mhz * 1) then -- Wait minimum 18ns
		    clkctr <= 0;
		    curr_state <= AUTORE2;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when AUTORE2 =>
		  sendcmd(cmd_aref);
		  curr_state => WAITAR1;


		  end case;
	
	end if;
  end process dram_machine;

    dram_dqm <= r_dram_dqm;
    dram_addr <= r_dram_addr;
    dram_ba <= r_dram_ba;
	
    dram_ncas <= r_dram_ncas;
    dram_cke <= r_dram_cke;
    dram_clk <= iclk;
    dram_ncs <= r_dram_ncs;
    dram_nras <= r_dram_ncas;
    dram_nwe <= r_dram_nwe;
  
end RTL;
