library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ram_1_2_tb is
end ram_1_2_tb;

architecture test of ram_1_2_tb is
    component ram_1_2
        generic(width:integer;
            length:integer);
        port(write_addr: in std_logic_vector(length-1 downto 0);
             write_val: in signed(width-1 downto 0);
             write_enable: in std_logic;
             read_addr_A, read_addr_B: in std_logic_vector(length-1 downto 0);
             read_A, read_B: out signed(width-1 downto 0));
    end component;
    
    signal write_addr: std_logic_vector(2 downto 0);
    signal write_val: signed(3 downto 0);
    signal write_enable: std_logic := '0';
    signal read_addr_A, read_addr_B: std_logic_vector(2 downto 0):= "000";
    signal read_A, read_B: signed(3 downto 0);

begin
    ram_real: ram_1_2
    generic map (
        width => 4,
        length => 3
    )
    port map(
        write_addr => write_addr,
        write_val => write_val,
        write_enable => write_enable,
        read_addr_A => read_addr_A, 
        read_addr_B => read_addr_B,
        read_A => read_A, 
        read_B => read_B 
    );
    process begin
        write_val <= "1000";
        read_addr_A <= "000";
        read_addr_B <= "001";
        write_addr <= "000";
        write_enable <= '1';
        wait for 1 ns;
        write_enable <= '0';
        wait for 10 ns;
        write_addr <= "010";
        write_val <= "0011";
        read_addr_B <= "010"
        write_enable <= '1';
        wait for 1 ns;
        write_enable <= '0';
        wait for 10 ns;
        write_addr <= "100";
        write_enable <= '1';
        wait for 1 ns;
        write_enable <= '0';
        read_addr_A <= "100";
        read_addr_B <= "000";
        wait for 10 ns;
        wait;
    end process;
end test;