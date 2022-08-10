library ieee;
use ieee.std_logic_1164.all;

entity fft_tb is
end fft_tb;

architecture test of fft_tb is
    component fft
    generic(N : integer;
            width, width_twiddle : integer);
    port (
       clk, fft_start: in std_logic;
       fft_done : out std_logic;
       inA, inB : std_logic_vector(2*width-1 downto 0);
       test0, test1, test2, test3, test4, test5, test6, test7 : out std_logic_vector(15 downto 0)
    );
    end component;
    signal clk, fft_start : std_logic := '0';
    signal inA, inB : std_logic_vector(15 downto 0) := (others =>'0');
    signal fft_done : std_logic;
    signal test0, test1, test2, test3, test4, test5, test6, test7 : std_logic_vector(15 downto 0);
begin
    fft_i: fft
    generic map (
        width => 8,
        width_twiddle => 6,
        N => 3
    )
    port map (
        clk => clk,
        fft_start => fft_start,
        inA => inA,
        inB => inB,
        fft_done => fft_done,
        test0 => test0,
        test1 => test1,
        test2 => test2,
        test3 => test3,
        test4 => test4,
        test5 => test5,
        test6 => test6,
        test7 => test7
    );
    process begin
        
        inA <= x"0001";
        inB <= x"0004";
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        fft_start <= '1';
        wait for 1 ns;
        fft_start <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        inA <= x"0009";
        inB <= x"0010";
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        inA <= x"00FF";
        inB <= x"00FC";
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        inA <= x"00F7";
        inB <= x"00F0";
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
