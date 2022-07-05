library ieee;
use ieee.std_logic_1164.all;

entity counter_tb is
end counter_tb;

architecture test of counter_tb is
    component counter
        generic (count_width : integer; max : integer);
        port(clk : in std_logic;
             clr : in std_logic;
             value : out std_logic_vector(count_width-1 downto 0);
             resets : out std_logic);
    end component;

    signal clk, clr, r : std_logic;
    signal val : std_logic_vector;
begin

    count g: counter
        generic map(
            count_width => 4;
            max => 12;
        )
        port map(
            clk => clk;
            clr => clr;
            reset => r;
            value => val;
        )
    
    process begin
end test;