library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compteur is
port(
  clk, reset, ce, raz : in  std_logic;
  count      : out std_logic_vector(27 downto 0)
);
end compteur;

architecture arch_compteur of compteur is
  signal count_int : unsigned(27 downto 0);
begin
  process(clk, reset)
  begin
    if reset = '1' then
      count_int <= (others => '0');
    elsif rising_edge(clk) then
		if raz = '1' then count_int <= (others => '0');
		elsif ( ce = '1' ) then
		  if count_int = x"FFFFFFF" then
			count_int <= (others => '0'); -- fin de comptage
		  else
			count_int <= count_int + 1; -- "+" (unsigned, int)
		  end if;
		end if;  
    end if;
  end process;

  count <= std_logic_vector(count_int); -- copie de count_int
end arch_compteur;

library IEEE;
use IEEE.std_logic_1164.all;

entity me is 
port( 
	clk, reset : in std_logic;
	count : in std_logic_vector(27 downto 0);
	led1, led2, led3, ce, raz : out std_logic
	);
end me;

architecture arch_me of me is
type etat_me is (INIT, LED_1, LED_2, LED_3);
signal etat_cr, etat_sv : etat_me;
begin 	
	
	process(clk,reset)	-- registre synchrone, maj etat_cr
	begin
		if reset='1' then etat_cr <= LED_1;
		elsif rising_edge(clk) then etat_cr <= etat_sv;
		end if;
	end process;

process(count, etat_cr)
begin
	led1 <= '0'; led2 <= '0'; led3 <= '0'; ce <= '0'; raz <= '0'; etat_sv <= etat_cr;
	
	case etat_cr is
		when INIT => etat_sv <= LED_1;
						raz <= '1';
		when LED_1 =>  if count = x"0B71B00" then etat_sv <= LED_2; end if; --"0B71B00" "0002EE0"
						led1 <= '1'; ce <= '1';
		when LED_2 =>  if count = x"16E3600" then etat_sv <= LED_3; end if; --"16E3600" "0005DC0"
						led2 <= '1'; ce <= '1';
		when LED_3 =>  if count = x"2255100" then etat_sv <= INIT; end if; --"2255100" "0008CA0"
						led3 <= '1'; ce <= '1';
	end case;
end process;	

end arch_me;

--======================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use work.all;

entity icebreaker is
port( CLK, BTN_N : std_logic ; 
		BTN1, BTN2 : in std_logic;
		LED1, LED2, LED3 : out std_logic
	   );
end icebreaker;

architecture arch_icebreaker of icebreaker is
signal reset, ce, raz : std_logic;
signal count : std_logic_vector(27 downto 0);
begin

reset <= not(BTN_N);

compteur0 : entity compteur port map (
clk => CLK,
reset => reset,
ce => ce,
raz => raz,
count => count
);

me0 : entity me port map (
clk => CLK, 
reset => reset,
count => count,	
led1 => LED1,
led2 => LED2,
led3 => LED3,
ce => ce,
raz => raz
);

end arch_icebreaker;
