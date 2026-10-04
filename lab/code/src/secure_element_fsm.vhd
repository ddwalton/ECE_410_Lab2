library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY secure_element_fsm IS
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
END ENTITY secure_element_fsm;

ARCHITECTURE Behavioral OF secure_element_fsm IS
    TYPE STATE_t IS (STARTUP, IDLE, SECURE, SLEEP, ALARM);
    SIGNAL state : STATE_t := STARTUP;
BEGIN
    WITH state SELECT 
    rgb <=
        "001" WHEN STARTUP, -- blue
        "010" WHEN SECURE,  -- green
        "100" WHEN ALARM,   -- red
        "110" WHEN IDLE,    -- yellow
        "111" WHEN SLEEP,   -- white
        "000" WHEN OTHERS;  -- shouldn't be others  
    
    transition : PROCESS(clk)
    BEGIN
        IF (rising_edge(clk)) THEN
            IF rst = '1' THEN
                state <= STARTUP;
            ELSE
                IF (state = STARTUP) THEN 
                    IF (self_test = '1' AND busy = '0') THEN
                        state <= IDLE;
                    ELSIF (self_test = '0' AND busy = '0') THEN
                        state <= ALARM;
                    -- ELSE stay STARTUP
                    END IF;
                ELSIF (state = IDLE) THEN
                    IF (attack_detected = '1') THEN
                        state <= ALARM;
                    ELSIF (secure_channel = '1') THEN
                        state <= SECURE;
                    ELSIF (startup = '1')  THEN
                        state <= STARTUP;
                    ELSIF (sleep = '1') THEN
                        state <= SLEEP;
                    -- ELSE stay IDLE
                    END IF;
                ELSIF (state = SLEEP) THEN
                    IF (request = '1') THEN
                        state <= IDLE;
                    END IF;
                -- ALARM and SECURE have no transitions
                END IF;
            END IF;
        END IF;
    END PROCESS transition;
END ARCHITECTURE Behavioral;