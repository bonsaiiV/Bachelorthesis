library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity butterfly_simple_tb is
end butterfly_simple_tb;

architecture test of butterfly_simple_tb is
    component butterfly
    generic(width_A, width_twiddle : integer);
    port(   inA, inB   : in  std_logic_vector(2*width_A-1 downto 0);
            twiddle    : in  std_logic_vector(2*width_twiddle-1 downto 0);
            outA, outB : out std_logic_vector(2*width_A-1 downto 0));
    end component;

    signal inA_real, inA_imag, outA_real, outA_imag, inB_real, inB_imag, outB_real, outb_imag: signed(7 downto 0);
    signal twiddle_real, twiddle_imag: signed(5 downto 0);
    signal inA, inB, outA, outB: std_logic_vector(15 downto 0);
    signal twiddle: std_logic_vector(11 downto 0);
begin

    m: butterfly
        generic map(
            width_A => 8,
            width_twiddle => 6
        )
        port map(
            inA => inA,
            outA => outA,
            twiddle => twiddle,
            inB => inB,
            outB => outB
        );
    inA <= std_logic_vector(inA_imag& inA_real);
    inB <= std_logic_vector(inB_imag& inB_real);
    twiddle <= std_logic_vector(twiddle_imag& twiddle_real);
    outA_real <= signed(outA(7 downto 0));
    outA_imag <= signed(outA(15 downto 8));
    outB_imag <= signed(outB(15 downto 8));
    outB_real <= signed(outB(7 downto 0));
    
    process begin
        inA_real <= "00000110"; 
        inA_imag <= "00000000"; 
        twiddle_real <= "010000"; 
        twiddle_imag <= "000000"; 
        inB_real <= "00000010";
        inB_imag <= "00000000";
        wait for 10 ns;
        inA_real <= "00000110"; 
        inA_imag <= "00000001"; 
        inB_real <= "00000100"; 
        inB_imag <= "00001000";
        wait for 10 ns;
        inA_real <= "00000110"; 
        inA_imag <= "00000000"; 
        twiddle_real <= "001011"; 
        twiddle_imag <= "001011"; 
        inB_real <= "00010010";
        inB_imag <= "00000100";
        wait for 10 ns;
        wait;
    end process;

end test;