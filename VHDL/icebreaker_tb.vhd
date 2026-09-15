library IEEE;
use IEEE.std_logic_1164.all;
use work.all;

entity uart_tb is
end uart_tb;

architecture arch_uart_tb of uart_tb is

    signal clk, reset, start, ld_t , ready, tx, tx_test  : std_logic;
    signal data_to_send						 : std_logic_vector(7 downto 0);   
    constant CLK_period : time := 83333 ns; -- 12000
begin
    uart_0 : entity work.uart port map(
            clk   	=> clk,
            reset 	=> reset,
            start   => start,
            ld_t  	=> ld_t,
            ready   => ready,
            tx 		=> tx,
            tx_test => tx_test,
            data_to_send => data_to_send
        );

    -- Clock definition
    CLK_process : process
    begin
        clk <= '0';
        wait for CLK_period / 2;
        clk <= '1';
        wait for CLK_period / 2;
    end process;

    -- Stimuli
    stimuli : process
    begin
        reset <= '1'; -- Reset actif
        wait for 500 us;
        reset <= '0'; -- Fin reset
        wait for 500 us;	
        start <= '0';  ld_t <= '0'; data_to_send <= "01110100"; 
        wait for 5 ms;
        start <= '1'; ld_t <= '0'; data_to_send <= "01110100"; 
        wait for 50 ms;
        start <= '0'; ld_t <= '1'; data_to_send <= "01110100"; 
        wait for 50 ms;
        start <= '0'; ld_t <= '1'; data_to_send <= "01110100"; 
        wait for 50 ms;
        

        wait;
    end process;

end arch_uart_tb;
