library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library fft_types;
use fft_types.types.all;

entity fft is
    generic(N : integer := 3;
            width : integer := 8; 
            width_twiddle : integer := 6;
            n_parallel : integer := 1); --number of splits in a path: the amount of paths is 2**n_parallel
    port (
        clk, fft_start : in std_logic;
        output_valid : out std_logic := '0';
        inA, inB : in std_logic_vector(2*width-1 downto 0);
        outA, outB: out std_logic_vector(2*width-1 downto 0)
    );
end fft;

architecture fft_b of fft is
    component management_unit
    generic(
        N: integer;
        layer_l: integer;
        n_parallel: integer);
    port(fft_start, clk: in std_logic;
        twiddle_addr: out std_logic_vector(N-2 downto 0);
        addr_A_read, addr_B_read, addr_A_write, addr_B_write: out std_logic_vector(N-n_parallel-1 downto 0);
        generate_output, write_enable: out std_logic;
        get_input: out std_logic;
        ram_re_addr: out addr_MUX);
    end component;
    signal addr_A_read_buff, addr_B_read_buff, addr_A_write_buff, addr_B_write_buff: std_logic_vector(N-n_parallel-1 downto 0);
    signal write_enable: std_logic;
    signal read_A_addr, read_B_addr, write_A_addr, write_B_addr: std_logic_vector(N-n_parallel-1 downto 0);
    signal reversed_A_addr, reversed_B_addr: std_logic_vector(N-n_parallel-1 downto 0);

    --control signals
    signal generate_output: std_logic;
    signal output_valid_buff1, output_valid_buff2: std_logic := '0';


    --mux are arrays used in the merge process to match the ram data to the correct bfu
    type MUX is array(0 to 2**(n_parallel+1)-1) of std_logic_vector(2*width-1 downto 0);
    signal read_buff: MUX := (others => (others => '0'));
    signal write_buff: MUX := (others => (others => '0'));
    signal ram_write_enable : std_logic_vector(2**(n_parallel+1)-1 downto 0);
    signal bfu_in, bfu_out: MUX := (others => (others => '0'));
    signal ram_re_addr, write_re_addr_buff1, write_re_addr_buff2: addr_MUX := (others => (others => '0'));

    component butterfly
    generic(width_A, width_twiddle : integer);
    port(   clk : in std_logic;
            inA, inB     : in  std_logic_vector(width_A*2-1 downto 0);
            twiddle : in  std_logic_vector(width_twiddle*2-1 downto 0);
            outA, outB : out std_logic_vector(width_A*2-1 downto 0));
    end component;


    signal twiddle_addr: std_logic_vector(N-2 downto 0);
    signal twiddle: std_logic_vector(2*width_twiddle-1 downto 0);

    signal get_input: std_logic;

    component ram
        generic(width:integer;
            length:integer);
        port(write_addr_A, write_addr_B: in std_logic_vector(length-1 downto 0);
             write_A, write_B: in std_logic_vector(width-1 downto 0);
             write_enable_A, write_enable_B, clk: in std_logic;
             read_addr_A, read_addr_B: in std_logic_vector(length-1 downto 0) := (others => '0');
             read_A, read_B: out std_logic_vector(width-1 downto 0));
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
        layer_l => 2,
        n_parallel => n_parallel
    )
    port map (
        fft_start => fft_start,
        clk => clk,
        twiddle_addr => twiddle_addr,
        addr_A_read => addr_A_read_buff,
        addr_B_read => addr_B_read_buff,
        addr_A_write => addr_A_write_buff,
        addr_B_write => addr_B_write_buff,
        generate_output => generate_output,
        write_enable => write_enable,
        get_input => get_input,
        ram_re_addr => ram_re_addr
    );
    bfu1: butterfly
    generic map(
        width_A => width,
        width_twiddle => width_twiddle
    )
    port map(
        clk => clk,
        inA => bfu_in(0),
        outA => bfu_out(0),
        twiddle => twiddle,
        inB => bfu_in(1),
        outB => bfu_out(1)
    );
    ram1: ram
    generic map (
        width => 2*width,
        length => N-n_parallel
    )
    port map(
        write_addr_A => write_A_addr,
        write_addr_B => write_B_addr,
        write_A => write_buff(0), 
        write_B => write_buff(1),
        write_enable_A => ram_write_enable(0), 
        write_enable_B => ram_write_enable(1),
        clk => clk,
        read_addr_A => read_A_addr, 
        read_addr_B => read_B_addr,
        read_A => read_buff(0), 
        read_B => read_buff(1)
    );
    bfu2: butterfly
    generic map(
        width_A => width,
        width_twiddle => width_twiddle
    )
    port map(
        clk => clk,
        inA => bfu_in(2),
        outA => bfu_out(2),
        twiddle => twiddle,
        inB => bfu_in(3),
        outB => bfu_out(3)
    );
    ram2: ram
    generic map (
        width => 2*width,
        length => N-n_parallel
    )
    port map(
        write_addr_A => write_A_addr,
        write_addr_B => write_B_addr,
        write_A => write_buff(2), 
        write_B => write_buff(3),
        write_enable_A => ram_write_enable(2), 
        write_enable_B => ram_write_enable(3),
        clk => clk,
        read_addr_A => read_A_addr, 
        read_addr_B => read_B_addr,
        read_A => read_buff(2), 
        read_B => read_buff(3)
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


    ram_write_enable(0) <= write_enable;
    ram_write_enable(1) <= write_enable when get_input = '0' else '0';
    ram_write_enable(2) <= write_enable;
    ram_write_enable(3) <= write_enable when get_input = '0' else '0';

    write_buff(to_integer(unsigned(write_re_addr_buff2(0)))) <= bfu_out(0) when get_input = '0' else inA;
    write_buff(to_integer(unsigned(write_re_addr_buff2(1)))) <= bfu_out(1);
    write_buff(to_integer(unsigned(write_re_addr_buff2(2)))) <= bfu_out(2) when get_input = '0' else inB;
    --TODO do not use the readressing in value written to!!!!
    outA <= bfu_out(0);
    outB <= bfu_out(2);

    --output valid need to be delayed, since it rises once the last cycle starts and not when the first element of it finishes
    output_valid_buff1 <= generate_output;
    process(clk)
    begin
        if (rising_edge(clk)) then
            output_valid <= output_valid_buff2;
            output_valid_buff2 <= output_valid_buff1;

            write_re_addr_buff1 <= ram_re_addr;
            write_re_addr_buff2 <= write_re_addr_buff1;
        end if;
    end process;

    gen_write_re_addr: for i in 3 to 2*(n_parallel+1)-1 generate
        write_buff(to_integer(unsigned(write_re_addr_buff2(i)))) <= bfu_out(i);
    end generate gen_write_re_addr;

    gen_read_re_addr: for i in 0 to 2*(n_parallel+1)-1 generate
            bfu_in(i) <= read_buff(to_integer(unsigned(ram_re_addr(i))));
    end generate gen_read_re_addr;

    --reverse addresses to simulate permutating except for input to make it natural ordered
    gen_rev_addr: for i in 0 to N-n_parallel-1 generate
        reversed_A_addr(i) <= addr_A_write_buff(N-n_parallel-i-1);
        reversed_B_addr(i) <= addr_B_write_buff(N-n_parallel-i-1);
        read_A_addr(i) <= addr_A_read_buff(N-n_parallel-i-1);
        read_B_addr(i) <= addr_B_read_buff(N-n_parallel-i-1);
    end generate gen_rev_addr;

    write_A_addr <= reversed_A_addr when get_input = '0' else addr_A_write_buff;
    write_B_addr <= reversed_B_addr;
    
end fft_b;
