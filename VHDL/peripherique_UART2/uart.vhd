-- F_ice = 12 MHz
-- Baudrate = 230400
-- F_ice/Baudrate = 12e6/230400 = 52 = 0x34
--   


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compteur_nb_bits is
port( 	clk,raz,ce		:	in  std_logic;
	count 			: 	out std_logic_vector(3 downto 0));
end compteur_nb_bits;

architecture arch_compteur_nb_bits of compteur_nb_bits is
signal count_int : unsigned (3 downto 0);
begin
process(clk)
	begin	
	if rising_edge(clk) then
		if raz='1' then count_int <= (others => '0');
		elsif ce='1' then			
			if count_int="1111" then count_int <= (others => '0'); -- fin de comptage
			else count_int <= count_int + 1; -- "+"(unsigned,int)
			end if;
		end if;
	end if;
end process;

count <= std_logic_vector(count_int); -- count copie de count_int

end arch_compteur_nb_bits;



--======================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compteur_baudrate is
port( 	clk,raz,ce		:	in  std_logic;
	count 			: 	out std_logic_vector(7 downto 0));
end compteur_baudrate;

architecture arch_compteur_baudrate of compteur_baudrate is
signal count_int : unsigned (7 downto 0);
begin
process(clk)
	begin	
	if rising_edge(clk) then
		if raz='1' then count_int <= (others => '0');
		elsif ce='1' then			
			if count_int="11111111" then count_int <= (others => '0'); -- fin de comptage
			else count_int <= count_int + 1; -- "+"(unsigned,int)
			end if;
		end if;
	end if;
end process;

count <= std_logic_vector(count_int); -- count copie de count_int

end arch_compteur_baudrate;
--======================================================================




library IEEE;
use IEEE.std_logic_1164.all;

entity registre_tampon is
port( 	clk,reset,load	:	in std_logic;
	d_in 		: 	in std_logic_vector(7 downto 0);
	d_out 		: 	out std_logic_vector(7 downto 0));
end registre_tampon;

architecture arch_registre_tampon of registre_tampon is
begin
	process(clk,reset)
		begin
		if reset='1' then d_out <= "00000000";
		elsif rising_edge(clk) then 
			if load='1' then d_out <= d_in;
			end if;
		end if;
	end process;
end arch_registre_tampon;
--======================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg_serial is
port( raz, clk, load, rotate : in std_logic;
	d_in : in std_logic_vector(7 downto 0);
	tx : out std_logic;
	tx_test : out std_logic);
end reg_serial;

architecture arch_reg_serial of reg_serial is

signal interne : unsigned( 10 downto 0);

begin

process(clk)
begin
	if rising_edge(clk) then
		if raz = '1' then interne <= "00000000011";
		elsif load = '1' then interne <= unsigned(d_in)&"011";
		elsif rotate = '1' then interne <= rotate_right(interne, 1 );
		end if;
	end if;
end process;

TX <= interne(0);
TX_test <= interne(0);

end arch_reg_serial;
--======================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity fsm_serial is
port( clk, reset, start : in std_logic;
	count_nb_bits : in std_logic_vector (3 downto 0);
	count_baudrate : in std_logic_vector (7 downto 0);
	raz_ser, ld_ser, ser, raz_count_nb_bits, ce_count_nb_bits, raz_count_baudrate, ce_count_baudrate, ready : out std_logic);
end fsm_serial;

architecture arch_fsm_serial of fsm_serial is

type STATE_T is (INIT, LOAD_SER, SERIALIZE, WAIT_BAUD);
signal etat_cr, etat_sv : STATE_T;
begin

	      
		 process(clk, reset)
		      begin
		      if reset = '1' then etat_cr <= INIT;
		      elsif rising_edge(clk) then  etat_cr <= etat_sv;
		      end if;
		 end process;
    
   
       process(etat_cr,start, count_nb_bits, count_baudrate)

           begin
               

      raz_ser <= '0';
      ld_ser <= '0';
      ser <= '0';
      raz_count_nb_bits <= '0';
        raz_count_baudrate <= '0';
      ce_count_baudrate <= '0';
       ce_count_nb_bits <= '0';
      ready <= '0';
         
          etat_sv <=etat_cr ;
          
                   case etat_cr is
                       
                       when INIT =>if start='1' then etat_sv<=LOAD_SER;  end if;                         
                       raz_count_nb_bits <= '1'; ready <= '1';--raz_ser <= '1'; 
                         
                       when LOAD_SER =>etat_sv<=SERIALIZE;                         
                      ld_ser <= '1' ;
                         
                       when SERIALIZE=>if count_nb_bits=x"A" then etat_sv<=INIT; 
													else etat_sv <= WAIT_BAUD;
													end if;
                      ser <= '1';  ce_count_nb_bits <= '1'; raz_count_baudrate <= '1';
                      
                       when WAIT_BAUD=>if count_baudrate=x"33" then etat_sv<=SERIALIZE; 
													end if;                              
                        ce_count_baudrate <= '1';
                            
                end case;
      
        end process;

end arch_fsm_serial;
--======================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use work.all;

entity uart is
port( 	clk, reset, start, ld_t : in std_logic;
		data_to_send : in std_logic_vector(7 downto 0);
		ready, tx: out std_logic;
		tx_test : out std_logic);
end uart;


architecture arch_uart of uart is
signal raz_ser, ld_ser, ser, ce_count_nb_bits, raz_count_nb_bits : std_logic;
signal ce_count_baudrate, raz_count_baudrate : std_logic;
signal count_nb_bits : std_logic_vector(3 downto 0);
signal count_baudrate : std_logic_vector(7 downto 0);
signal tamp_out : std_logic_vector(7 downto 0);


begin


tampon:		entity registre_tampon port map(
			clk		=> clk,
			reset		=> reset,
			load		=> ld_t,
			d_in 		=> data_to_send,
			d_out 		=> tamp_out
			);



fsm_serial0:	entity fsm_serial port map(
			clk		=> clk,
			reset		=> reset,
			start		=> start,
			count_nb_bits 	=> count_nb_bits,
			count_baudrate 	=> count_baudrate,
			raz_ser		=> raz_ser,
			ld_ser		=> ld_ser,
			ser		=> ser,
			raz_count_nb_bits	=> raz_count_nb_bits,
			ce_count_nb_bits 		=> ce_count_nb_bits,
			raz_count_baudrate	=> raz_count_baudrate,
			ce_count_baudrate 		=> ce_count_baudrate,
			ready => ready
			);







compt_nb_bits0:		entity compteur_nb_bits port map(
			clk		=> clk,
			raz		=> raz_count_nb_bits,
			ce		=> ce_count_nb_bits,
			count 		=> count_nb_bits
			);

compt_baudrate0:		entity compteur_baudrate port map(
			clk		=> clk,
			raz		=> raz_count_baudrate,
			ce		=> ce_count_baudrate,
			count 		=> count_baudrate
			);


reg_ser:	entity reg_serial port map(
			raz		=> raz_ser,
			clk		=> clk,
			load		=> ld_ser,
			rotate		=> ser,
			d_in 		=> tamp_out,
			TX		=> tx,
			TX_test => tx_test
			);
			
end arch_uart;
--======================================================================


