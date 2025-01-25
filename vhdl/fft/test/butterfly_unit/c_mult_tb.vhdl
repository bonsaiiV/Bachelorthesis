library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity c_mult_tb is
end c_mult_tb;

architecture test of c_mult_tb is
    component c_mult
        generic (width_A, width_B: integer);
        port    (A_real, A_imag: in  signed(width_A-1 downto 0);
                 B_real, B_imag: in  signed(width_B-1 downto 0);
                 C_real, C_imag: out signed(width_A-1 downto 0));
    end component;

    signal A_real, A_imag: signed(7 downto 0);
    signal B_real, B_imag: signed(7 downto 0);
    signal C_real, C_imag: signed(7 downto 0);
begin

    m: c_mult
        generic map(
            width_A => 8,
            width_B => 8
        )
        port map(
            A_real => A_real,
            A_imag => A_imag,
            B_real => B_real,
            B_imag => B_imag,
            C_real => C_real,
            C_imag => C_imag
        );

    process begin
        A_real <= "11111010"; -- -6
        A_imag <= "11110101"; -- -11
        B_real <= "11000000"; -- -1
        B_imag <= "00000000";
        wait for 10 ns;
        B_real <= "00101101"; 
        B_imag <= "00101101";
        wait for 10 ns;
        wait;
    end process;

end test;
