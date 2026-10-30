library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY black_box_tb IS
END ENTITY black_box_tb;

ARCHITECTURE test OF black_box_tb IS
    SIGNAL clock        : STD_LOGIC := '0';
    SIGNAL data_in      : STD_LOGIC := '0';
    SIGNAL clk_en       : STD_LOGIC := '0';
    SIGNAL data         : STD_LOGIC;
    SIGNAL leds         : STD_LOGIC_VECTOR(0 TO 2);
    SIGNAL seq_detected : STD_LOGIC;

    CONSTANT clk_period    : time := 10 ns;
    CONSTANT c_SIM_COUNT   : natural := 10; -- small count for fast simulation
    CONSTANT debounce_wait : time := (c_SIM_COUNT + 5) * clk_period;
BEGIN
    uut: ENTITY work.black_box 
        GENERIC MAP (
            g_COUNT_MAX => c_SIM_COUNT
        )
        PORT MAP (
            clock        => clock,
            data_in      => data_in,
            clk_en       => clk_en,
            data         => data,
            leds         => leds,
            seq_detected => seq_detected
        );

    gen_clk : PROCESS
    BEGIN
        clock <= '1';
        WAIT FOR clk_period / 2;

        clock <= '0';
        WAIT FOR clk_period / 2;
    END PROCESS gen_clk;

    test_signals : PROCESS
    BEGIN
        -- test initial combinational pass-through and next state
        data_in <= '0';
        WAIT FOR clk_period;
        assert data = '0' report "test 1: initial data output should be 0" severity error;
        assert leds = "001" report "test 1: initial next_state should be 001" severity error;

        -- test debouncer glitch filtering (< 10 cycles)
        clk_en <= '1';
        WAIT FOR 5 * clk_period;
        clk_en <= '0';
        WAIT FOR 5 * clk_period;
        assert leds = "001" report "test 2: short clk_en glitch should be ignored" severity error;

        -- test transition state 000 -> 001
        data_in <= '0';
        clk_en <= '1';
        WAIT FOR debounce_wait;
        clk_en <= '0';
        WAIT FOR debounce_wait;
        assert leds = "010" report "test 3: transition 000 -> 001. next_state should be 010" severity error;

        -- test transition state 001 -> 010
        data_in <= '0';
        clk_en <= '1';
        WAIT FOR debounce_wait;
        clk_en <= '0';
        WAIT FOR debounce_wait;
        assert leds = "100" report "test 4: transition 001 -> 010. next_state should be 100" severity error;

        -- test transition state 010 -> 100
        data_in <= '0';
        clk_en <= '1';
        WAIT FOR debounce_wait;
        clk_en <= '0';
        WAIT FOR debounce_wait;
        assert leds = "110" report "test 5: transition 010 -> 100. next_state should be 110" severity error;

        -- test transition state 100 -> 110
        data_in <= '0';
        clk_en <= '1';
        WAIT FOR debounce_wait;
        clk_en <= '0';
        WAIT FOR debounce_wait;
        assert leds = "110" report "test 6: transition 100 -> 110. next_state should be 110" severity error;

        -- test sequence detection on state 110 with data_in = 1
        data_in <= '1';
        WAIT FOR clk_period;
        assert data = '1' report "test 7: data pass-through check when high should be 1" severity error;
        assert leds = "000" report "test 7: next_state for state 110 with data_in = 1 should be 000" severity error;
        assert seq_detected = '1' report "test 7: sequence detection output check should be 1" severity error;

        -- test transition back to state 000
        clk_en <= '1';
        WAIT FOR debounce_wait;
        clk_en <= '0';
        WAIT FOR debounce_wait;
        assert seq_detected = '0' report "test 8: sequence detected de-assert after state reset should be 0" severity error;

        -- test state 000 with data_in = 1 stays at 000
        data_in <= '1';
        clk_en <= '1';
        WAIT FOR debounce_wait;
        clk_en <= '0';
        WAIT FOR debounce_wait;
        assert leds = "000" report "test 9: state 000 with data_in = 1 should stay in state 000" severity error;

        WAIT;
    END PROCESS test_signals;
END ARCHITECTURE test;