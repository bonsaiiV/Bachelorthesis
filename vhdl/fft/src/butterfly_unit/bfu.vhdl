library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity butterfly is 
	generic(width_A, width_twiddle : integer);
	port (
		clk : in std_logic;
		inA, inB   : in  std_logic_vector(2*width_A-1 downto 0);
		twiddle	: in  std_logic_vector(2*width_twiddle-1 downto 0);

		outA, outB : out std_logic_vector(2*width_A-1 downto 0) := (others => '0')
	);
end butterfly;


architecture butterfly_b of butterfly is
	component c_mult
		generic (width_A, width_B: integer);
		port (
			clk: in std_logic;
			A_real, A_imag: in  signed(width_A-1 downto 0);
			B_real, B_imag: in  signed(width_B-1 downto 0);

			result_real, result_imag: out signed(width_A-1 downto 0)
		);
	end component;
	component delay
		generic (T, word_width: integer);
		port (
			clk: in std_logic;
			in_word: in std_logic_vector(word_width-1 downto 0);

			out_word: out std_logic_vector(word_width-1 downto 0)
		);
	end component;

	signal inA_real, inA_imag, inB_real, inB_imag, tmp_real, tmp_imag : signed(width_A downto 0):= (others => '0');
	signal outA_real_buf, outA_imag_buf, outB_real_buf, outB_imag_buf : signed(width_A downto 0):= (others => '0');
	signal twiddle_real, twiddle_imag : signed(width_twiddle-1 downto 0) := (others => '0');
	signal bufferedA : std_logic_vector(2*width_A-1 downto 0);
begin
	d: delay
	generic map (
		T => 2,
		word_width => 2*width_A
	)
	port map (
		clk => clk,
		in_word => inA,
		out_word => bufferedA
	);
	m : c_mult
		generic map(
			width_A => width_A + 1,
			width_B => width_twiddle
		)
		port map(
			clk => clk,
			A_real => inB_real,
			A_imag => inB_imag,
			B_real => twiddle_real,
			B_imag => twiddle_imag,
			result_real => tmp_real,
			result_imag => tmp_imag
		);
	-- cast the input signals
	inA_real <= bufferedA(width_A-1) & signed(bufferedA(width_A-1 downto 0));
	inA_imag <= bufferedA(2*width_A-1) & signed(bufferedA(2*width_A-1 downto width_A));
	inB_real <= inB(width_A-1) & signed(inB(width_A-1 downto 0));
	inB_imag <= inB(2*width_A-1) & signed(inB(2*width_A-1 downto width_A));
	twiddle_real <= signed(twiddle(width_twiddle-1 downto 0));
	twiddle_imag <= signed(twiddle(2*width_twiddle-1 downto width_twiddle));

	-- finish calculation after multiplication
	process(clk)
	begin
		if (rising_edge(clk)) then
			outA_real_buf <= inA_real + tmp_real;
			outA_imag_buf <= inA_imag + tmp_imag;
			outB_real_buf <= inA_real - tmp_real;
			outB_imag_buf <= inA_imag - tmp_imag;
		end if;
	end process;

	-- cast output signals
	outA <= std_logic_vector(outA_imag_buf(width_A downto 1)& outA_real_buf(width_A downto 1));
	outB <= std_logic_vector(outB_imag_buf(width_A downto 1)& outB_real_buf(width_A downto 1));

end butterfly_b;
