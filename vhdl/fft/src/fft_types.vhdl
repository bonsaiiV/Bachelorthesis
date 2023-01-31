library ieee;
use ieee.std_logic_1164.all;

package types is
    --type addr_MUX is array(0 to 2**(log2_paths+1)-1) of std_logic_vector((log2_paths+1)-1 downto 0);
    type addr_MUX is array(0 to 3) of std_logic_vector(1 downto 0);
    type twiddle_addr_ARRAY is array (0 to 1) of std_logic_vector(2 downto 0);
end package;