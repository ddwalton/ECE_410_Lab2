library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY taus88_top_tb IS
END ENTITY taus88_top_tb;

ARCHITECTURE test OF taus88_top_tb IS
    SIGNAL clk, rst : STD_LOGIC := '0';
    SIGNAL dout : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
BEGIN
    dut : ENTITY WORK.taus88_top(Behavioral)
        PORT MAP (clk => clk, rst => rst, dout => dout);
    
    gen_clk : PROCESS
    BEGIN
        -- 50 MHz -> period = 1/50M = 20 ns
        -- half period = 0.5 * 20 ns = 10 ns
        clk <= '0';
        WAIT FOR 10 ns;
        clk <= '1';
        WAIT FOR 10 ns;
    END PROCESS gen_clk;

    test_signals : PROCESS
    BEGIN
        WAIT FOR 100 ns; -- rising edge occurs 5 times
        
        -- hold rst high for 100 ns (5 clk cycles)
        -- expected: same dout as the first 5 clk cycles
        rst <= '1';
        WAIT FOR 100 ns;
        
        -- continue forever
        rst <= '0';
    END PROCESS test_signals;
END ARCHITECTURE test;