library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ram_tb is
end ram_tb;

architecture test of ram_tb is
    component ram
        generic(width:integer;
            length:integer);
        port(write_addr_A, write_addr_B: in std_logic_vector(length-1 downto 0);
             write_A, write_B: in signed(width-1 downto 0);
             write_enable_A, write_enable_B: in std_logic;
             read_addr_A, read_addr_B: in std_logic_vector(length-1 downto 0);
             read_A, read_B: out signed(width-1 downto 0));
    end component;
    
    signal write_addr_A, write_addr_B: std_logic_vector(2 downto 0);
    signal write_A, write_B: signed(3 downto 0);
    signal write_enable_A, write_enable_B: std_logic := '0';
    signal read_addr_A, read_addr_B: std_logic_vector(2 downto 0):= "000";
    signal read_A, read_B: signed(3 downto 0);

begin
    ram_real: ram
    generic map (
        width => 4,
        length => 3
    )
    port map(
        write_addr_A => write_addr_A,
        write_addr_B => write_addr_B,
        write_A => write_A, 
        write_B => write_B,
        write_enable_A => write_enable_A, 
        write_enable_B => write_enable_B,
        read_addr_A => read_addr_A, 
        read_addr_B => read_addr_B,
        read_A => read_A, 
        read_B => read_B 
    );
    process begin
        write_enable_A <= '0';
        write_enable_B <= '0';
        write_A <= "1000";
        write_B <= "0100";
        read_addr_A <= "000";
        read_addr_B <= "001";
        write_addr_A <= "000";
        write_addr_B <= "001";
        write_enable_A <= '1';
        write_enable_B <= '1';
        wait for 1 ns;
        write_enable_A <= '0';
        write_enable_A <= '0';
        wait for 10 ns;
        write_addr_A <= "010";
        write_B <= "0010";
        write_enable_A <= '1';
        write_enable_B <= '1';
        wait for 1 ns;
        write_enable_A <= '0';
        write_enable_A <= '0';
        wait for 10 ns;
        write_addr_A <= "100";
        write_addr_B <= "011";
        write_enable_A <= '1';
        write_enable_B <= '1';
        wait for 1 ns;
        write_enable_A <= '0';
        write_enable_A <= '0';
        read_addr_A <= "010";
        read_addr_B <= "100";
        wait for 10 ns;
        wait;
    end process;
end test;