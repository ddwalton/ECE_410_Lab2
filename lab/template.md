# ECE 410 Lab 2: Finite State Machines

Names: Dion Walton, Anahita Houshyar

CCIDs: ddwalton, ahoushya

Lab Section: D31

## Questions
1. What was the biggest obstacle you had to overcome while working on this lab, and how did you resolve it?
2. Compare the testing process using the logic analyzer with the behavioral simulation. How did the real-time
testing with the AD2 differ from the purely simulated environment, and what are the key benefits of using
the AD2/AD3 for testing your design? Were there any specific challenges or insights you gained from this
hands-on testing that were not apparent during simulation?
3. Propose potential enhancements to the pseudo random number generator design from Part 1, and briefly
justify each enhancement in 1 or 2 sentences.
4. Suggest other possible upgrades that could be added to the secure element to improve its functionality or
safety. Provide a brief explanation for each suggestion.
5. What trade-offs did you consider when deciding whether to use a Mealy or Moore FSM for the secure
element? How did this decision impact your design?


## Abstract
> Provide a summary of the lab objectives, design approach, and key results. The abstract should be no more than 150 words.

In this lab, we design, tested, and implement a pseudo-random number generator using a the Tausworthe generator architecture. Then, we design, tested, and implemented a 7-input, 3-output (RGB LED), 5-state Moore finite state machine (FSM) for a secure element chip. After creating the 5-state secure element FSM, it was enhanced by making the Zybo-Z7 development board flash a red on the RGB LED at 5 Hz in `ALARM_STATE`, and adding a 15-second wake-up timer to the sleep state, in which it would automatically go into the `IDLE_STATE` from `SLEEP_STATE`. Finally, a Mealy FSM was reverse engineered from a bitstream and reimplemented in VHDL.

> TODO: Results?

## Design
> Provide detailed explanation of your design process, including the following components:

#### Tausworthe Generator Design

The Tauseworthe generator consisted of 3 `taus88` submodules. Each submodule acts as a linear feedback shift register (LFSR), which is essentially a D Flip-Flop that does some combinational operation to determine the next register value. Using generics, each submodule is instantiated with a "seed" - the initial value held in the LFSR (`g_SEED`), 3 shift values (`g_SHIFT1`, `g_SHIFT2`, and `g_SHIFT3`), and a "mask" (`g_MASK`). The submodule then does the following computation (although, the code uses type casting and `shift_left()` / `shift_right()` functions instead of using the overloaded `SLL` and `SRL` operators for compliance with modern VHDL).

```vhdl
reg <= (((reg SLL g_SHIFT1) XOR reg) SRL g_SHIFT2) 
        XOR
        ((reg AND g_MASK) SLL g_SHIFT3);
```

Using 3 of these submodules initialized with different seeds, shift values, and masks and XORing their registers, we get a pseudo-random number generator (PRNG) that is updated on each CLK cycle. 

#### Secure Element FSM: Initial Design

The initial design of the secure element FSM is implemented as a Moore FSM, where the current output only depends on the current state. The state-transition diagram can be seen below in the "Truth Table & Functional Block Diagrams" section. This was done by creating a `secure_element_fsm.vhd` entity, with input ports being each of the 7 inputs, (`attack_detected`, `busy`, `self_test`, etc.) and output ports being the the RGB values that indicate the current state. The RGB values are directly mapped to an enumerated type that describe the state, where the transitions between states are defined in nested if-else blocks within a process. Simply put, a control signal `state` drives the output RGB based on the `transition` process on the rising edge of the clock. Additionally, this version of the FSM utilizes a synchronous reset, which only resets the state back to `STARTUP_STATE` on the rising edge of the clock while `rst` is held high.

The top-level module for the first iteration of the secure chip FSM (`fsm_top.vhd`) utilizes the `manual_clock` to drive the state transitions, so that testing on-board allowed more precise control.

#### Secure Element FSM: Upgraded Design

The upgraded design of the secure element FSM required 3 new features: an asynchronous reset, a blinking red LED on `ALARM_STATE`, and a 15-second timer that automatically transitioned the state from `SLEEP_STATE` to `IDLE_STATE` once it reached 0. To create the asynchronous reset, a second iteration of the FSM was created as `secure_element_fsm_async.vhd`. This has the same code, except the process now has `rst` in its sensitivity list (as opposed to just `clk`), while taking the `if (rst = '1')` out of the if statement for the `if rising_edge(clk) = '1'` and making the rising edge if an elsif. The change can be seen below:

```vhdl
transition : PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- async reset
            state <= STARTUP_STATE;
        ELSIF (rising_edge(clk)) THEN
            -- do stuff
```

After adding the asynchronous reset, the remaining features were implemented by creating a higher-level entity (`fsm_wrapper.vhd`) that uses the FSM as a component. This higher-level entity takes in the control signals as input and plugs them into the ports of the FSM, while additionally having a secondary `wakeup` control signal that, if '1', acts like `request`, sending the state from `SLEEP_STATE` to `IDLE_STATE`. Additionally, the out ports of the are overridden with internal signals from the top-level entity to properly control the LED. 

The 1 Hz blinking LED was implemented by taking the output of the FSM (which is known due to the `rgb_fsm_out` being a one-to-one mapping to states) and toggling the actual LED between "000" (off) and "100" (red) based on a 1 Hz clock signal only if `rgb_fsm_out = "100"` (`ALARM_STATE`). The 1 Hz clock was obtained from a `clock_divider` component which uses the system clock of 125 MHz as input. The clock divider operates by counting up on each rising edge of the system clock until it reaches `125_000_000 / 2` clock cycles, where it subsequently toggles the output clock high or low. This results in an overall 1 Hz output clock. The counter was implemented by using the `IEEE.NUMERIC_STD` library, which allowed an 4-bit unsigned `count` timer to be subtracted by 1 each rising edge of the 1 Hz clock (or where the closest rising edge in line with the system clock is). Once the `count` signal reaches 0, the `wakeup` signal is asserted, overriding normal operation and putting the FSM into `IDLE_STATE`.

### Calculations/Assumptions
> Clearly state any calculations performed and assumptions made during the design process.

#### Secure Element FSM Assumptions

For the secure element FSM, it was assumed that any state (aside from `SLEEP_STATE`) immediately goes into `ALARM_STATE` once `attack_detected` is asserted. Additionally, it was assumed that `ALARM_STATE > SECURE_STATE > STARTUP_STATE > SLEEP_STATE` in terms of precedence (i.e., if each signal were asserted at the same time, the FSM would go into `ALARM_STATE`). Finally, it was assumed that the `SLEEP_STATE` can only be left by asserting `request`, where it transitions into `IDLE_STATE`. 

#### Black Box Assumptions

For the "black box," it was assumed that the original code operated as a Mealy machine (inputs and state in conjunction controlling the current state). Although mathematically analogous, the Mealy implementation was far simpler to implement than a Moore machine due to the number of states it would require.

### Flowchart of the Design
> Include a flowchart that illustrates the overall design process or logic flow of your system.

### Truth Table & Functional Block Diagrams
> Provide a truth table for small designs or for internal blocks if the design is complex. This should outline the expected outputs for all possible inputs. Additionally, include a functional block diagram that illustrates the overall structure and major components of your design, showing how different blocks interact with each other.

#### Tausworthe Generator Block Diagram

![alt text](images/tgen_block_diagram.png)

#### Secure Element Chip FSM

![alt text](images/secure_elem_fsm_block_diagram.png)

#### Block Box FSM

![alt text](images/black_box_fsm.png)

#### Black Box Truth Table

| Current State (`curr_state`) | Input (`data_in`) / `SW0` = `LD0`| Next State (`next_state`) / `LD[1:3]` | Output (`seq_detected`) |
| --- | --- | --- | --- |
| 000 | 0 | 001 | 0 |
| 000 | 1 | 000 | 0 |
| 001 | 0 | 010 | 0 |
| 001 | 1 | 011 | 0 |
| 010 | 0 | 100 | 0 |
| 010 | 1 | 011 | 0 |
| 011 | 0 | 101 | 0 |
| 011 | 1 | 000 | 0 |
| 100 | 0 | 110 | 0 |
| 100 | 1 | 011 | 0 |
| 101 | 0 | 111 | 0 |
| 101 | 1 | 011 | 0 |
| 110 | 0 | 110 | 0 |
| 110 | 1 | 000 | 1 |
| 111 | 0 | 100 | 0 |
| 111 | 1 | 000 | 1 |

### Synthesized Schematic
> Include the schematic generated after synthesis, showing the actual hardware implementation of your design. If the schematic is too large, you may break it up into smaller, more manageable pieces for clarity.

#### Top-level FSM RTL Synthesis

![alt text](<images/fsm_top_schematic.png>)

#### `fsm_wrapper_inst` RTL Synthesis

![alt text](images/fsm_wrapper_inst.png)

#### `fsm_wrapper_inst` Elaborated Design

![alt text](images/fsm_wrapper_elaborated.png)

### Implementation
> Describe the implementation details, including pin assignments and any observations made on the board during testing

## Simulation
> Document the simulation and results, including:

### Test Cases Table & Explanation
> Provide a brief explanation of the test cases used to verify the design, including the rationale behind each test and an explanation of edge cases used to verify the design.


### Simulation Results
> Include figures and waveforms from the simulation, accompanied by a brief explanation of the observed results and their significance.

## Results 
> Present the results of your implementation, comparing them with expected outcomes. Discuss any discrepancies and analyze the performance of the design.

## Conclusion
> Summarize the outcomes of the lab, including any challenges encountered and how they were addressed. Discuss the effectiveness of the design and any potential improvements.

## References
> Cite any references used during the lab, including textbooks, websites, articles or AI Assistants.

## Team Contribution
> Clearly indicate the specific contributions made by each team member in the lab, including design, simulation, implementation, and report writing.

