library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    generic (count_width : integer; max : integer);
    port(clk : in std_logic;
         clr : in std_logic;
         value : out std_logic_vector(count_width-1 downto 0);
         resets : out std_logic);
end counter;

architecture counter_b of counter is

    signal count : unsigned(count_width-1 downto 0);
    signal reached_max : std_logic;

begin

process(clk) begin
    if rising_edge(clk) then
        if clr = '1' then
            count <= (others => '0');
        else
            if count = max then
                count <= (others => '0');
                reached_max <= '1';
            else
                count <= count + 1;
            end if;
        end if;
    end if;
end process;
process(count) begin
    if count >= max then
        reached_max <= '1';
    else
        reached_max <= '0';
    end if;
end process;
value <= std_logic_vector(count);
resets <= std_logic(reached_max);


end counter_b;