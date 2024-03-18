library ieee;
use ieee.std_logic_1164.all;

package fft_types is
    --generics here are only supported by vhdl 08, which is not supported by my ghdl
    --type addr_MUX is array(0 to 2*paths-1) of std_logic_vector((log2_paths+1)-1 downto 0);
    type addr_MUX is array(0 to 3) of std_logic_vector(1 downto 0);
    --type twiddle_addr_ARRAY is array (0 to paths-1) of std_logic_vector(N-2 downto 0);
    type twiddle_addr_ARRAY is array (0 to 1) of std_logic_vector(3 downto 0);
end package;
