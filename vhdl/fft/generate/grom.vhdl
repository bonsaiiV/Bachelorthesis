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
"000000010000","111111001111","111101001111","111100001111","111010001110","111001001110","111000001101","110110001100","110101001011","110100001010","110011001000","110010000111","110010000110","110001000100","110001000011","110001000001","110000000000","110001111111","110001111101","110001111100","110010111010","110010111001","110011111000","110100110110","110101110101","110110110100","111000110011","111001110010","111010110010","111100110001","111101110001","111111110001");
begin
    value <= rom_mem(to_integer(unsigned(addr)));
end rom_b;
