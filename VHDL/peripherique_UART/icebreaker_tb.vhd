library IEEE;
use IEEE.std_logic_1164.all;
use work.all;

entity icebreaker_tb is
end icebreaker_tb;

architecture arch_icebreaker_tb of icebreaker_tb is

    signal CLK, BTN_N, BTN1, BTN2, BTN3, TX, LED_RED_N: std_logic;
    constant CLK_period : time := 83333 ns; -- 12000
begin

    icebreaker_0 : entity work.icebreaker
        port map (
            CLK   => CLK,
            BTN_N => BTN_N,
            BTN1  => BTN1,
            BTN2  => BTN2,
            BTN3  => BTN3,
            TX  => TX,
            LED_RED_N  => LED_RED_N
            
        );

    -- Clock definition
    CLK_process : process
    begin
        CLK <= '0';
        wait for CLK_period / 2;
        CLK <= '1';
        wait for CLK_period / 2;
    end process;

     -- Stimuli
    stimuli : process
    begin
        BTN_N <= '0'; -- Reset actif
        wait for 500 us;
        BTN_N <= '1'; -- Fin reset
        wait for 500 us;

        BTN1 <= '1'; BTN2 <= '0'; BTN3 <= '0'; 
        wait for 1 ms;
        
        BTN1 <= '0'; BTN2 <= '1';BTN3 <= '0'; 
        wait for 10 ms;
        BTN1 <= '0'; BTN2 <= '0';BTN3 <= '1'; 
        wait for 60 ms;
        
        BTN1 <= '0'; BTN2 <= '1';BTN3 <= '0'; 
        wait for 10 ms;
        BTN1 <= '0'; BTN2 <= '0';BTN3 <= '1'; 
        wait for 60 ms;

     BTN1 <= '0'; BTN2 <= '1';BTN3 <= '0'; 
        wait for 10 ms;
        BTN1 <= '0'; BTN2 <= '0';BTN3 <= '1'; 
        wait for 60 ms;

     BTN1 <= '0'; BTN2 <= '1';BTN3 <= '0'; 
        wait for 10 ms;
        BTN1 <= '0'; BTN2 <= '0';BTN3 <= '1'; 
        wait for 60 ms;


     BTN1 <= '0'; BTN2 <= '1';BTN3 <= '0'; 
        wait for 10 ms;
        BTN1 <= '0'; BTN2 <= '0';BTN3 <= '1'; 
        wait for 60 ms;



        wait;
    end process;

end arch_icebreaker_tb;
