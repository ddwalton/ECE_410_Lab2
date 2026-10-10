library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY taus88 IS
    GENERIC (
        g_SEED   : STD_LOGIC_VECTOR(31 DOWNTO 0);
        g_MASK   : STD_LOGIC_VECTOR(31 DOWNTO 0);
        g_SHIFT1 : NATURAL; -- shift left
        g_SHIFT2 : NATURAL; -- shift right
        g_SHIFT3 : NATURAL -- shift left
    );
    PORT (
        clk  : IN STD_LOGIC;
        rst  : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY taus88;

ARCHITECTURE Behavioral OF taus88 IS
    SIGNAL reg : STD_LOGIC_VECTOR(31 DOWNTO 0) := g_SEED; 
BEGIN
    dout <= reg; -- drive dout using internal reg

    shift_xor_mask : PROCESS(CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            IF (RST = '1') THEN
                -- synchronous reset
                reg <= g_SEED;
            ELSE 
--              the code below implements
--              reg <= (((reg SLL g_SHIFT1) XOR reg) SRL g_SHIFT2) 
--                     XOR
--                     ((reg AND g_MASK) SLL g_SHIFT3);
                reg <= std_logic_vector(
                            shift_right(unsigned((std_logic_vector(shift_left(unsigned(reg), g_SHIFT1)) XOR reg)), g_SHIFT2)
                            XOR
                            shift_left(unsigned(reg AND g_MASK), g_SHIFT3)
                        );
            END IF;
        END IF;
    END PROCESS shift_xor_mask;
END ARCHITECTURE Behavioral;