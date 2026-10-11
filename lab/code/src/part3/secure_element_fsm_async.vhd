library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY secure_element_fsm_async IS
    PORT (
        clk             : IN STD_LOGIC;
        rst             : IN STD_LOGIC;
        busy            : IN STD_LOGIC;
        self_test       : IN STD_LOGIC;
        startup         : IN STD_LOGIC;
        sleep           : IN STD_LOGIC;
        request         : IN STD_LOGIC;
        secure_channel  : IN STD_LOGIC;
        attack_detected : IN STD_LOGIC;
        rgb             : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END ENTITY secure_element_fsm_async;

ARCHITECTURE Behavioral OF secure_element_fsm_async IS
    TYPE STATE_t IS (STARTUP_STATE, IDLE_STATE, SECURE_STATE, SLEEP_STATE, ALARM_STATE);
    SIGNAL state : STATE_t := STARTUP_STATE;
BEGIN
    WITH state SELECT 
    rgb <=
        "001" WHEN STARTUP_STATE, -- blue
        "010" WHEN SECURE_STATE,  -- green
        "100" WHEN ALARM_STATE,   -- red
        "110" WHEN IDLE_STATE,    -- yellow
        "111" WHEN SLEEP_STATE,   -- white
        "000" WHEN OTHERS;        -- shouldn't be others  
    
    transition : PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- async reset
            state <= STARTUP_STATE;
        ELSIF (rising_edge(clk)) THEN
            IF (state = STARTUP_STATE) THEN 
                IF ((self_test = '0' AND busy = '0') OR (attack_detected = '1')) THEN
                    state <= ALARM_STATE;
                ELSIF (self_test = '1' AND busy = '0') THEN
                    state <= IDLE_STATE;
                END IF;
            ELSIF (state = IDLE_STATE) THEN
                IF (attack_detected = '1') THEN
                    state <= ALARM_STATE;
                ELSIF (secure_channel = '1') THEN
                    state <= SECURE_STATE;
                ELSIF (startup = '1')  THEN
                    state <= STARTUP_STATE;
                ELSIF (sleep = '1') THEN
                    state <= SLEEP_STATE;
                END IF;
            ELSIF (state = SLEEP_STATE) THEN
                IF (request = '1') THEN
                    state <= IDLE_STATE;
                END IF;
            ELSIF (state = SECURE_STATE) then
                IF (attack_detected = '1') THEN
                    state <= ALARM_STATE;
                ELSIF (sleep = '1') THEN
                    state <= SLEEP_STATE;
                ELSIF (secure_channel = '0') THEN
                    state <= IDLE_STATE;
                    -- go back to idle
                END IF;
            -- ALARM_STATE has no transitions (terminal state)
            END IF;
        END IF;
    END PROCESS transition;
END ARCHITECTURE Behavioral;