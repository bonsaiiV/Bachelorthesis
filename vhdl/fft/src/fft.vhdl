library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft is
    generic(N : integer;
            width, width_twiddle : integer);
    port (
        clk, fft_start : in std_logic;
        fft_done : out std_logic;
        inA, inB : std_logic_vector(2*width-1 downto 0);
        test0 : out std_logic_vector(15 downto 0)
    );
end fft;

architecture fft_b of fft is
    component management_unit
    generic(
        N: integer;
        layer_l: integer);
    port(fft_start, clk: in std_logic;
        twiddle_addr: out std_logic_vector(N-2 downto 0);
        addr_A_read, addr_B_read, addr_A_write, addr_B_write: out std_logic_vector(N-1 downto 0);
        fft_done, write_A_enable, write_B_enable: out std_logic;
        get_input: out std_logic);
    end component;
    signal twiddle_addr: std_logic_vector(N-2 downto 0);
    signal addr_A_read, addr_B_read, addr_A_write, addr_B_write: std_logic_vector(N-1 downto 0);
    signal write_A_enable, write_B_enable: std_logic;
    signal read_A_addr, read_B_addr, write_A_addr, write_B_addr: std_logic_vector(N-1 downto 0);

    component butterfly
    generic(width_A, width_twiddle : integer);
    port(   inA, inB     : in  std_logic_vector(width_A*2-1 downto 0);
            twiddle : in  std_logic_vector(width_twiddle*2-1 downto 0);
            outA, outB : out std_logic_vector(width_A*2-1 downto 0));
    end component;

    signal twiddle: std_logic_vector(2*width_twiddle-1 downto 0);
    signal bfu_A, bfu_B : std_logic_vector(2*width-1 downto 0);
    signal read_A, read_B, write_A, write_B: std_logic_vector(2*width-1 downto 0);
    signal get_input: std_logic;

    component ram
        generic(width:integer;
            length:integer);
        port(write_addr_A, write_addr_B: in std_logic_vector(length-1 downto 0);
             write_A, write_B: in std_logic_vector(width-1 downto 0);
             write_enable_A, write_enable_B, clk: in std_logic;
             read_addr_A, read_addr_B: in std_logic_vector(length-1 downto 0);
             read_A, read_B: out std_logic_vector(width-1 downto 0);
             test0 : out std_logic_vector(15 downto 0));
    end component;
    component rom
    generic(
        width :integer;
        length :integer
    ) ;
    port (
        addr: in std_logic_vector(length-1 downto 0);
        value: out std_logic_vector(width-1 downto 0)
    );
    end component;
begin
    mu: management_unit
    generic map (
        N => N,
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
        write_B_enable => write_B_enable,
        get_input => get_input
    );
    bfu: butterfly
    generic map(
        width_A => width,
        width_twiddle => width_twiddle
    )
    port map(
        inA => bfu_A,
        outA => write_A,
        twiddle => twiddle,
        inB => bfu_B,
        outB => write_B
    );
    ram_real: ram
    generic map (
        width => 2*width,
        length => N
    )
    port map(
        write_addr_A => write_A_addr,
        write_addr_B => write_B_addr,
        write_A => write_A, 
        write_B => write_B,
        write_enable_A => write_A_enable, 
        write_enable_B => write_B_enable,
        clk => clk,
        read_addr_A => read_A_addr, 
        read_addr_B => read_B_addr,
        read_A => read_A, 
        read_B => read_B,
        test0 => test0
    );
    twiddle_rom: rom
    generic map (
        width => 2*width_twiddle,
        length => N - 1
    )
    port map (
        addr => twiddle_addr,
        value => twiddle
    );
    bfu_A <= read_A when get_input = '0' else inA;
    bfu_B <= read_B when get_input = '0' else inB;
    write_A_addr <= addr_A_write(0)&addr_A_write(1)&addr_A_write(2);
    write_B_addr <= addr_B_write(0)&addr_B_write(1)&addr_B_write(2);
    read_A_addr <= addr_A_read(0)&addr_A_read(1)&addr_A_read(2);
    read_B_addr <= addr_B_read(0)&addr_B_read(1)&addr_B_read(2);
    
end fft_b;
