library ieee;
use ieee.std_logic_1164.all;

entity fft_tb is
end fft_tb;

architecture test of fft_tb is
    component fft
    port (
       clk, fft_start: in std_logic;
       fft_done : out std_logic
    );
    end component;
    signal clk, fft_start : std_logic := '0';
begin
    fft_i: fft
    port map (
        clk => clk,
        fft_start => fft_start
    );
    process begin
        
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        fft_start <= '1';
        wait for 1 ns;
        fft_start <= '0';
        --for i in 0 to 25 loop
        while fft_done = '0' loop
            wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
        end loop;
        wait for 10 ns;
        wait;
    end process;
end test;
