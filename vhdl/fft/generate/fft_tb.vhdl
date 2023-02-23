library ieee;
use ieee.std_logic_1164.all;
entity fft_tb is
end fft_tb;
architecture test of fft_tb is
    component fft
    port (
       clk, fft_start: in std_logic;
       output_valid : out std_logic;
       inA, inB : in std_logic_vector(47 downto 0);
       outA, outB: out std_logic_vector(47 downto 0));
    end component;
signal inA, inB, outA, outB : std_logic_vector(47 downto 0) := (others =>'0');
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
inA<="000000000000000000000000010000100010000000000000";
inB<="000000000000000000000000010000011100000000000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="000000000000000000000000010000001011100000000000";
inB<="000000000000000000000000010000001011100000000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="000000000000000000000000010000010111000000000000";
inB<="000000000000000000000000010000011010100000000000";
wait for 1 ns;
clk <= '1';
wait for 1 ns;
clk <= '0';
inA<="000000000000000000000000010000010110100000000000";
inB<="000000000000000000000000010000001111100000000000";
while output_valid = '0' loop
            wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
        end loop;
        for i in 0 to 4 loop
        wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
        end loop;
        wait;
    end process;
end test;
