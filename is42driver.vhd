library IEEE;
use IEEE.std_logic_1164.all;

entity is42driver is
  port (
  
    iclk : in std_logic; -- From FPGA
	rdy : out std_logic;
	   
	   in_addr : in std_logic_vector(12 downto 0);
	   in_mosi : in std_logic_vector(31 downto 0);
	   in_ba : in std_logic_vector(1 downto 0);
	   in_exec : in std_logic;
	   in_wbit : in std_logic;
	   
	   out_miso : out std_logic_vector(31 downto 0);
  
	dram_addr : out std_logic_vector(12 downto 0); -- To DRAM
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
end entity;

architecture RTL of is42driver is

  signal r_rdy : std_logic := '0';
  
  signal ir_addr : std_logic_vector(12 downto 0) := "0000000000000";
  signal ir_mosi : std_logic_vector(31 downto 0) := X"00000000";
  signal ir_ba: std_logic_vector(1 downto 0) := "00";
  signal ir_wbit : std_logic := '0';
 
  signal r_dram_ncs : std_logic := '0';
  signal r_dram_cke : std_logic := '0';
  signal r_dram_ncas : std_logic := '0';
  signal r_dram_nras : std_logic := '0';
  signal r_dram_nwe : std_logic := '0';
  
  signal r_dram_dqm : std_logic_vector(3 downto 0) := "0000";
  signal r_dram_addr : std_logic_vector(12 downto 0) := "0000000000000";
  signal r_dram_ba : std_logic_vector(1 downto 0) := "00";
  
  signal r_dram_dq : std_logic_vector(31 downto 0) := X"00000000";
  signal r_out_miso : std_logic_vector(31 downto 0) := X"00000000";
 
  -- State machine nodes
  
  type DRAM_STATE is (INIT, IGNITION, STARTWAIT100US, STARTINITIALNOP,
		FINISHWAIT, INITPRECHARGE, WAITTRD, AUTORE1, WAITAR1, AUTORENOP, 
		WAITARN1, AUTORE2, WAITAR2, AUTORENOP2, WAITARN2, MODESEL, 
		WAITMSEL, MSELNOP, WAITMSN, ACTIVATE, INITCOMP, EXECWRITE,
		WRITEWAIT1, WRITEWAIT2, EXECREAD, READWAIT);
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
  signal clkctr: natural range 0 to (5100) := 0;


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

 

	if falling_edge(iclk) then
	  
	  case curr_state is
	    when INIT =>
		  curr_state <= IGNITION;
		  
		when IGNITION =>
		  r_dram_cke <= '1';
		  r_dram_dqm <= "1111";
		  curr_state <= STARTWAIT100US;
		  
		when STARTWAIT100US =>
		  if clkctr > (50) then
		    clkctr <= 0;
		    curr_state <= STARTINITIALNOP;
	      else
			clkctr <= clkctr + 1;
		  end if;
		
		when STARTINITIALNOP =>
		  sendcmd(cmd_nop);
          curr_state <= FINISHWAIT;		
		
		when FINISHWAIT =>
		  if clkctr > (5000) then -- Wait minimum 100us
		    clkctr <= 0;
		    curr_state <= INITPRECHARGE;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when INITPRECHARGE =>
		  sendcmd(cmd_pre);
		  r_dram_dqm <= "0000";
		  r_dram_addr(10) <= '1'; -- Precharge all banks
		  curr_state <= WAITTRD;
		  
		when WAITTRD =>
		  if clkctr > (2) then -- Wait minimum 18ns
		    clkctr <= 0;
		    curr_state <= AUTORE1;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when AUTORE1 =>
		  sendcmd(cmd_aref);
		  curr_state <= WAITAR1;
		  
		when WAITAR1 =>
		  if clkctr > (4) then -- Wait minimum 60ns/2
		    clkctr <= 0;
		    curr_state <= AUTORENOP;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when AUTORENOP =>
		  sendcmd(cmd_nop);
		  curr_state <= WAITARN1;

        when WAITARN1 =>
		  if clkctr > (4) then -- Wait minimum 60ns/2
		    clkctr <= 0;
		    curr_state <= AUTORE2;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when AUTORE2 =>
		  sendcmd(cmd_aref);
		  curr_state <= WAITAR2;
		  
		when WAITAR2 =>
		  if clkctr > (4) then -- Wait minimum 60ns/2
		    clkctr <= 0;
		    curr_state <= AUTORENOP2;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when AUTORENOP2 =>
		  sendcmd(cmd_nop);
		  curr_state <= WAITARN2;
		  
		when WAITARN2 =>
		  if clkctr > (4) then -- Wait minimum 60ns/2
		    clkctr <= 0;
		    curr_state <= MODESEL;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when MODESEL =>
		  sendcmd(cmd_mrs); -- Send mode select command
			r_dram_ba(0) <= '0'; -- Set reserved pins to 0 per datasheet
			r_dram_ba(1) <= '0';
			r_dram_addr(12) <= '0';
			r_dram_addr(11) <= '0';
			r_dram_addr(10) <= '0';

			r_dram_addr(9) <= '1'; -- Single Location Address mode
			
			r_dram_addr(8) <= '0'; -- Std operation
			r_dram_addr(7) <= '0';
			
			r_dram_addr(6) <= '0'; -- 2clk data latency since 100<MHz operation
			r_dram_addr(5) <= '1';
			r_dram_addr(4) <= '0';
			
			r_dram_addr(3) <= '0'; -- 1 byte r/w format
			r_dram_addr(2) <= '0';
			r_dram_addr(1) <= '0';
			r_dram_addr(0) <= '0';
			curr_state <= WAITMSEL;
			
			
	    when WAITMSEL =>
		  if clkctr > (2) then -- Wait minimum 14ns/2
		    clkctr <= 0;
		    curr_state <= MSELNOP;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		when MSELNOP =>
		  sendcmd(cmd_nop);
		  curr_state <= WAITMSN;
		  
		when WAITMSN =>
		  if clkctr > (2) then -- Wait minimum 14ns/2
		    clkctr <= 0;
		    curr_state <= ACTIVATE;
	      else
			clkctr <= clkctr + 1;
		  end if;
			
		when ACTIVATE => -- Ready for r/w commands
		  sendcmd(cmd_act);
		  r_rdy <= '1';
		  curr_state <= INITCOMP;
		  
		when INITCOMP =>
		r_out_miso <= X"00000000";
		  if (in_exec = '1') then
            r_rdy <= '0';
            ir_addr <= in_addr;
            ir_wbit <= in_wbit;
			ir_ba <= in_ba;
            if (in_wbit = '1') then
              curr_state <= EXECWRITE;
			  ir_mosi <= in_mosi;
            else
              curr_state <= EXECREAD;
            end if;		
          end if;			
		  
		when EXECWRITE =>
		  sendcmd(cmd_write);
		  r_dram_ba <= ir_ba;
		  r_dram_addr <= ir_addr;
		  r_dram_dq <= ir_mosi;
		  ir_mosi <= in_mosi;
		  curr_state <= WRITEWAIT1;
		  
		when WRITEWAIT1 =>
		  sendcmd(cmd_nop);
		  r_dram_dq <= ir_mosi;
		  curr_state <= WRITEWAIT2;
		  
		when WRITEWAIT2 =>
		  if clkctr > (1) then
		    clkctr <= 0;
			r_rdy <= '1';
		    curr_state <= INITCOMP;
	      else
			clkctr <= clkctr + 1;
		  end if;
		
		when EXECREAD =>
		  sendcmd(cmd_read);
		  r_dram_ba <= ir_ba;
		  r_dram_addr <= ir_addr;
		  curr_state <= READWAIT;
		  
		when READWAIT =>
		  sendcmd(cmd_nop);
		  if clkctr > (1) then
		    clkctr <= 0;
			r_out_miso <= dram_dq;
			r_rdy <= '1';
		    curr_state <= INITCOMP;
	      else
			clkctr <= clkctr + 1;
		  end if;
		  
		end case;
	
	end if;
  end process dram_machine;
  
  rdy <= r_rdy;
  out_miso <= r_out_miso;
  
  dram_dqm <= r_dram_dqm;
  dram_dq <= r_dram_dq;
  dram_addr <= r_dram_addr;
  dram_ba <= r_dram_ba;
	
  dram_ncas <= r_dram_ncas;
  dram_cke <= r_dram_cke;
  dram_clk <= iclk;
  dram_ncs <= r_dram_ncs;
  dram_nras <= r_dram_nras;
  dram_nwe <= r_dram_nwe;
  
end RTL;
