library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm_wrapper is
    generic (
        g_CLK_FREQ_HZ : INTEGER := 125_000_000
    );

    port (
        clk             : IN STD_LOGIC;
        rst             : IN STD_LOGIC;
        busy            : IN STD_LOGIC;
        self_test       : IN STD_LOGIC;
        startup         : IN STD_LOGIC;
        sleep           : IN STD_LOGIC;
        request         : IN STD_LOGIC;
        secure_channel  : IN STD_LOGIC;
        attack_detected : IN STD_LOGIC;
        rgb             : OUT STD_LOGIC_VECTOR(2 downto 0) := "000";
        count_out       : OUT UNSIGNED(3 downto 0) -- 4 bits -> max = 15
    );
end entity fsm_wrapper;

architecture fsm_wrapper_behavioral of fsm_wrapper is
    signal wakeup       : STD_LOGIC := '0';
    signal clk_1hz      : STD_LOGIC := '0';
    signal clk_1hz_prev : STD_LOGIC := '0'; -- for edge detection
    signal rgb_fsm_out  : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal count        : UNSIGNED(3 downto 0)  := "1111";
begin
    count_out <= count;

    fsm_async : entity WORK.secure_element_fsm_async(Behavioral)
        port map (
            clk => clk,
            rst => rst,
            busy => busy,
            self_test => self_test,
            startup => startup,
            sleep => sleep,
            request => (request or wakeup), -- wakeup on count = 0
            secure_channel => secure_channel,
            attack_detected => attack_detected,
            rgb => rgb_fsm_out
        );

    clk_divider_inst : entity WORK.clock_divider(Behavioral)
        generic map (
            freq_in => g_CLK_FREQ_HZ,
            freq_out => 1 -- 1 Hz out
        )
        port map (
            clock => clk,
            clock_div => clk_1hz
        );

    flash_red_and_countdown : process(clk, rst)
    begin
        if rst = '1' then
            -- async reset
            rgb <= "000";
            count <= "1111";
            wakeup <= '0';
            clk_1hz_prev <= '0';
        elsif rising_edge(clk) then
            -- Default assignments
            wakeup <= '0'; 
            clk_1hz_prev <= clk_1hz;
            
            -- ALARM_STATE: flash red using the 1Hz signal level
            if (rgb_fsm_out = "100") then 
                if (clk_1hz = '1') then
                    rgb <= "100";
                else
                    rgb <= "000";
                end if;
                count <= "1111"; -- keep reset

            elsif (rgb_fsm_out = "111") then 
                -- SLEEP_STATE: count down on 1Hz rising edge
                rgb <= "111";
                
                if (clk_1hz = '1' and clk_1hz_prev = '0') then
                    if (count = "0000") then   
                        wakeup <= '1'; 
                        count <= "1111"; 
                    else
                        count <= count - 1;
                    end if;
                end if;

            else
                --  output the fsm's intended color
                rgb <= rgb_fsm_out;
                count <= "1111"; 
            end if;
        end if;
    end process flash_red_and_countdown;
end architecture fsm_wrapper_behavioral; 