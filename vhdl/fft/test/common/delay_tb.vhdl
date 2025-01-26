library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity delay_tb is
end delay_tb;

architecture test of delay_tb is
	component delay
	generic(T, word_width : integer);
	port (
		clk: in std_logic;
		in_word: in std_logic_vector(word_width-1 downto 0);

		out_word: out std_logic_vector(word_width-1 downto 0) := (others => '0')
	);
	end component;

	signal clk: std_logic := '0';
	signal in_word: std_logic_vector(7 downto 0) := (others => '0');

	signal out_word: std_logic_vector(7 downto 0);
begin
	t: delay
	generic map(
		T => 2,
		word_width => 8
	)
	port map (
		clk => clk,
		in_word => in_word,
		out_word => out_word
	);
	process begin
		assert out_word = "00000000"
		report "error on init";
		in_word <= "00000101";
		wait for 20 ns;
		assert out_word = "00000000"
		report "result is 2 cycles too early";
		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;
		assert out_word = "00000000"
		report "result is 1 cycle too early";
		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;
		assert out_word = "00000101"
		report "result is wrong";
		wait;
	end process;
end test;
