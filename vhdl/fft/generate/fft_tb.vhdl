library ieee;
use ieee.std_logic_1164.all;
entity fft_tb is
end fft_tb;
architecture test of fft_tb is
    component fft
    generic(N : integer;
            width :integer; 
            width_twiddle : integer);
    port (
       clk, fft_start: in std_logic;
       output_valid : out std_logic;
       inA, inB : in std_logic_vector(2*width-1 downto 0);
       outA, outB: out std_logic_vector(2*width-1 downto 0));
    end component;
    signal clk, fft_start : std_logic := '0';
    signal inA, inB : std_logic_vector(37 downto 0) := (others =>'0');
    signal output_valid : std_logic;
    signal outA, outB : std_logic_vector(37 downto 0);
begin
    fft_i: fft
    generic map (
        width => 19,
        width_twiddle => 6,
        N => 15
    )
    port map (
        clk => clk,
        fft_start => fft_start,
        inA => inA,
        inB => inB,
        output_valid => output_valid,
        outA => outA,
        outB => outB
    );
   process begin
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        fft_start <= '1';
inA<="00000000000000000001000010001000000000";
inB<="00000000000000000001000001110000000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000001000000101110000000";
inB<="00000000000000000001000000101110000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000001000001011100000000";
inB<="00000000000000000001000001101010000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000001000001011010000000";
inB<="00000000000000000001000000111110000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000001000010001000000000";
inB<="00000000000000000001000001100000000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000001000011000110000000";
inB<="00000000000000000000111111000010000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000001000000110000000000";
inB<="00000000000000000001000011000110000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000000111111001100000000";
inB<="00000000000000000001000011000000000000";
while output_valid = '0' loop
            wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
        end loop;
        for i in 0 to 16500 loop
        wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
        end loop;
        wait;
    end process;
end test;
