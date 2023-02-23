library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rom is
    generic(
        width :integer:=12;
        length :integer
    ) ;
    port (
       clk: std_logic;
       addr: in std_logic_vector(length-1 downto 0);
       value: out std_logic_vector(width-1 downto 0)
    );
end rom;
architecture rom_b of rom is
    type MEMORY is array(0 to 2**length-1) of std_logic_vector(width-1 downto 0);
    signal rom_mem :MEMORY :=(
"00000000000100000000","11100111110011101100","11010010110010110101","11000101000001100001","11000000000000000000","11000101001110011111","11010010111101001011","11100111111100010100");
begin
   process(clk)   begin       if (rising_edge(clk)) then           value <= rom_mem(to_integer(unsigned(addr)));
       end if;   end process;end rom_b;
