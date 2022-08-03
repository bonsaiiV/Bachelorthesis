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
         test0, test1, test2, test3, test4, test5, test6, test7 : out std_logic_vector(length-1 downto 0));
end ram;

architecture ram_b of ram is
    type MEMORY is array(0 to 7) of std_logic_vector(width-1 downto 0);
    signal ram_mem :MEMORY :=(
        x"0000",x"0000",x"0000",x"0000",
        x"0000",x"0000",x"0000",x"0000");
begin
    process(clk)
        variable ram_write_addr_A: natural range 0 to 2**length-1;
        variable ram_write_addr_B: natural range 0 to 2**length-1;
    begin
        if(rising_edge(clk)) then
            if(write_enable_A = '1')
            ram_write_addr_A := to_integer(unsigned(write_addr_A));
            ram_mem(ram_write_addr_A) <= write_A;
        end if;
            if(write_enable_B = '1') then
            ram_write_addr_B := to_integer(unsigned(write_addr_B));
            ram_mem(ram_write_addr_B) <= write_B;
            end if;
        end if;
    end process;
    read_A <= ram_mem(to_integer(unsigned(read_addr_A)));
    read_B <= ram_mem(to_integer(unsigned(read_addr_B)));
    test0 <= ram_mem(0);
    test1 <= ram_mem(4);
    test2 <= ram_mem(2);
    test3 <= ram_mem(6);
    test4 <= ram_mem(1);
    test5 <= ram_mem(5);
    test6 <= ram_mem(3);
    test7 <= ram_mem(7);

end ram_b;