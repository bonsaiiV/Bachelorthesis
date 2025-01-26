library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity delay is
	generic (T, word_width: integer);
	port (
		clk: in std_logic;
		in_word: in std_logic_vector(word_width-1 downto 0);

		out_word: out std_logic_vector(word_width-1 downto 0) := (others => '0')
	);
end delay;

architecture delay_b of delay is
	type BUF is array(0 to T) of std_logic_vector(word_width-1 downto 0);
	signal buffered_word: BUF := (others => (others => '0'));
begin
	buffered_word(0) <= in_word;
	out_word <= buffered_word(T);
	gen_buffer_propagation: for i in 0 to T-1 generate
		process(clk)
		begin
			if (rising_edge(clk)) then
				buffered_word(i+1) <= buffered_word(i);
			end if;
		end process;
	end generate gen_buffer_propagation;
end delay_b;
