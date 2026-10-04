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
        
        -- go into ALARM_STATE
        rst <= '0';
        self_test <= '0';
        busy <= '0';

        WAIT FOR clk_period;
        
        rst <= '1';
        
        WAIT FOR clk_period;

        -- go into IDLE_STATE
        rst <= '0';
        self_test <= '1';
        busy <= '0';

        WAIT FOR clk_period;

        -- go into SLEEP_STATE
        sleep <= '1';

        WAIT FOR clk_period;

        -- go into IDLE_STATE again
        sleep <= '0';
        request <= '1';

        WAIT FOR clk_period;

        -- go into ALARM_STATE from IDLE_STATE
        attack_detected <= '1';

        WAIT FOR clk_period;

        attack_detected <= '0';
        rst <= '1';
        
        WAIT FOR clk_period;

        -- go into IDLE_STATE
        rst <= '0';
        self_test <= '1';
        busy <= '0';

        WAIT FOR clk_period;

        -- go into SECURE_STATE
        secure_channel <= '1';

        WAIT;
    END PROCESS test_signals;
END ARCHITECTURE test;