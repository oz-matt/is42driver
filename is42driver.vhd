-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;

entity is42driver is
  generic (
    inclk_mhz : positive;  
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
    dram_nwe : out std_logic;
  );
end is42driver;

architecture RTL of dramdriver is
 
  signal r_dram_ncs : std_logic := '0';
  signal r_dram_cke : std_logic := '0';
  signal r_dram_dqm : std_logic_vector(3 downto 0) := '0';
  
  
  -- State machine nodes
  
  type DRAM_STATE is (INIT, IGNITION, WAIT100US, IDLE);
  signal curr_state: DRAM_STATE := INIT;
  
  -- Clock counter
  signal clkctr: natural range 0 to (inclk_mhz * 101) := '0';
  
begin

  dram_machine : process (iclk) is
  begin
	if rising_edge(iclk) then
	begin
	  
	  case curr_state is
	    when INIT =>
		  curr_state <= IGNITION;
		  
		when IGNITION =>
		  r_dram_cke <= 1;
		  r_dram_dqm <= "1111";
		  curr_state <= WAIT100US;
		  
		when WAIT100US =>
		  if clkctr > (inclk_mhz * 100) then
		  begin
		    clkctr <= 0;
		    curr_state <= IDLE;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		  
		  
	  end case;
	
	end if;
  end process dram_machine;
end RTL;




-- entity clkdiv is
  -- port (
    -- iclk : in std_logic;
    -- iclk : in std_logic;
    -- iclk : in std_logic;
    -- iclk : in std_logic;
    -- iclk : in std_logic;
    -- iclk : in std_logic;
    -- iclk : in std_logic;
    -- iclk : in std_logic;
    -- iclk : in std_logic;
    -- );
-- end clkdiv;

-- architecture RTL of clkdiv is
  -- signal clkctr : integer range 0 to 5;
  
  -- signal toggle : std_logic := '0';
  
-- begin

  -- divit : process (iclk) is
  -- begin
    -- if rising_edge(iclk) then
      -- if clkctr = 4 then
        -- toggle <= not toggle;
        -- clkctr <= 0;
      -- else
        -- clkctr <= clkctr + 1;
      -- end if;
      
      
    -- end if;
  -- end process divit;
  

  -- osig <= toggle;

-- end RTL;