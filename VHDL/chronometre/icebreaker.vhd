
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity div_freq_1s is
port( 	clk,reset	:	in std_logic;
			fs		: 	out std_logic;
		fs_sym		: 	out std_logic);
end div_freq_1s;

architecture arch_div_freq_1s of div_freq_1s is
signal count_int : unsigned (23 downto 0);
begin
	process(clk,reset)
		begin
		if reset='1' then count_int <= (others => '0');
		elsif rising_edge(clk) then
				if count_int=   12000000 -1 --### A COMPLETER ###-- N =F_clk / F_fs=12MHZ/1KHZ
					then count_int <= (others => '0'); 
					else count_int <= count_int + 1; -- "+"(unsigned,int)
				end if;
		end if;
	end process;

fs_sym <= '1' when count_int < 6000000---### A COMPLETER ###-- N/2-1
	 else '0';
fs <= count_int(23);

end arch_div_freq_1s;

--======================================================================--


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compteur is
port(
  clk, reset, ce, raz : in  std_logic;
  count      : out std_logic_vector(7 downto 0)
);
end compteur;

architecture arch_compteur of compteur is
  signal count_int : unsigned(7 downto 0);
begin
  process(clk, reset)
  begin
    if reset = '1' then
      count_int <= (others => '0');
    elsif rising_edge(clk) then
		if raz = '1' then count_int <= (others => '0');
		elsif ( ce = '1' ) then
		  if count_int = 99 then
			count_int <= (others => '0'); -- fin de comptage
		  else
			count_int <= count_int + 1; -- "+" (unsigned, int)
		  end if;
		end if;  
    end if;
  end process;

  count <= std_logic_vector(count_int); -- copie de count_int
end arch_compteur;

--======================================================================--

library IEEE;
use IEEE.std_logic_1164.all;

entity dec_sev_seg is
port( din :  in std_logic_vector( 3 downto 0 );
		dout : out std_logic_vector ( 6 downto 0));
end dec_sev_seg;		
		
architecture arch_dec_sev_seg of dec_sev_seg is
signal conv : std_logic_vector( 6 downto 0);
begin  -- GFEDCBA

	conv <= "0111111" when din = x"0"
	else	"0000110" when din = x"1"
	else	"1011011" when din = x"2"
	else	"1001111" when din = x"3"
    --## A COMPLETER ##--
    else	"1100110" when din = x"4"
	else	"1101101" when din = x"5"
	else	"1111101" when din = x"6"
	else	"0000111" when din = x"7"
	else	"1111111" when din = x"8"
	else	"1101111" when din = x"9"
	else	"1110111" when din = x"A"
	else	"1111100" when din = x"B"
	else	"0111001" when din = x"C"
	else	"1011110" when din = x"D"

    
	else	"1111001" when din = x"E"
	else	"1110001" when din = x"F"
	else	"0000000"; 		
dout <= not(conv);				

end arch_dec_sev_seg;


--======================================================================  

library IEEE;
use IEEE.std_logic_1164.all;

entity state_machine is
port( reset, clk, btn_init, btn_run, btn_pause:  in std_logic;
		raz, cen, led_i, led_r, led_p  : out std_logic);
end state_machine;

architecture arch_state_machine of state_machine is

type etat_machine is (INIT_STATE, RUN_STATE, PAUSE_STATE);
signal etat_cr, etat_sv : etat_machine ;
begin 

	process(clk,reset)	-- registre synchrone, maj etat_cr
	begin
		if reset='1' then etat_cr <= INIT_STATE;
		elsif rising_edge(clk) then etat_cr <= etat_sv;
		end if;
	end process;

process( etat_cr, btn_init, btn_run, btn_pause)
begin
	led_i <= '0'; led_r <= '0'; led_p <= '0'; cen <= '0'; raz <= '0'; etat_sv <= etat_cr;
	
	case etat_cr is
		when INIT_STATE => if btn_run = '1' then etat_sv <= RUN_STATE; end if; 
							raz <= '1'; led_i <= '1';
		when RUN_STATE =>  if btn_init = '1' then etat_sv <= INIT_STATE; 
						   elsif ( btn_pause = '1'  and  btn_init = '0' ) then etat_sv <= PAUSE_STATE; end if;
							led_r <= '1'; cen <= '1';
		when PAUSE_STATE =>  if btn_init = '1' then etat_sv <= INIT_STATE;
							elsif ( btn_run = '1'  and  btn_init = '0' ) then etat_sv <= RUN_STATE; end if;
							led_p <= '1';
	
	end case;
end process;

end arch_state_machine;

--======================================================================  

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity count_split is
port( din:  in std_logic_vector ( 7 downto 0);
	  msb_nibble, lsb_nibble : out std_logic_vector ( 3 downto 0));
end count_split;

architecture arch_count_split of count_split is

signal result : unsigned( 7 downto 0);
signal result2 : unsigned( 7 downto 0);

begin

result <= unsigned(din)/10;
result2 <= unsigned(din) mod 10;

msb_nibble <= std_logic_vector(result(3 downto 0));

lsb_nibble <= std_logic_vector(result2(3 downto 0));

end arch_count_split;
--======================================================================  


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity div_freq_255 is
port( 	clk,reset	:	in std_logic;
		fs_sym		: 	out std_logic);
end div_freq_255;

architecture arch_div_freq_255 of div_freq_255 is
signal count_int : unsigned (23 downto 0);
begin
	process(clk,reset)
		begin
		if reset='1' then count_int <= (others => '0');
		elsif rising_edge(clk) then
				if count_int=   47000-1 --### A COMPLETER ###-- N =F_clk / 255=12MHZ/255HZ
					then count_int <= (others => '0'); 
					else count_int <= count_int + 1; -- "+"(unsigned,int)
				end if;
		end if;
	end process;

fs_sym <= '1' when count_int < 23500---### A COMPLETER ###-- N/2-1
	 else '0';
end arch_div_freq_255;

--======================================================================--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mux is
port( 	e0, e1  : 	in std_logic_vector ( 3 downto 0);
		sel		:	in std_logic;
		s  		: 	out std_logic_vector ( 3 downto 0));
end mux;

architecture arch_mux of mux is
begin
	
	s <= e0 when sel = '0' else e1;
end arch_mux;

--======================================================================--

library IEEE;
use IEEE.std_logic_1164.all;
use work.all;

entity icebreaker is
port( CLK, BTN_N : std_logic ; 
		BTN1, BTN2, BTN3 : in std_logic;
		LED1, LED2, LED3, LED4 : out std_logic ;
	   P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10 : out std_logic
	   );
end icebreaker;

architecture arch_icebreaker of icebreaker is

signal reset, clk_count, clk_sym_1s : std_logic ;
signal dash : std_logic;
signal count : std_logic_vector(7 downto 0);
signal sev_seg : std_logic_vector(6 downto 0);
signal raz : std_logic;
signal ce : std_logic;
signal msb_nibble : std_logic_vector(3 downto 0);
signal lsb_nibble : std_logic_vector(3 downto 0);
signal fs_255s  : std_logic;
signal nibble : std_logic_vector(3 downto 0);
begin 

reset <= not(BTN_N); 	
	
div_freq0 : entity  div_freq_1s port map (
clk => CLK,
reset => reset,
fs => clk_count,
fs_sym => LED1
);

compteur0 : entity compteur port map (
clk => clk_count,
reset => reset,
ce => ce,
raz => raz,
count => count
);

dec_sev_seg0 : entity dec_sev_seg port map (
din => nibble,
dout => sev_seg
);	

P1A10 <= fs_255s;

P1A1 <= sev_seg(0);
P1A2 <= sev_seg(1);
P1A3 <= sev_seg(2);
P1A4 <= sev_seg(3);
P1A7 <= sev_seg(4);
P1A8 <= sev_seg(5);
P1A9 <= sev_seg(6);

state_machine0 : entity state_machine port map (
clk => CLK,
reset => reset,
cen => ce,
raz => raz,
btn_init => BTN1,
btn_run => BTN2,
btn_pause => BTN3,
led_i => LED2,
led_r => LED3,
led_p => LED4
);

count_split0 : entity count_split port map (
din => count,
msb_nibble => msb_nibble,
lsb_nibble => lsb_nibble
);

div_freq1 : entity  div_freq_255 port map (
clk => CLK,
reset => reset,
fs_sym => fs_255s 
);

mux0 : entity  mux port map (
e0 => msb_nibble,
e1 => lsb_nibble,
sel => fs_255s, 
s => nibble  
);


end arch_icebreaker;
