library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity black_box is
    generic (
        g_COUNT_MAX : natural := 125_000_000 / 10 -- default for hardware synthesis
    );
    port (
        clock : in STD_LOGIC;
        data_in : in STD_LOGIC;
        clk_en : in STD_LOGIC;
        data : out STD_LOGIC;
        leds : out STD_LOGIC_VECTOR (0 to 2);
        seq_detected : out STD_LOGIC
    );
end black_box;

architecture rtl of black_box is
    -- max value to count to for debouncing logic
    signal curr_state : std_logic_vector(2 downto 0) := "000";
    signal next_state : std_logic_vector(2 downto 0) := "001";
    signal slow_clk_en : std_logic := '0'; -- for debouncing clk_en
    signal last_slow_clk_en : std_logic := '0';
    
    -- double-flop sync
    signal sync_0 : std_logic := '0'; -- synchronizer stage 0
    signal sync_1 : std_logic := '0'; -- synchronizer stage 1
begin
    data <= data_in;
    leds <= next_state;
    next_state <= "001" when curr_state = "000" and data_in = '0' else
                  "000" when curr_state = "000" and data_in = '1' else
                  "010" when curr_state = "001" and data_in = '0' else
                  "011" when curr_state = "001" and data_in = '1' else
                  "100" when curr_state = "010" and data_in = '0' else
                  "011" when curr_state = "010" and data_in = '1' else
                  "101" when curr_state = "011" and data_in = '0' else
                  "000" when curr_state = "011" and data_in = '1' else
                  "110" when curr_state = "100" and data_in = '0' else
                  "011" when curr_state = "100" and data_in = '1' else
                  "111" when curr_state = "101" and data_in = '0' else
                  "011" when curr_state = "101" and data_in = '1' else
                  "110" when curr_state = "110" and data_in = '0' else
                  "000" when curr_state = "110" and data_in = '1' else
                  "100" when curr_state = "111" and data_in = '0' else
                  "000" when curr_state = "111" and data_in = '1'; 
                  
    seq_detected <= '1' when next_state = "000" and curr_state /= "000" and curr_state /= "011" else '0';
    
    transition : process(clock)
        variable count : natural := 0;
    begin
        if rising_edge(clock) then
            -- synchronize input to clock domain
            sync_0 <= clk_en;
            sync_1 <= sync_0;
            
            -- counter-based debounce filter
            if (sync_1 /= slow_clk_en) then
                if (count < g_COUNT_MAX) then
                    count := count + 1;
                else
                    slow_clk_en <= sync_1;
                    count := 0; -- reset count
                end if;
            else
                count := 0; -- reset count
            end if;
            
            -- detect rising edge of debounced signal
            last_slow_clk_en <= slow_clk_en;
            
            if (last_slow_clk_en = '0' and slow_clk_en = '1') then
                -- on first seen rising edge of clk_en, transition
                curr_state <= next_state;
            end if;
        end if;
    end process transition;
end rtl;