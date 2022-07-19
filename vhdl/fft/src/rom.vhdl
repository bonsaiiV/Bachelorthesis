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
    type MEMORY is array(0 to 3) of std_logic_vector(width-1 downto 0);
    signal rom_mem :MEMORY :=(
        "000000010000","110101001011", 
        "110000000000","110101110101");
begin


    value <= rom_mem(to_integer(unsigned(addr)));

end rom_b;