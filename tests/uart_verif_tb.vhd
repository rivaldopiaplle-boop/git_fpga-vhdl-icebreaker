-- Banc de test auto-vérifiant de l'UART (uart/uart.vhd), ajouté à la reprise.
--
-- Les bancs de test d'origine produisent des chronogrammes à lire à l'oeil.
-- Celui-ci joue le rôle du PC branché sur la liaison série : il décode la
-- ligne TX et vérifie, par des assertions, que chaque octet envoyé est bien
-- celui reçu, trame comprise (bit de départ, 8 bits de poids faible en
-- premier, bit d'arrêt), et que le débit tient dans la tolérance d'une UART.
-- Une assertion en échec fait échouer la chaîne d'intégration.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_verif_tb is
end uart_verif_tb;

architecture verification of uart_verif_tb is
    constant PERIODE_HORLOGE : time := 83_333 ps;  -- 12 MHz, comme la carte
    constant DEBIT_VISE      : real := 230_400.0;  -- bauds
    constant TOLERANCE       : real := 0.03;       -- 3 % : marge usuelle d'une UART

    type octets_t is array (natural range <>) of std_logic_vector(7 downto 0);
    constant OCTETS : octets_t := (x"55", x"A3", x"00", x"FF", x"4B");

    signal clk, reset, start, ld_t : std_logic := '0';
    signal donnee      : std_logic_vector(7 downto 0) := (others => '0');
    signal ready, tx   : std_logic;
    signal fin_emission : boolean := false;
begin
    dut : entity work.uart port map(
        clk => clk, reset => reset, start => start, ld_t => ld_t,
        data_to_send => donnee, ready => ready, tx => tx, tx_test => open);

    horloge : process
    begin
        if fin_emission then
            wait;
        end if;
        clk <= '0'; wait for PERIODE_HORLOGE / 2;
        clk <= '1'; wait for PERIODE_HORLOGE / 2;
    end process;

    -- Le processeur : charge chaque octet puis demande son envoi.
    emission : process
    begin
        reset <= '1'; wait for 1 us;
        reset <= '0'; wait for 1 us;
        for i in OCTETS'range loop
            wait until rising_edge(clk) and ready = '1';
            donnee <= OCTETS(i);
            ld_t <= '1'; wait until rising_edge(clk); ld_t <= '0';
            start <= '1'; wait until rising_edge(clk); start <= '0';
            wait until rising_edge(clk) and ready = '0';
        end loop;
        wait;
    end process;

    -- Le PC : décode la ligne et vérifie.
    reception : process
        variable t_depart : time;
        variable duree_bit : time;
        variable debit, ecart : real;
        variable recu : std_logic_vector(7 downto 0);
    begin
        wait until reset = '0';

        for i in OCTETS'range loop
            wait until falling_edge(tx);                 -- bit de départ
            t_depart := now;

            if i = 0 then
                -- 0x55 : le premier bit de donnée vaut 1, son front montant
                -- termine le bit de départ et donne la durée d'un bit.
                wait until rising_edge(tx);
                duree_bit := now - t_depart;
                debit := 1.0e12 / real(duree_bit / 1 ps);
                ecart := abs(debit - DEBIT_VISE) / DEBIT_VISE;
                report "Debit mesure : " & integer'image(integer(debit)) & " bauds, ecart "
                    & integer'image(integer(ecart * 1000.0)) & " pour mille";
                assert ecart < TOLERANCE
                    report "Debit hors tolerance : " & integer'image(integer(debit)) & " bauds"
                    severity error;
            end if;

            -- Échantillonnage au milieu de chaque bit, compté depuis le bit de départ.
            -- (Pour la première trame, la mesure a déjà franchi ce bit de départ.)
            if now < t_depart + duree_bit / 2 then
                wait for t_depart + duree_bit / 2 - now;
                assert tx = '0' report "Bit de depart absent" severity error;
            end if;
            for b in 0 to 7 loop                         -- poids faible en premier
                wait for t_depart + duree_bit / 2 + (b + 1) * duree_bit - now;
                recu(b) := tx;
            end loop;
            wait for t_depart + duree_bit / 2 + 9 * duree_bit - now;
            assert tx = '1' report "Bit d'arret absent" severity error;
            assert recu = OCTETS(i)
                report "Octet " & integer'image(i) & " : recu "
                    & integer'image(to_integer(unsigned(recu))) & ", attendu "
                    & integer'image(to_integer(unsigned(OCTETS(i))))
                severity error;
            report "Octet " & integer'image(i) & " recu : "
                & integer'image(to_integer(unsigned(recu)));
        end loop;

        report "UART verifiee : " & integer'image(OCTETS'length) & " octets conformes";
        fin_emission <= true;
        wait;
    end process;
end verification;
