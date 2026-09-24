library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity UART is
  generic (
    g_CLKS_PER_BIT : integer := 521   -- For 5 MHz clock and 9600 baud
  );
  port (
    i_Clk       : in  std_logic;   -- 50 MHz input clock
    i_RX_Serial : in  std_logic;
    o_LED       : out std_logic_vector(7 downto 0)  -- LED output for counter
  );
end UART;

architecture rtl of UART is

  -- Internal clocks from divider
  signal clk_5MHz : std_logic;
  signal clk_2Hz  : std_logic;

  -- UART RX Signals
  type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits,
                     s_RX_Stop_Bit, s_Cleanup);
  signal r_SM_Main   : t_SM_Main := s_Idle;
  signal r_RX_Data_R : std_logic := '0';
  signal r_RX_Data   : std_logic := '0';

  signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
  signal r_Bit_Index : integer range 0 to 7 := 0;
  signal r_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_RX_DV     : std_logic := '0';

  -- Counter Signals
  signal r_N_Limit   : integer range 1 to 9 := 9; -- Default to Modulo-9
  signal r_Counter   : integer range 0 to 15 := 0; 

  -- Component declaration for Clock Divider
  component ClockDiv is
    port (
      clk_in       : in  std_logic;
      reset        : in  std_logic;
      clk_out_5MHz : out std_logic;
      clk_out_2Hz  : out std_logic
    );
  end component;

begin

  -- Instantiate the clock divider (divide 50 MHz -> 5 MHz and 2 Hz)
  u_clk_div : ClockDiv
    port map (
      clk_in       => ----
      reset        => ----
      clk_out_5MHz => ----
      clk_out_2Hz  => ----
    );

  --------------------------------------------------------------------------
  -- Double-register the incoming serial data
  --------------------------------------------------------------------------
  p_SAMPLE : process (clk_5MHz)
  begin
    if rising_edge(clk_5MHz) then
      r_RX_Data_R <= i_RX_Serial;
      r_RX_Data   <= r_RX_Data_R; 
    end if; 
  end process p_SAMPLE;

  --------------------------------------------------------------------------
  -- UART RX State Machine using 5 MHz clock
  --------------------------------------------------------------------------
  p_UART_RX : process (clk_5MHz)
  begin
    if rising_edge(clk_5MHz) then
      case r_SM_Main is
        when s_Idle =>
          r_RX_DV     <= '0';
          r_Clk_Count <= 0;
          r_Bit_Index <= 0;

          if r_RX_Data = '0' then
            r_SM_Main <= s_RX_Start_Bit;
          else
            r_SM_Main <= s_Idle;
          end if;

        when s_RX_Start_Bit =>
          if r_Clk_Count = (g_CLKS_PER_BIT-1)/2 then
            if r_RX_Data = '0' then
              r_Clk_Count <= 0;
              r_SM_Main   <= s_RX_Data_Bits;
            else
              r_SM_Main   <= s_Idle;
            end if;
          else
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= s_RX_Start_Bit;
          end if;

        when s_RX_Data_Bits =>
          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= s_RX_Data_Bits;
          else
            r_Clk_Count            <= 0;
            r_RX_Byte(r_Bit_Index) <= r_RX_Data;

            if r_Bit_Index < 7 then
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= s_RX_Data_Bits;
            else
              r_Bit_Index <= 0;
              r_SM_Main   <= s_RX_Stop_Bit;
            end if;
          end if;

        when s_RX_Stop_Bit =>
          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= s_RX_Stop_Bit;
          else
            r_RX_DV     <= '1';
            r_Clk_Count <= 0;
            r_SM_Main   <= s_Cleanup;
          end if;

        when s_Cleanup =>
          r_SM_Main <= s_Idle;
          r_RX_DV   <= '0';

        when others =>
          r_SM_Main <= s_Idle;

      end case;
    end if;
  end process p_UART_RX;

  --------------------------------------------------------------------------
  -- Set Modulo Limit 'N' based on UART Byte Received
  --------------------------------------------------------------------------
  p_SET_LIMIT : process (clk_5MHz)
  begin
    if rising_edge(clk_5MHz) then
      if r_RX_DV = '1' then
        case r_RX_Byte is
        
          when x"32" =>
            -- Write Logic to set N Limit for Modulo-2
            
          when x"35" =>
             -- Write Logic to set N Limit for Modulo-5
             
          -- ... Add cases for remaining ASCII characters '1' through '9' ...

          when others =>
             -- Ignore other characters, maintain current N limit
        end case;
      end if;
    end if;
  end process p_SET_LIMIT;

  --------------------------------------------------------------------------
  -- Modulo-N Counter Process updating at 2 Hz
  --------------------------------------------------------------------------
  p_COUNTER : process (clk_2Hz)
  begin
    if rising_edge(clk_2Hz) then
        -- Write logic to increment the counter up to (r_N_Limit - 1). 
        -- When it reaches the limit, wrap around to 0.
        -- Ensure that if r_N_Limit is dynamically reduced below the 
        -- current count, the counter resets gracefully.
    end if;
  end process p_COUNTER;

  -- Output logic (convert integer counter to 8-bit std_logic_vector for LEDs)
  o_LED <= std_logic_vector(to_unsigned(r_Counter, 8));

end rtl;