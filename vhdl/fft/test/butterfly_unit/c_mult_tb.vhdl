library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity c_mult_tb is
end c_mult_tb;

architecture test of c_mult_tb is
	component c_mult
		generic (width_A, width_B: integer);
		port (
			clk: in std_logic;
			A_real, A_imag: in  signed(width_A-1 downto 0);
			B_real, B_imag: in  signed(width_B-1 downto 0);

			result_real, result_imag: out signed(width_A-1 downto 0)
		);
	end component;

	signal A_real, A_imag: signed(7 downto 0) := (others => '0');
	signal B_real, B_imag: signed(7 downto 0) := (others => '0');
	signal result_real, result_imag: signed(7 downto 0) := (others => '0');
	signal clk : std_logic := '0';
begin

	m: c_mult
		generic map(
			width_A => 8,
			width_B => 8
		)
		port map(
			clk => clk,
			A_real => A_real,
			A_imag => A_imag,
			B_real => B_real,
			B_imag => B_imag,
			result_real => result_real,
			result_imag => result_imag
		);

	process begin
		ASSERT result_real = 0 AND result_imag = 0
		REPORT "initial values are wrong";
		A_real <= "11111010"; -- -6
		A_imag <= "11110101"; -- -11
		B_real <= "11000000"; -- -1 in fixed point
		B_imag <= "00000000";
		wait for 20 ns;
		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;
		ASSERT result_real = 0 AND result_imag = 0
		REPORT "result is 1 cycle too early";
		B_real <= "00101101"; 
		B_imag <= "00101101";
		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;
		ASSERT result_real = 6 AND result_imag = 11
		REPORT "first result is wrong";
		B_real <= "00000000"; 
		B_imag <= "00000000";
		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;
		--ASSERT result_real = 6 AND result_imag = 11
		--REPORT "first result is wrong";
		B_real <= "00000000"; 
		B_imag <= "00000000";
		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;
		wait;
	end process;

end test;
