library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity c_mult is
	generic (width_A, width_B: integer);
	port (
		clk: in std_logic;
		A_real, A_imag: in  signed(width_A-1 downto 0);
		B_real, B_imag: in  signed(width_B-1 downto 0);

		result_real, result_imag: out signed(width_A-1 downto 0) := (others => '0')
	);
end c_mult;

architecture c_mult_b of c_mult is
	signal tmp_real0 : signed(width_A+width_B-1 downto 0) := (others => '0');
	signal tmp_real1 : signed(width_A+width_B-1 downto 0) := (others => '0');
	signal tmp_imag0 : signed(width_A+width_B-1 downto 0) := (others => '0');
	signal tmp_imag1 : signed(width_A+width_B-1 downto 0) := (others => '0');

begin
	process(clk)
	begin
		if(rising_edge(clk)) then
			tmp_real0 <= A_real * B_real;
			tmp_real1 <= A_imag * B_imag;
			tmp_imag0 <= A_real * B_imag;
			tmp_imag1 <= A_imag * B_real;
		end if;
	end process;

	process(clk)
	begin
		if(rising_edge(clk)) then
			result_real <= tmp_real0(width_A + width_B-3 downto width_B-2) - tmp_real1(width_A + width_B-3 downto width_B-2);
			result_imag <= tmp_imag0(width_A + width_B-3 downto width_B-2) + tmp_imag1(width_A + width_B-3 downto width_B-2);
		end if;
	end process;

end c_mult_b;
