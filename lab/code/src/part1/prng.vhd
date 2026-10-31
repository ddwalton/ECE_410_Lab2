library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY prng IS
    PORT (
        clk  : IN STD_LOGIC;
        rst  : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY prng;

ARCHITECTURE Behavioral OF prng IS
    CONSTANT c_ID : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"1090";

    SIGNAL reg1, reg2, reg3 : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN
    taus_1: ENTITY WORK.taus88 
        GENERIC MAP (
            g_SEED   => x"A5A5" & c_ID, 
            g_MASK   => x"FFFFFFFE", 
            g_SHIFT1 => 13, 
            g_SHIFT2 => 19, 
            g_SHIFT3 => 12
        )
        PORT MAP (
            clk  => clk, 
            rst  => rst, 
            dout => reg1
        );

    taus_2: ENTITY WORK.taus88 
        GENERIC MAP (
            g_SEED   => x"5A5A" & c_ID, 
            g_MASK   => x"FFFFFFF8", 
            g_SHIFT1 => 2, 
            g_SHIFT2 => 25, 
            g_SHIFT3 => 4
        )
        PORT MAP (
            clk  => clk, 
            rst  => rst, 
            dout => reg2
        );

    taus_3: ENTITY WORK.taus88 
        GENERIC MAP (
            g_SEED   => x"C3C3" & c_ID, 
            g_MASK   => x"FFFFFFF0", 
            g_SHIFT1 => 3, 
            g_SHIFT2 => 11, 
            g_SHIFT3 => 17
        )
        PORT MAP (
            clk  => clk, 
            rst  => rst, 
            dout => reg3
        );

    dout <= reg1 XOR reg2 XOR reg3;
END ARCHITECTURE Behavioral;