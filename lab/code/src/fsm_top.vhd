----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/07/2026 04:05:35 PM
-- Design Name: 
-- Module Name: fsm_top - Structural
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity fsm_top is
    PORT (
        -- Inputs from Zybo
        clock           : IN STD_LOGIC; -- sys clk
        start           : IN STD_LOGIC; -- reset signal
        btn             : IN STD_LOGIC; -- next clk signal
        
        -- Transition Inputs
        busy            : IN STD_LOGIC;
        self_test       : IN STD_LOGIC;
        startup         : IN STD_LOGIC;
        sleep           : IN STD_LOGIC;
        request         : IN STD_LOGIC;
        secure_channel  : IN STD_LOGIC;
        attack_detected : IN STD_LOGIC;
        
        --- LEDs
        led6_r          : OUT STD_LOGIC;
        led6_g          : OUT STD_LOGIC;
        led6_b          : OUT STD_LOGIC
    );
end fsm_top;

architecture Structural of fsm_top is
    SIGNAL clk_out  : STD_LOGIC;
    SIGNAL rgb   : STD_LOGIC_VECTOR(2 DOWNTO 0);
begin
    led6_r <= rgb(2);
    led6_g <= rgb(1);
    led6_b <= rgb(0);

    manual_clock : ENTITY WORK.manual_clock(Behavioral) PORT MAP (clock => clock, btn => btn, clk_out => clk_out);
    fsm : ENTITY WORK.secure_element_fsm(Behavioral) 
        PORT MAP (
            clk => clk_out,
            rst => start,
            busy => busy,
            self_test => self_test,
            startup => startup,
            sleep => sleep,
            request => request,
            secure_channel => secure_channel,
            attack_detected => attack_detected,
            rgb => rgb
        );
    
end Structural;
