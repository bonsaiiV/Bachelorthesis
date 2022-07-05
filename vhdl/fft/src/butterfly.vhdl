library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity butterfly is 
    generic(width_A, width_twiddle : integer);
    port(   inA_real, inA_imag, inB_real, inB_imag     : in  signed(width_A-1 downto 0);
            twiddle_real, twiddle_imag                 : in  signed(width_twiddle-1 downto 0);
            outA_real, outA_imag, outB_real, outB_imag : out signed(width_A-1 downto 0));
end butterfly;


architecture butterfly_b of butterfly is
    component c_mult
        generic (width_A, width_B: integer);
        port    (A_real, A_imag: in  signed(width_A-1 downto 0);
                 B_real, B_imag: in  signed(width_B-1 downto 0);
                 C_real, C_imag: out signed(width_A-1 downto 0));
    end component;

    signal A_real, A_imag, B_real, B_imag, tmp_real, tmp_imag : signed(width_A-1 downto 0);
    signal outA_real_buf, outA_imag_buf, outB_real_buf, outB_imag_buf : signed(width_A downto 0);
begin
    m : c_mult
        generic map(
            width_A => width_A,
            width_B => width_twiddle
        )
        port map(
            A_real => inB_real,
            A_imag => inB_imag,
            B_real => twiddle_real,
            B_imag => twiddle_imag,
            C_real => tmp_real,
            C_imag => tmp_imag
        );

    outA_real_buf <= inA_real + tmp_real;
    outA_imag_buf <= inA_imag + tmp_imag;
    outB_real_buf <= inA_real - tmp_real;
    outB_imag_buf <= inA_imag - tmp_imag;

    outA_real <= (outA_real_buf(width_A-1 downto width_A-1), outA_real_buf(width_A-1 downto 1));
    outA_imag <= (outA_imag_buf(width_A-1 downto width_A-1), outA_imag_buf(width_A-1 downto 1));
    outB_real <= (outB_real_buf(width_A-1 downto width_A-1), outB_real_buf(width_A-1 downto 1));
    outB_imag <= (outB_imag_buf(width_A-1 downto width_A-1), outB_imag_buf(width_A-1 downto 1));
end butterfly_b;