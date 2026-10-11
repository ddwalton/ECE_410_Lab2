library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm_wrapper_top is
    port (
        -- Inputs from Zybo
        clock           : IN STD_LOGIC; -- sys clk
        start           : IN STD_LOGIC; -- reset signal
        
        -- Transition Inputs
        busy            : IN STD_LOGIC;
        self_test       : IN STD_LOGIC;
        startup         : IN STD_LOGIC;
        sleep           : IN STD_LOGIC;
        request         : IN STD_LOGIC;
        secure_channel  : IN STD_LOGIC;
        attack_detected : IN STD_LOGIC;
        
        --- LEDs
        rgb              : OUT STD_LOGIC_VECTOR(2 downto 0);

        -- SSD Signals
        display_select  : OUT STD_LOGIC;
        segments        : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
end fsm_wrapper_top;

architecture behavioral of fsm_wrapper_top is
    -- turns 4-bit hex into 8-bit binary-coded decimal (bcd) 
    function hex_to_bcd(hex_val : in UNSIGNED(3 downto 0)) return STD_LOGIC_VECTOR is
        variable tens : unsigned(3 downto 0);
        variable ones : unsigned(3 downto 0);
    begin
        if hex_val > 9 then
            -- number is between 10 and 15
            tens := to_unsigned(1, 4);
            ones := hex_val - 10;
        else
            -- number is between 0 and 9
            tens := to_unsigned(0, 4);
            ones := hex_val;
        end if;
        
        return std_logic_vector(tens) & std_logic_vector(ones);
    end function;

    signal count : UNSIGNED(3 downto 0);
    signal bcd_digits : STD_LOGIC_VECTOR(7 downto 0);
begin
    bcd_digits <= hex_to_bcd(count);

    fsm_wrapper_inst : entity WORK.fsm_wrapper(fsm_wrapper_behavioral)
        generic map (
            g_CLK_FREQ_HZ => 125_000_000
        )
        port map (
            clk => clock,
            rst => start,
            busy => busy,
            self_test => self_test,
            startup => startup,
            sleep => sleep,
            request => request,
            secure_channel => secure_channel,
            attack_detected => attack_detected,
            rgb => rgb,
            count_out => count
        );
    
    display_controller_inst : entity WORK.display_controller(Behavioral)
        port map (
            digits => bcd_digits,
            clock => clock,
            display_select => display_select,
            segments => segments
        );
end architecture behavioral;