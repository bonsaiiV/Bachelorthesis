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
    signal val : std_logic_vector(2 downto 0);
begin

    count: counter
        generic map(
            count_width => 3,
            max => 6
        )
        port map(
            clk => clk,
            clr => clr,
            resets => r,
            value => val
        );
    process begin
        clr <= '1';
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clr <= '0';
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clr <= '1';
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clr <= '0';
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;

        wait;
    end process;
end test;