library IEEE;
use IEEE.std_logic_1164.all;
use work.all;

entity icebreaker_tb is
end icebreaker_tb;

architecture arch_icebreaker_tb of icebreaker_tb is

    signal BTN1, BTN2, BTN_N, LED1, LED2, LED3, CLK  : std_logic;
    constant CLK_period : time := 83333 ns; -- 12000
begin

    icebreaker_0 : entity work.icebreaker
        port map (
            CLK   => CLK,
            BTN_N => BTN_N,
            BTN1  => BTN1,
            BTN2  => BTN2,
            LED1  => LED1,
            LED2  => LED2,
            LED3  => LED3
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

        wait;
    end process;

end arch_icebreaker_tb;
