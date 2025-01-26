library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ram_group_tb is
end ram_group_tb;

architecture test of ram_group_tb is
	component ram_group
		generic (
			unknown_hardware : boolean := false;
			word_width : integer := 16;
			length : integer := 3
		);
		port (
			clk : in std_logic;
			bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B : in std_logic_vector(length-1 downto 0);
			data_write_A, data_write_B : in std_logic_vector(word_width-1 downto 0);
			write_enable_A, write_enable_B : in std_logic;
			write_to_bank_nr : in std_logic;

			data_read_A, data_read_B : out std_logic_vector(word_width-1 downto 0) := (others => '0')
		);
	end component;
	
	signal clk : std_logic := '0';
	signal bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B : std_logic_vector(3-1 downto 0) := (others => '0');
	signal data_write_A, data_write_B : std_logic_vector(4-1 downto 0) := (others => '0');
	signal write_enable_A, write_enable_B : std_logic := '0';
	signal write_to_bank_nr : std_logic := '0';

	signal data_read_A, data_read_B : std_logic_vector(4-1 downto 0);

begin
	testee : ram_group
	generic map (
		unknown_hardware => true,
		word_width => 4,
		length => 3
	)
	port map(
		clk => clk,
		bank0_addr_A => bank0_addr_A, 
		bank0_addr_B => bank0_addr_B,
		bank1_addr_A => bank1_addr_A, 
		bank1_addr_B => bank1_addr_B,
		write_enable_A => write_enable_A, 
		write_enable_B => write_enable_B,
		data_write_A => data_write_A, 
		data_write_B => data_write_B,
		write_to_bank_nr => write_to_bank_nr,
		data_read_A => data_read_A, 
		data_read_B => data_read_B 
	);
	process begin
		wait;
	end process;
end test;
