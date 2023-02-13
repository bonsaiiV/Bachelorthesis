library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rom is
    generic(
        width :integer:=12;
        length :integer
    ) ;
    port (
        addr: in std_logic_vector(length-1 downto 0);
        value: out std_logic_vector(width-1 downto 0)
    );
end rom;
architecture rom_b of rom is
    type MEMORY is array(0 to 2**length-1) of std_logic_vector(width-1 downto 0);
    signal rom_mem :MEMORY :=(
"000000010000","111010001110","110101001011","110010000110","110000000000","110010111010","110101110101","111010110010");
begin
   process(clk)   begin       if (rising_edge(clk)) then           value <= rom_mem(to_integer(unsigned(addr)));
       end if;   end process;end rom_b;
