library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY fsm_wrapper_tb IS
END ENTITY fsm_wrapper_tb;

ARCHITECTURE test OF fsm_wrapper_tb IS
    SIGNAL clk             : STD_LOGIC := '0';
    SIGNAL rst             : STD_LOGIC := '1';
    SIGNAL busy            : STD_LOGIC := '0';
    SIGNAL self_test       : STD_LOGIC := '0';
    SIGNAL startup         : STD_LOGIC := '0';
    SIGNAL sleep           : STD_LOGIC := '0';
    SIGNAL request         : STD_LOGIC := '0';
    SIGNAL secure_channel  : STD_LOGIC := '0';
    SIGNAL attack_detected : STD_LOGIC := '0';
    SIGNAL rgb             : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL count_out       : UNSIGNED(3 DOWNTO 0);

    CONSTANT clk_period    : time := 0.25 sec;
    -- set a small clock frequency generic for simulation to avoid waiting millions of cycles
    CONSTANT sim_clk_freq  : integer := 4; 
BEGIN
    uut: ENTITY work.fsm_wrapper
        GENERIC MAP (
            g_CLK_FREQ_HZ => sim_clk_freq
        )
        PORT MAP (
            clk             => clk,
            rst             => rst,
            busy            => busy,
            self_test       => self_test,
            startup         => startup,
            sleep           => sleep,
            request         => request,
            secure_channel  => secure_channel,
            attack_detected => attack_detected,
            rgb             => rgb,
            count_out       => count_out
        );

    gen_clk : PROCESS
    BEGIN
        clk <= '1';
        WAIT FOR clk_period / 2;

        clk <= '0';
        WAIT FOR clk_period / 2;
    END PROCESS gen_clk;

    test_signals : PROCESS
    BEGIN
        -- INITIAL RESET & STARTUP
        rst <= '1';
        startup <= '1';

        WAIT FOR clk_period;
        assert rgb = "001" report "test 1: transition rst -> startup. should be in startup (rgb = 001)" severity error;
        startup <= '0';
        
        -- TEST RED STATE (ALARM STATE: Flashing Red RGB)
        -- transition startup -> alarm_state
        rst <= '0';
        self_test <= '0';
        busy <= '0';

        WAIT FOR clk_period;
        -- in alarm state, top-level rgb flashes red ("100" / "000") driven by clk_1hz, count is held at 15
        assert (rgb = "100" or rgb = "000") report "test 2: transition startup -> alarm. rgb should flash red (100 or 000)" severity error;
        assert count_out = "1111" report "test 3: alarm state count_out should be reset to 15 (1111)" severity error;

        -- wait through clock division cycles to observe flashing behavior
        WAIT FOR clk_period * sim_clk_freq * 2;
        assert (rgb = "100" or rgb = "000") report "test 4: continuous alarm state check failed" severity error;
        
        -- TRANSITION TO IDLE STATE
        rst <= '1';
        
        WAIT FOR clk_period;
        assert rgb = "001" report "test 5: reset from alarm -> startup. should be in startup (rgb = 001)" severity error;

        rst <= '0';
        self_test <= '1';

        WAIT FOR clk_period;
        assert rgb = "110" report "test 6: transition startup -> idle. should be in idle (rgb = 110)" severity error;

        -- transition idle -> sleep_state
        sleep <= '1';

        WAIT FOR clk_period;
        assert rgb = "111" report "test 7: transition idle -> sleep. rgb should be solid white (111)" severity error;
        sleep <= '0';

        -- allow clock divider to tick and verify count decrement
        WAIT FOR clk_period * sim_clk_freq * 2;
        assert rgb = "111" report "test 8: sleep state rgb should remain solid white (111) during countdown" severity error;
        assert count_out < "1111" report "test 9: sleep state countdown should decrement count_out" severity error;

        -- wait for full countdown (16 divider pulses) until wakeup triggers return to idle
        WAIT FOR clk_period * sim_clk_freq * 16;
        WAIT FOR clk_period * 2;
        assert rgb = "110" report "test 10: auto-wakeup from sleep -> idle upon counter reaching 0 failed (rgb = 110)" severity error;

        WAIT;
    END PROCESS test_signals;
END ARCHITECTURE test;