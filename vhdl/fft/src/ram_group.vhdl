library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_group is
    generic(width:integer:=16;
            length:integer:=3);
    port(bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B: in std_logic_vector(length-1 downto 0);
         write_A, write_B: in std_logic_vector(width-1 downto 0);
         write_enable_A, write_enable_B, clk: in std_logic;
         read_A, read_B: out std_logic_vector(width-1 downto 0):= (others => '0');
         select_bank: in std_logic);
end ram_group;

architecture ram_b of ram_group is
    component ram
        generic(width:integer;
            length:integer);
        port(addr_A, addr_B: in std_logic_vector(length-1 downto 0);
             write_A, write_B: in std_logic_vector(width-1 downto 0);
             write_enable_A, write_enable_B, clk: in std_logic;
             read_A, read_B: out std_logic_vector(width-1 downto 0));
    end component;

    signal write_enable_0A, write_enable_0B, write_enable_1A, write_enable_1B: std_logic;
    signal read_0A, read_0B, read_1A, read_1B: std_logic_vector(width-1 downto 0);
begin
    write_enable_0A <= write_enable_A when select_bank = '0' else '0';
    write_enable_0B <= write_enable_B when select_bank = '0' else '0';
    write_enable_1A <= write_enable_A when select_bank = '1' else '0';
    write_enable_1B <= write_enable_B when select_bank = '1' else '0';

    read_A <= read_0A when select_bank = '1' else read_1A;
    read_B <= read_0B when select_bank = '1' else read_1B;
    ram_bank0: ram
    generic map (
        width => width,
        length => length
    )
    port map(
        addr_A => bank0_addr_A,
        addr_B => bank0_addr_B,
        write_A => write_A, 
        write_B => write_B,
        write_enable_A => write_enable_0A, 
        write_enable_B => write_enable_0B,
        clk => clk,
        read_A => read_0A, 
        read_B => read_0B
    );
    ram_bank1: ram
    generic map (
        width => width,
        length => length
    )
    port map(
        addr_A => bank1_addr_A,
        addr_B => bank1_addr_B,
        write_A => write_A, 
        write_B => write_B,
        write_enable_A => write_enable_1A, 
        write_enable_B => write_enable_1B,
        clk => clk,
        read_A => read_1A, 
        read_B => read_1B
    );
end ram_b;