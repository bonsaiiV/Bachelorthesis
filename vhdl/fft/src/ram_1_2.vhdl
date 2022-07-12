library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_1_2 is
    generic(width:integer;
            length:integer);
    port(write_addr: in std_logic_vector(length-1 downto 0);
         write_val: in signed(width-1 downto 0);
         write_enable: in std_logic;
         read_addr_A, read_addr_B: in std_logic_vector(length-1 downto 0);
         read_A, read_B: out signed(width-1 downto 0));
end ram_1_2;

architecture ram_1_2_b of ram_1_2 is
    type MEMORY is array(0 to 7) of signed(width-1 downto 0);
    signal ram_mem :MEMORY :=(
        x"0",x"0",x"0",x"0", 
        x"0",x"0",x"0",x"0");
begin
    process(write_enable)
    begin
        if(rising_edge(write_enable)) then
            ram_mem(to_integer(unsigned(write_addr))) <= write_val;
        end if;
    end process;
    read_A <= ram_mem(to_integer(unsigned(read_addr_A)));
    read_B <= ram_mem(to_integer(unsigned(read_addr_B)));

end ram_1_2_b;