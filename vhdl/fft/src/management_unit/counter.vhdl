library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    generic (count_width : integer; max : integer);
    port(enable, clk : in std_logic;
         clr : in std_logic;
         value : out std_logic_vector(count_width-1 downto 0):= (others => '0');
         resets : out std_logic:='0');
end counter;

architecture counter_b of counter is

    signal count : unsigned(count_width-1 downto 0) := (others => '0');

begin

process(clk) begin
    
    if rising_edge(clk) then
        if clr = '1' then
            count <= (others => '0');
            resets <= '0';
        elsif(enable = '1') then
            if count = max then
                count <= (others => '0');
                resets <= '1';
            else
                count <= count + 1;
                resets <= '0';
            end if;
        end if;
    end if;
end process;
value <= std_logic_vector(count);

end counter_b;
