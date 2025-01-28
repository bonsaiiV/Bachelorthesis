library ieee;
use ieee.std_logic_1164.all;

entity counter_tb is
end counter_tb;

architecture test of counter_tb is
	component counter
		generic (
			count_width : integer;
			max : integer
		);
		port(
			clk : in std_logic;
			clr : in std_logic;
			enable : in std_logic;

			value : out std_logic_vector(count_width-1 downto 0);
			resets : out std_logic
		);
	end component;

	signal clk : std_logic := '0';
	signal clr : std_logic;
	signal value : std_logic_vector(2 downto 0);
	signal resets : std_logic;
begin
	testee: counter
		generic map (
			count_width => 3,
			max => 3
		)
		port map (
			clk => clk,
			enable => '1',
			clr => clr,
			value => value,
			resets => resets
		);
	process begin
		assert value = "001"
		report "bad init: value"
		severity error;
		assert resets = '1'
		report "bad init: resets";

		clr <= '1';
		wait for 20 ns;
		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert value = "000"
		report "value should not increase while clr is active";

		clr <= '0';
		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert value = "001"
		report "counter should have been 1";

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert value = "010"
		report "counter should have been 2";

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert value = "011"
		report "counter should have been 3";

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert value = "000"
		report "counter should have been reset to 0";
		assert resets = '1'
		report "counter should have been signaling reset";

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert value = "001"
		report "counter should start increasing again";
		assert resets = '0'
		report "counter should have stopped signaling reset";

		clr <= '1';
		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert value = "000"
		report "counter should have been cleared";
		assert resets = '0'
		report "counter should have stopped signaling reset";

		wait;
	end process;
end test;
