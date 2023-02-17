library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
    generic(width:integer:=16;
            length:integer:=3);
    port(write_addr_A, write_addr_B: in std_logic_vector(length-1 downto 0);
         write_A, write_B: in std_logic_vector(width-1 downto 0);
         write_enable_A, write_enable_B, clk: in std_logic;
         read_addr_A, read_addr_B: in std_logic_vector(length-1 downto 0);
         read_A, read_B: out std_logic_vector(width-1 downto 0):= (others => '0');
         test0, test1, test2, test3, test4, test5, test6, test7 : out std_logic_vector(width-1 downto 0));
end ram;

architecture ram_b of ram is
    type MEMORY is array(0 to 7) of std_logic_vector(width-1 downto 0);
    signal ram_mem :MEMORY;
begin
    process(clk)
    begin
        if(rising_edge(clk)) then
            read_A <= ram_mem(to_integer(unsigned(read_addr_A)));
            if(write_enable_A = '1') then
                ram_mem(to_integer(unsigned(write_addr_A))) <= write_A;
            end if;
        end if;
    end process;
    process(clk)
    begin
        if(rising_edge(clk)) then
            read_B <= ram_mem(to_integer(unsigned(read_addr_B)));
            if(write_enable_B = '1') then
                ram_mem(to_integer(unsigned(write_addr_B))) <= write_B;
            end if;
        end if;
    end process;
    



end ram_b;