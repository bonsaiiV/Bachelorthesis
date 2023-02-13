library ieee;
use ieee.std_logic_1164.all;
entity fft_tb is
end fft_tb;
architecture test of fft_tb is
    component fft
    port (
       clk, fft_start: in std_logic;
       output_valid : out std_logic;
       inA, inB : in std_logic_vector(37 downto 0);
       outA, outB: out std_logic_vector(37 downto 0));
    end component;
signal inA, inB, outA, outB : std_logic_vector(37 downto 0) := (others =>'0');
    signal clk, fft_start : std_logic := '0';
    signal output_valid : std_logic;
begin
    fft_i: fft
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
inA<="00000000000000000000000100010000000000";
inB<="00000000000000000000000011100000000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000000000001011100000000";
inB<="00000000000000000000000001011100000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000000000010111000000000";
inB<="00000000000000000000000011010100000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000000000010110100000000";
inB<="00000000000000000000000001111100000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000000000100010000000000";
inB<="00000000000000000000000011000000000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000000000110001100000000";
inB<="00000000000000000001111110000100000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000000000001100000000000";
inB<="00000000000000000000000110001100000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="00000000000000000001111110011000000000";
inB<="00000000000000000000000110000000000000";
while output_valid = '0' loop
            wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
        end loop;
        for i in 0 to 8 loop
        wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
        end loop;
        wait;
    end process;
end test;
