library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ram_tb is
end ram_tb;

architecture test of ram_tb is
	component ram
		generic(
			unknown_hardware : boolean := false;
			word_width : integer := 16;
			length : integer := 3
		);
		port(
			clk: in std_logic;
			addr_A, addr_B: in std_logic_vector(length-1 downto 0);
			data_write_A, data_write_B: in std_logic_vector(word_width-1 downto 0);
			write_enable_A, write_enable_B: in std_logic;

			data_read_A, data_read_B: out std_logic_vector(word_width-1 downto 0):= (others => '0')
		);
	end component;
	
	signal clk: std_logic := '0';
	signal addr_A, addr_B: std_logic_vector(2 downto 0);
	signal write_enable_A, write_enable_B: std_logic := '0';
	signal data_write_A, data_write_B: std_logic_vector(3 downto 0);

	signal data_read_A, data_read_B: std_logic_vector(3 downto 0);

begin
	ram_i: ram
	generic map (
		unknown_hardware => true,
		word_width => 4,
		length => 3
	)
	port map(
		clk => clk,
		write_enable_A => write_enable_A, 
		write_enable_B => write_enable_B,
		addr_A => addr_A, 
		addr_B => addr_B,
		data_write_A => data_write_A, 
		data_write_B => data_write_B,
		data_read_A => data_read_A, 
		data_read_B => data_read_B 
	);
	process begin
		assert data_read_A = "0000" and data_read_B = "0000"
		report "0. cycle: bad init";

		data_write_A <= "1000";
		data_write_B <= "0100";
		addr_A <= "000";
		addr_B <= "001";
		write_enable_A <= '1';
		write_enable_B <= '1';

		wait for 20 ns;
		assert data_read_A = "0000" and data_read_B = "0000"
		report "0. cycle: read should only return values when read is enabled";

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert data_read_A = "0000" and data_read_B = "0000"
		report "1. cycle: read should only return values when read is enabled";

		write_enable_A <= '0';
		write_enable_B <= '0';

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert data_read_A = "1000" and data_read_B = "0100"
		report "2. cycle: read after clock cycle is wrong";

		addr_A <= "001";
		addr_B <= "000";

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert data_read_A = "0100" and data_read_B = "1000"
		report "3. cycle: read after switching addresses is wrong";

		addr_A <= "010";
		addr_B <= "011";

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert data_read_A = "0000" and data_read_B = "0000"
		report "4. cycle: bad read from unwritten address";

		data_write_A <= "0010";
		data_write_B <= "0001";
		write_enable_A <= '1';
		write_enable_B <= '1';

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert data_read_A = "0000" and data_read_B = "0000"
		report "5. cycle: read value should only update when read enabled";

		write_enable_A <= '0';
		write_enable_B <= '0';

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert data_read_A = "0010" and data_read_B = "0001"
		report "6. cycle: bad read from 2. address";

		addr_A <= "000";
		addr_B <= "001";

		clk <= '1';
		wait for 10 ns;
		clk <= '0';
		wait for 10 ns;

		assert data_read_A = "1000" and data_read_B = "0100"
		report "7. cycle: bad read from original address";

		wait;
	end process;
end test;
