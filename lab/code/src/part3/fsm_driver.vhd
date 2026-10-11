library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm_driver is
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
end entity fsm_driver;

architecture fsm_driver_behavioral of fsm_driver is
    signal wakeup : STD_LOGIC := '0';
    signal clk_1hz : STD_LOGIC := clk;
    signal rgb_fsm_out : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal count : UNSIGNED(3 downto 0)  := "1111";
begin
    count_out <= count;

    fsm_async : entity WORK.secure_element_fsm(Behavioral)
        port map (
            clk => (clk or rst), -- gate the fsm's clk to make it asynchronous
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

    clk_divider : entity WORK.clk_div(clk_divider)
        generic map (
            freq_in => g_CLK_FREQ_HZ,
            freq_out => 1 -- 1 Hz out
        )
        port map (
            clock => clk,
            clock_div => clk_1hz
        );

    flash_red_and_countdown : process(clk_1hz)
    begin
        -- flash red in ALARM_STATE (rgb_fsm_out = '100')
        if (rgb_fsm_out = "100") then
            if (rising_edge(clk_1hz)) then
                rgb <= "100"; -- output is RED for clk_1hz = 1
            elsif (falling_edge(clk_1hz)) then
                rgb <= "000"; -- output is OFF for clk_1hz = 0
            end if;
        -- countdown in SECURE_STATE (rgb_fsm_out = '010')
        elsif (rgb_fsm_out = "010") then
            if (rising_edge(clk_1hz)) then
                if (count = "0000") then   
                    -- wakeup the chip on count = 0                 
                    wakeup <= '1'; 
                    count <= "1111"; -- reset back to 15
                else
                    -- else, continue counting down
                    count <= count - 1;
                end if ;
            end if;
        else
            -- not updated at g_CLK_FREQ_HZ? (might change)
            
            -- rgb is the normal output of the fsm
            rgb <= rgb_fsm_out;
            wakeup <= '0';
            -- reset count
            count <= "1111"; 
        end if;
    end process flash_red_and_countdown;
end architecture fsm_driver_behavioral; 