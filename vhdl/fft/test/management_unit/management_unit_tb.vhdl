library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity management_unit_tb is
end management_unit_tb;

architecture test of management_unit_tb is
    component management_unit
    generic(
        N: integer;
        layer_l: integer);
    port(fft_start, clk: in std_logic;
        twiddle_addr: out std_logic_vector(N-2 downto 0);
        addr_A_read, addr_B_read, addr_A_write, addr_B_write: out std_logic_vector(N-1 downto 0);
        fft_done, write_A_enable, write_B_enable: out std_logic);
    end component;
    signal fft_start, clk: std_logic:='0';
    signal twiddle_addr: std_logic_vector(1 downto 0);
    signal addr_A_read, addr_B_read, addr_A_write, addr_B_write: std_logic_vector(2 downto 0);
    signal fft_done, write_A_enable, write_B_enable: std_logic;
begin
    mu: management_unit
        generic map (
            N => 3,
            layer_l => 2
        )
        port map (
            fft_start => fft_start,
            clk => clk,
            twiddle_addr => twiddle_addr,
            addr_A_read => addr_A_read,
            addr_B_read => addr_B_read,
            addr_A_write => addr_A_write,
            addr_B_write => addr_B_write,
            fft_done => fft_done,
            write_A_enable => write_A_enable,
            write_B_enable => write_B_enable
        );
    process 
    begin
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        fft_start <= '1';
        wait for 1 ns;
        fft_start <= '0';
        --while fft_done = '0' loop
        for i in 0 to 25 loop
            clk <= '1';
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
        end loop;
        wait;
    end process;
end test;