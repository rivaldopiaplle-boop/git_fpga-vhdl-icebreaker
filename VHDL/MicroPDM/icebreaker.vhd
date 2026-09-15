

--======================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compteur_2b is
port(
  clk, ce, raz : in  std_logic;
  count      : out std_logic_vector(1 downto 0)
);
end compteur_2b;

architecture arch_compteur_2b of compteur_2b is
  signal count_int : unsigned(1 downto 0);
begin
  process(clk)
  begin
   
    if rising_edge(clk) then
		if raz = '1' then count_int <= (others => '0');
		elsif ( ce = '1' ) then
		  if count_int = 3 then
			count_int <= (others => '0'); -- fin de comptage
		  else
			count_int <= count_int + 1; -- "+" (unsigned, int)
		 end if;
		end if;
	end if;
  end process;

  count <= std_logic_vector(count_int); -- copie de count_int
end arch_compteur_2b;

--======================================================================--



library IEEE;
use IEEE.std_logic_1164.all;

entity fsm_icebreaker is 
port( 
	clk, reset, init, run, send, ready : in std_logic;
	start, ce, raz_count, ld_t : out std_logic
	);
end fsm_icebreaker;


architecture arch_fsm_icebreaker of fsm_icebreaker is
type etat_fsm_icebreaker is (INITIATION, NEXT_CAR, LOAD_TAMPON, WAIT_FOR_SEND, SEND_DATA, WAIT_FOR_RDY);
signal etat_cr, etat_sv : etat_fsm_icebreaker;
begin 	
	
	process(clk,reset)	-- registre synchrone, maj etat_cr
	begin
		if reset='1' then etat_cr <= INITIATION;
		elsif rising_edge(clk) then etat_cr <= etat_sv;
		end if;
	end process;

process(init, load, send, ready, etat_cr)
begin
	start <= '0'; ce <= '0'; raz_count <= '0'; ld_t <= '0';  etat_sv <= etat_cr;
	
	case etat_cr is
		when INITIATION =>etat_sv <= NEXT_CAR; 
						raz_count <= '1';
		when NEXT_CAR =>   if load = '1' then etat_sv <= LOAD_TAMPON; end if; 
						
		when LOAD_TAMPON =>  etat_sv <= WAIT_FOR_SEND; 
								ld_t <= '1'; ce <= '1'; 
		when WAIT_FOR_SEND =>   if init = '1' then etat_sv <= NEXT_CAR;
								elsif  send = '1' then etat_sv <= SEND_DATA; end if;
		when SEND_DATA =>   etat_sv <= WAIT_FOR_RDY;  
						start <= '1';
		when WAIT_FOR_RDY =>  if ready = '1' then etat_sv <= NEXT_CAR; end if; 
		
	end case;
end process;	

end arch_fsm_icebreaker;

--======================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity div_freq is
port( 	clk,reset	:	in std_logic;
			fs		: 	out std_logic );
end div_freq;

architecture arch_div_freq of div_freq is
signal count_int : unsigned (3 downto 0);
begin
	process(clk,reset)
		begin
		if reset='1' then count_int <= (others => '0');
		elsif rising_edge(clk) then
				if count_int=   12 -1 --### A COMPLETER ###-- N =F_clk / F_fs=12MHZ/1MHZ
					then count_int <= (others => '0'); 
					else count_int <= count_int + 1; -- "+"(unsigned,int)
				end if;
		end if;
	end process;

fs <= count_int(3);

end div_freq;

--======================================================================--
entity average_filter is
    generic( SIZE  : integer := 3 ); -- Moyenne sur 2^SIZE échantillons
    port( 
        clk    : in std_logic;
        reset  : in std_logic;
        d_in  : in std_logic;
        d_out : out std_logic_vector(7 downto 0)
    );
end average_filter;

architecture arch_average_filter of average_filter is
    type t_pile is array(integer range 0 to 2**SIZE-1) of unsigned(7 downto 0);
    signal pile     : t_pile;
    signal new_ech  : unsigned(7 downto 0);

begin
    -- Détection de la nouvelle entrée d_in
    new_ech <= "11111111" when d_in = '1' else "00000000";

    process(clk, reset)
        variable acc_v : unsigned(SIZE+7 downto 0);
    begin
        if reset = '1' then
            -- Réinitialisation de la pile à zéro
            for i in 0 to (2**SIZE)-1 loop
                pile(i) <= "00000000";
            end loop;
average_filter
        elsif rising_edge(clk) then
            -- Décalage de tous les éléments de la pile
            for i in 0 to 2**SIZE-2 loop
                pile(i+1) <= pile(i);
            end loop;
            -- Ajout du nouvel échantillon à la position 0
            pile(0) <= new_ech;
            
            -- Calcul de la moyenne
            acc_v := (others => '0');   
            for i in 0 to 2**SIZE-1 loop
                acc_v := acc_v + pile(i);
            end loop;

            -- Division par N (2^SIZE) en décalant à droite
            d_out <= std_logic_vector(acc_v(7+SIZE downto SIZE));
        end if;average_filter
    end process;
end arch_average_filter;







--======================================================================



library IEEE;
use IEEE.std_logic_1164.all;
use work.all;

entity icebreaker is
port( CLK, BTN_N : std_logic ; 
		BTN1, BTN2, P1B1, : in std_logic;
		TX, LED_RED_N, P1B2: out std_logic 
	   );
end icebreaker;

architecture arch_icebreaker of icebreaker is

signal ce, raz_count,reset : std_logic ;
signal comptage : std_logic_vector(1 downto 0) ;
signal start, ld_t,ready : std_logic ;
signal  data_to_send : std_logic_vector(7 downto 0) ;
signal clk_1us : std_logic ;



begin 

reset <= not(BTN_N); 	


compteur_2b_0 : entity compteur_2b port map (
clk => CLK,
ce => ce,
raz => raz_count,
count => comptage
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

fsm_icebreaker0 : entity fsm_icebreaker port map (
clk => CLK,
reset => reset,
start => start,
ld_t => ld_t,
init => BTN1,
ready => ready,
load => BTN2,
send => BTN3,
ce => ce,
raz_count => raz_count
);

div_freq0 : entity  div_freq port map (
clk => CLK,
reset => reset,
fs => clk_1us
);

average_filter0 : entity average_filter generic map(8) port map (
clk => clk_micro,
reset => reset,
d_in => P1B1,
d_out => data_to_send
);

end arch_icebreaker;





