library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
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
end ram;

architecture ram_b of ram is
	type MEMORY is array(0 to 2**length-1) of std_logic_vector(word_width-1 downto 0);
	signal ram_mem :MEMORY := (others => (others => '0'));
begin
	gen_unkown_hardware : if unknown_hardware generate
		process(clk)
		begin
			if(rising_edge(clk)) then
				if(write_enable_A = '1') then
					ram_mem(to_integer(unsigned(addr_A))) <= data_write_A;
				else
					data_read_A <= ram_mem(to_integer(unsigned(addr_A)));
				end if;
				if(write_enable_B = '1') then
					ram_mem(to_integer(unsigned(addr_B))) <= data_write_B;
				else
					data_read_B <= ram_mem(to_integer(unsigned(addr_B)));
				end if;
			end if;
		end process;
	else generate
		process(clk)
		begin
			if(rising_edge(clk)) then
				if(write_enable_A = '1') then
					ram_mem(to_integer(unsigned(addr_A))) <= data_write_A;
				else
					data_read_A <= ram_mem(to_integer(unsigned(addr_A)));
				end if;
			end if;
		end process;

		process(clk)
		begin
			if(rising_edge(clk)) then
				if(write_enable_B = '1') then
					ram_mem(to_integer(unsigned(addr_B))) <= data_write_B;
				else
					data_read_B <= ram_mem(to_integer(unsigned(addr_B)));
				end if;
			end if;
		end process;
	end generate gen_unkown_hardware;


end ram_b;
