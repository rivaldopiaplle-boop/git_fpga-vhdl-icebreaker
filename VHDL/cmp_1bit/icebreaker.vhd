-- Pressing button 1 (A) and/or 2 (B) will compare the two signals
-- and enable one of the built-in LEDs:
--      A < B: L2
--      A = B: L1
--      A > B: L3

library IEEE;
use IEEE.std_logic_1164.all;

entity cmp_1_bit is
port(  but1, but2, clk, reset: in std_logic;
		led1, led2, led3 : out std_logic
		);
end entity cmp_1_bit;

architecture arch_cmp_1_bit of cmp_1_bit is
begin

process(clk, reset)
begin
	if reset = '1' then led1 <= '0'; led2 <= '0'; led3 <= '0';
	elsif rising_edge(clk) then
		if (but1 = '1' and but2 = '0')  then led1 <= '1'; led2 <= '0'; led3 <= '0';
		elsif (but1 = but2) then led1 <= '0'; led2 <= '1'; led3 <= '0';
		elsif (but1 = '0' and but2 = '1') then led1 <= '0'; led2 <= '0'; led3 <= '1';
		else led1 <= '0'; led2 <= '0'; led3 <= '0';
		end if;
	end if;	
end process;

end arch_cmp_1_bit;
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
signal reset : std_logic;
begin

reset <= not(BTN_N);

cmp_1_bit0 : entity cmp_1_bit port map (
	but1 => BTN1, 
	but2 => BTN2,
	clk  => CLK,
	reset=> reset,
	led1 => LED1,
	led2 => LED2,
	led3 => LED3
);

end arch_icebreaker;
--======================================================================
