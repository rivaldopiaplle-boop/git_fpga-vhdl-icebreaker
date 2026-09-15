library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity div_freq is
port( 	clk,reset	:	in std_logic;
			fs		: 	out std_logic
			);
end div_freq;

architecture arch_div_freq of div_freq is
signal count_int : unsigned (23 downto 0);
begin
	process(clk,reset)
		begin
		if reset='1' then count_int <= (others => '0');
		elsif rising_edge(clk) then
				if count_int=x"68" then count_int <= (others => '0'); -- fin de comptage : 104 = 12000000/115200
				else count_int <= count_int + 1; -- "+"(unsigned,int)
				end if;
		end if;
	end process;


fs <= '1' when count_int = x"00" else '0';

end arch_div_freq;

--======================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compteur_2b is
port( 	clk,raz,ce		:	in  std_logic;
	count 			: 	out std_logic_vector(1 downto 0));
end compteur_2b;

architecture arch_compteur_2b of compteur_2b is
signal count_int : unsigned (1 downto 0);
begin
process(clk)
	begin	
	if rising_edge(clk) then
		if raz='1' then count_int <= (others => '0');
		elsif ce='1' then			
			if count_int="11" then count_int <= (others => '0'); -- fin de comptage
			else count_int <= count_int + 1; -- "+"(unsigned,int)
			end if;
		end if;
	end if;
end process;

count <= std_logic_vector(count_int); -- count copie de count_int

end arch_compteur_2b;
--======================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity fsm_icebreaker is
port( clk, reset	 : in std_logic;
		init : in std_logic;
		load : in std_logic;
		send : in std_logic;
		ready : in std_logic;
		start, ld_t, ce, raz_count : out std_logic
		);
end fsm_icebreaker;

architecture arch_fsm_icebreaker of fsm_icebreaker is
type etat_me is (INIT_STATE, LOAD_TAMPON, WAIT_FOR_SEND, SEND_DATA);
signal etat_cr, etat_sv : etat_me;
begin

	process(clk,reset)	-- registre synchrone, maj etat_cr
	begin
		if reset='1' then etat_cr <= INIT_STATE;
		elsif rising_edge(clk) then etat_cr <= etat_sv;
		end if;
	end process;

process(etat_cr, init,load,send, ready)	-- process combinatoire
	begin

etat_sv <= etat_cr; ld_t <= '0'; start <= '0'; ce <= '0'; raz_count <= '0';
	
	case etat_cr is
		when INIT_STATE => 
							if( load = '1' ) then etat_sv <=  LOAD_TAMPON; end if; 						
		
		when LOAD_TAMPON =>  ld_t <= '1'; ce <='1';
							etat_sv <=  WAIT_FOR_SEND;
		
		when WAIT_FOR_SEND => 
							if ( send = '1') then etat_sv <= SEND_DATA; end if;
		
				
		when SEND_DATA => 	 start <= '1';
							if ( init = '1') then 	etat_sv <= INIT_STATE; 
							elsif ( ready = '1' ) then etat_sv <= INIT_STATE; 
							end if;
	
				
	end case;	
	end process;

end arch_fsm_icebreaker;

--======================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rom is
  generic( taille_bit : integer :=2);
  port( addr : in std_logic_vector(taille_bit-1 downto 0);
        data : out std_logic_vector(7 downto 0));
 end rom;
 
architecture arch_rom of rom is
type memory is array(integer range 0 to 2**taille_bit-1) of std_logic_vector(7 downto 0);
    constant mem : memory :=(
		x"61", x"62", x"63", x"64"
  );
  begin  
    data <= mem(to_integer(unsigned(addr)));
end arch_rom;

--======================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use work.all;

entity icebreaker is
port( CLK, BTN_N : std_logic ; 
		BTN1, BTN2, BTN3, RX : in std_logic;
		LED1, LED2, LED3, LED4, TX : out std_logic ;
	   P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10, LED_RED_N : out std_logic
	   );
end icebreaker;

architecture arch_icebreaker of icebreaker is

signal comptage : std_logic_vector( 1 downto 0 );
signal data_to_send : std_logic_vector( 7 downto 0);
signal clk_baudrate, reset, start, ready, ld_t, ce, raz_count : std_logic;

begin

reset <= not(BTN_N);


fsm_icebreaker0 : entity fsm_icebreaker port map (
		clk => CLK, 
		reset => reset, 
		init => BTN1,
		load => BTN2,
		send => BTN3,
		ready => ready,
		start => start, 
		ld_t => ld_t,
		ce => ce,
		raz_count => raz_count
);


div_freq0 : entity div_freq port map (
clk => CLK,
reset => reset,	
fs	=> clk_baudrate	
);


uart0 : entity uart port map (
clk => CLK,
reset => reset,	
start => start,
ld_t => ld_t,
data_to_send => data_to_send,
ready => ready,
tx => TX, 
tx_test => LED_RED_N
);

compteur_2b0 : entity compteur_2b port map (
clk => CLK,
raz => reset,
ce => ce,
count 	=> comptage
);

rom0 : entity rom  generic map(2) port map (
addr => comptage,
data => data_to_send
);


end arch_icebreaker;


