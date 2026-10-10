------------------------------------------------------------------------
-- University  : University of Alberta
-- Course      : ECE 410 Fall 2025
-- Project     : Lab 2
-- Authors     : Antonio Andara Lara
-- Date        : 22-Sep-2025
------------------------------------------------------------------------
-- Description : Top module for taus88 implementation with SSD on the zybo board
------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY taus88_top_top IS
    PORT (
        clock          : IN STD_LOGIC;
        start          : IN STD_LOGIC;
        btn            : IN STD_LOGIC;
        display_select : OUT STD_LOGIC;
        busy           : OUT STD_LOGIC;
        segments       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        count_led      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END ENTITY taus88_top_top;

ARCHITECTURE Structural OF taus88_top_top IS
    SIGNAL clk_out  : STD_LOGIC;
    SIGNAL dout_s   : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL byte_s   : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL digits_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
    -- instantiate your top level design for lab 2 part 1 here
    PRNG         : ENTITY work.taus88_top(Behavioral) PORT MAP(clk => clk_out, rst => start, dout => dout_s);
	
    manual_input : ENTITY work.manual_clock(Behavioral) PORT MAP(clock => clock, btn => btn, clk_out => clk_out);
    counter_unit : ENTITY work.byte_counter(Behavioral) PORT MAP(start => start, clock => clock, busy => busy, count_led => count_led, count_byte => byte_s);
    mux          : ENTITY WORK.lab1_mux(Behavioral) PORT MAP(mux_i => dout_s, mux_s => byte_s, mux_o => digits_s);
    ssd_driver   : ENTITY work.display_controller(Behavioral) PORT MAP(digits => digits_s, clock => clock, display_select => display_select, segments => segments);
END ARCHITECTURE Structural;
