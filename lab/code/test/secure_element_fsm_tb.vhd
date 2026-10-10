library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY secure_element_fsm_tb IS
END ENTITY secure_element_fsm_tb;

ARCHITECTURE test OF secure_element_fsm_tb IS
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

    CONSTANT clk_period : time := 10 ns;
BEGIN
    uut: ENTITY work.secure_element_fsm PORT MAP (
        clk => clk, 
        rst => rst, 
        busy => busy, 
        self_test => self_test,
        startup => startup, 
        sleep => sleep, 
        request => request,
        secure_channel => secure_channel, 
        attack_detected => attack_detected, 
        rgb => rgb
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
        rst <= '1';
        startup <= '1';

        -- startup
        WAIT FOR clk_period;
        assert rgb = "001" report "test 1: transition rst -> startup. should be in startup (rgb = 001)" severity error;
        startup <= '0';
        
        -- go into alarm_state
        rst <= '0';
        self_test <= '0';
        busy <= '0';

        WAIT FOR clk_period;
        assert rgb = "100" report "test 2: transition startup -> alarm. should be in alarm (rgb = 100)" severity error;
        
        rst <= '1';
        
        WAIT FOR clk_period;
        assert rgb = "001" report "test 3: transition alarm -> startup. should be in startup (rgb = 001)" severity error;

        -- go into idle_state
        rst <= '0';
        self_test <= '1';
        busy <= '0';

        WAIT FOR clk_period;
        assert rgb = "110" report "test 4: transition startup -> idle. should be in idle (rgb = 110)" severity error;

        -- go into sleep_state (from idle)
        sleep <= '1';

        WAIT FOR clk_period;
        assert rgb = "111" report "test 5: transition idle -> sleep. should be in sleep (rgb = 111)" severity error;
        sleep <= '0';

        -- go into idle_state again
        request <= '1';

        WAIT FOR clk_period;
        assert rgb = "110" report "test 6: transition sleep -> idle. should be in idle (rgb = 110)" severity error;
        request <= '0';

        -- go into startup_state from idle_state
        startup <= '1';
        
        WAIT FOR clk_period;
        assert rgb = "001" report "test 7: transition idle -> startup. should be in startup (rgb = 001)" severity error;
        startup <= '0';

        -- return to idle_state
        self_test <= '1';
        
        WAIT FOR clk_period;
        assert rgb = "110" report "test 8: transition startup -> idle. should be in idle (rgb = 110)" severity error;

        -- go into alarm_state from idle_state
        attack_detected <= '1';

        WAIT FOR clk_period;
        assert rgb = "100" report "test 9: transition idle -> alarm. should be in alarm (rgb = 100)" severity error;
        attack_detected <= '0'; -- de-assert attack
        rst <= '1';
        
        WAIT FOR clk_period;
        assert rgb = "001" report "test 10: transition alarm -> startup. should be in startup (rgb = 001)" severity error;

        -- go into idle_state
        rst <= '0';
        self_test <= '1';
        busy <= '0';

        WAIT FOR clk_period;
        assert rgb = "110" report "test 11: transition startup -> idle. should be in idle (rgb = 110)" severity error;

        -- go into secure_state from idle_state
        secure_channel <= '1';

        WAIT FOR clk_period;
        assert rgb = "010" report "test 12: transition idle -> secure. should be in secure (rgb = 010)" severity error;

        -- go into sleep_state from secure_state
        sleep <= '1';

        WAIT FOR clk_period;
        assert rgb = "111" report "test 13: transition secure -> sleep. should be in sleep (rgb = 111)" severity error;
        sleep <= '0';

        -- return to idle_state then secure_state
        request <= '1';

        WAIT FOR clk_period;
        assert rgb = "110" report "test 14: transition sleep -> idle. should be in idle (rgb = 110)" severity error;
        request <= '0';
        
        secure_channel <= '1';

        WAIT FOR clk_period;
        assert rgb = "010" report "test 15: transition idle -> secure. should be in secure (rgb = 010)" severity error;

        -- go into idle_state from secure_state
        secure_channel <= '0';

        WAIT FOR clk_period;
        assert rgb = "110" report "test 16: transition secure -> idle. should be in idle (rgb = 110)" severity error;

        -- return to secure_state
        secure_channel <= '1';

        WAIT FOR clk_period;
        assert rgb = "010" report "test 17: transition idle -> secure. should be in secure (rgb = 010)" severity error;

        -- go into alarm_state from secure_state
        attack_detected <= '1';

        WAIT FOR clk_period;
        assert rgb = "100" report "test 18: transition secure -> alarm. should be in alarm (rgb = 100)" severity error;
        attack_detected <= '0';

        WAIT;
    END PROCESS test_signals;
END ARCHITECTURE test;