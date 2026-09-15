library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg_tampon is
port(
  load, reset, clk   : in  std_logic;
  d_in				 : in  std_logic_vector(7 downto 0);
  d_out    			 : out std_logic_vector(7 downto 0)
);
end reg_tampon;

architecture arch_reg_tampon of reg_tampon is
begin
  process(clk, reset)
  begin
    if reset = '1' then
      d_out <= (others => '0');
    elsif rising_edge(clk) then
		if ( load = '1' ) then
			d_out <= d_in ; 
		end if;
	end if;
  end process;

end arch_reg_tampon;

--======================================================================


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compteur_baudrate is
port(
  clk, ce, raz : in  std_logic;
  count      : out std_logic_vector(7 downto 0)
);
end compteur_baudrate;

architecture arch_compteur_baudrate of compteur_baudrate is
  signal count_int : unsigned(7 downto 0);
begin
  process(clk, raz, ce)
  begin
	if rising_edge(clk) then
		if raz = '1' then count_int <= (others => '0');
		elsif ( ce = '1' ) then
		  if count_int = 52 - 1 then  --On consacre 52 coups d’horloge pour envoyer 1 bit :
			count_int <= (others => '0'); -- fin de comptage
		  else
			count_int <= count_int + 1; -- "+" (unsigned, int)
		  end if;
		end if;  
	end if; 
   
  end process;

  count <= std_logic_vector(count_int); -- copie de count_int
end arch_compteur_baudrate;

--======================================================================--


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compteur_nb_bits is
port(
  clk, ce, raz : in  std_logic;
  count      : out std_logic_vector(7 downto 0)
);
end compteur_nb_bits;

architecture arch_compteur_nb_bits of compteur_nb_bits is
  signal count_int : unsigned(7 downto 0);
begin
  process(clk, raz, ce)
    begin
	if rising_edge(clk) then
		if raz = '1' then count_int <= (others => '0');
		elsif ( ce = '1' ) then
		  if count_int = 10 then  --Fclk/baudrate-1
			count_int <= (others => '0'); -- fin de comptage
		  else
			count_int <= count_int + 1; -- "+" (unsigned, int)
		  end if;
		end if;  
    end if; 
  end process;

  count <= std_logic_vector(count_int); -- copie de count_int
end arch_compteur_nb_bits;

--======================================================================--
library IEEE;
use IEEE.std_logic_1164.all;

entity fsm_serial is 
port( 
	clk, reset, start : in std_logic;
	count_baudrate, count_nb_bits : in std_logic_vector(7 downto 0);
	ce_baudrate, raz_baudrate, ce_nb_bits, raz_nb_bits : out std_logic;
	ready, raz_ser, id_ser, ser : out std_logic
	);
end fsm_serial;


architecture arch_fsm_serial of fsm_serial is
type etat_fsm_serial is (INIT, LOAD_SER, SERIALIZE, WAIT_BAUD);
signal etat_cr, etat_sv : etat_fsm_serial;
begin 	
	
	process(clk,reset)	-- registre synchrone, maj etat_cr
	begin
		if reset='1' then etat_cr <= INIT;
		elsif rising_edge(clk) then etat_cr <= etat_sv;
		end if;
	end process;

process(start, count_baudrate, count_nb_bits, etat_cr)
begin
	ce_baudrate <= '0'; raz_baudrate <= '0'; ce_nb_bits <= '0'; raz_nb_bits <= '0'; 
	ready <= '0'; raz_ser <= '0'; id_ser <= '0'; ser <= '0';  etat_sv <= etat_cr;
	
	case etat_cr is
		when INIT =>if start = '1' then etat_sv <= LOAD_SER; end if; 
						raz_nb_bits <= '1'; raz_ser <= '1'; ready <= '1';
		when LOAD_SER =>   etat_sv <= SERIALIZE; 
						id_ser <= '1'; 
		when SERIALIZE =>  if count_nb_bits < x"0a" then etat_sv <= WAIT_BAUD; 
						   elsif  count_nb_bits = x"0a" then etat_sv <= INIT; end if;
							ser <= '1'; ce_nb_bits <= '1'; raz_baudrate <= '1';
		when WAIT_BAUD =>  if count_baudrate = x"33" then etat_sv <= SERIALIZE; end if; 
						ce_baudrate <= '1';
	end case;
end process;	

end arch_fsm_serial;

--======================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg_serial is
port(
  rotate, load, raz, clk   : in  std_logic;
  d_in				 : in  std_logic_vector(7 downto 0);
  tx, tx_test   			 : out std_logic
  );
end reg_serial;

architecture arch_reg_serial of reg_serial is
signal register_serial 				 : unsigned(9 downto 0);
begin
  process(clk, raz, load, rotate)
    begin
    if rising_edge(clk) then
		if raz = '1' then register_serial <= (others => '0');
		elsif ( load = '1' ) then
		register_serial(0) <= '1'; register_serial(1) <= '0';
		register_serial(9 downto 2) <= unsigned(d_in);
		elsif rotate = '1' then
		register_serial <= rotate_right(register_serial,1);
		end if;  
    end if;
  end process;
  tx 	  <= register_serial(0) ;
  tx_test <= register_serial(0) ;
  
end arch_reg_serial;



--======================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use work.all;

entity uart is
port(   clk, reset : std_logic ; 
		start, ld_t 		: in std_logic;
		data_to_send 		: in std_logic_vector(7 downto 0);
		ready, tx, tx_test  : out std_logic
	   );
end uart;

architecture arch_uart of uart is
signal tamp_out 				 : std_logic_vector(7 downto 0);
signal ce_baudrate, raz_baudrate : std_logic;
signal count_baudrate 			 : std_logic_vector(7 downto 0);
signal ce_nb_bits, raz_nb_bits   : std_logic;
signal count_nb_bits 			 : std_logic_vector(7 downto 0);
signal raz_ser, id_ser, ser , raz	 : std_logic;

begin




reg_tampon0 : entity reg_tampon port map (
load => ld_t,
reset => reset,
clk => clk,
d_in => data_to_send,
d_out => tamp_out
);

compteur_baudrate0 : entity compteur_baudrate port map (
clk => clk,
ce => ce_baudrate,
raz => raz_baudrate,
count => count_baudrate
);

compteur_nb_bits0 : entity compteur_nb_bits port map (
clk => clk,
ce => ce_nb_bits,
raz => raz_nb_bits,
count => count_nb_bits
);

fsm_serial0 : entity fsm_serial port map (
clk => clk,
reset => reset,
start => start,
count_baudrate => count_baudrate,
count_nb_bits => count_nb_bits,
ce_baudrate => ce_baudrate,
raz_baudrate => raz_baudrate,
ce_nb_bits => ce_nb_bits,
raz_nb_bits => raz_nb_bits,
ready => ready,
raz_ser => raz_ser,
id_ser => id_ser,
ser => ser
);


reg_serial0 : entity reg_serial port map (
rotate => ser,
load => id_ser,
raz => raz_ser,
clk => clk,
d_in => tamp_out,
tx => tx,
tx_test => tx_test
);


end arch_uart;







