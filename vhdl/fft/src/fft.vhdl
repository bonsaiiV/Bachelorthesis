library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library xil_defaultlib;
use xil_defaultlib.types.all;

entity fft is
    generic(N : integer := 4;
            width : integer := 24; 
            width_twiddle : integer := 8;
            log2_paths : integer := 1;
            paths : integer := 2);
    port (
        clk, fft_start : in std_logic;
        output_valid : out std_logic := '0';
        inA, inB : in std_logic_vector(2*width-1 downto 0);
        outA, outB: out std_logic_vector(2*width-1 downto 0) := (others => '0')
    );
end fft;

architecture fft_b of fft is

    --control signals
    signal generate_output: std_logic := '0';
    signal output_valid_buff1, output_valid_buff2: std_logic := '0';
    signal get_input: std_logic := '0';

    signal write_enable : std_logic_vector(2*paths-1 downto 0) := (others => '0');

        
    --mux are arrays used in the merge process to match the ram data to the correct bfu
    type MUX is array(0 to 2**(log2_paths+1)-1) of std_logic_vector(2*width-1 downto 0);

    --data signals
    signal read_buff: MUX := (others => (others => '0'));
    signal write_buff: MUX := (others => (others => '0'));
    signal bfu_in, bfu_out: MUX := (others => (others => '0'));
    signal inA_buff1, inB_buff1, inA_buff2, inB_buff2, inA_buff3, inB_buff3:  std_logic_vector(2*width-1 downto 0);

    --address signals

    signal outA_source, outB_source : std_logic_vector(log2_paths downto 0);

    signal read_ram_switch, write_ram_switch: addr_MUX := (others => (others => '0'));

    signal bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B: std_logic_vector(N-log2_paths-1 downto 0) := (others => '0');
    signal reversed_A_addr, reversed_B_addr: std_logic_vector(N-log2_paths-1 downto 0) := (others => '0');

    signal select_bank: std_logic;

    --twiddle signals
    type TWIDS is array (0 to paths-1) of std_logic_vector(2*width_twiddle-1 downto 0);
    signal twiddle_addr: twiddle_addr_ARRAY := (others => (others => '0'));
    signal twiddle: TWIDS := (others => (others => '0'));

    --components 

    component management_unit
    generic(
        N: integer;
        layer_l: integer;
        log2_paths: integer;
        paths: integer);
    port(fft_start, clk: in std_logic;
        twiddle_addr: out twiddle_addr_ARRAY;
        bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B: out std_logic_vector(N-log2_paths-1 downto 0);
        generate_output: out std_logic;
        get_input: out std_logic;
        read_ram_switch, write_ram_switch: out addr_MUX;
        write_enable: out std_logic_vector(2*paths-1 downto 0);
        outA_source, outB_source: out std_logic_vector(log2_paths downto 0);
        select_bank_out: out std_logic);
    end component;

    component butterfly
    generic(width_A, width_twiddle : integer);
    port(   inA, inB     : in  std_logic_vector(width_A*2-1 downto 0);
            twiddle : in  std_logic_vector(width_twiddle*2-1 downto 0);
            outA, outB : out std_logic_vector(width_A*2-1 downto 0));
    end component;

    component ram_group
        generic(width:integer;
            length:integer);
        port(bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B: in std_logic_vector(length-1 downto 0);
             write_A, write_B: in std_logic_vector(width-1 downto 0);
             write_enable_A, write_enable_B, clk: in std_logic;
             read_A, read_B: out std_logic_vector(width-1 downto 0);
             select_bank: in std_logic);
    end component;

    component rom
    generic(
        width :integer;
        length :integer
    ) ;
    port (
        clk: in std_logic;
        addr: in std_logic_vector(length-1 downto 0);
        value: out std_logic_vector(width-1 downto 0)
    );
    end component;

    
begin
    mu: management_unit
    generic map (
        N => N,
        layer_l => 2,
        log2_paths => log2_paths,
        paths => paths
    )
    port map (
        fft_start => fft_start,
        clk => clk,
        twiddle_addr => twiddle_addr,
        bank0_addr_A => bank0_addr_A,
        bank0_addr_B => bank0_addr_B,
        bank1_addr_A => bank1_addr_A,
        bank1_addr_B => bank1_addr_B,
        generate_output => generate_output,
        write_enable => write_enable,
        get_input => get_input,
        read_ram_switch => read_ram_switch, 
        write_ram_switch => write_ram_switch,
        outA_source => outA_source,
        outB_source => outB_source,
        select_bank_out => select_bank
    );
    gen_path: for i in 0 to paths-1 generate
        bfu: butterfly
        generic map(
            width_A => width,
            width_twiddle => width_twiddle
        )
        port map(
            inA => bfu_in(2*i),
            outA => bfu_out(2*i),
            twiddle => twiddle(i),
            inB => bfu_in(2*i+1),
            outB => bfu_out(2*i+1)
        );
        ram_instance: ram_group
        generic map (
            width => 2*width,
            length => N-log2_paths
        )
        port map(
            bank0_addr_A => bank0_addr_A,
            bank0_addr_B => bank0_addr_B,
            bank1_addr_A => bank1_addr_A,
            bank1_addr_B => bank1_addr_B,
            write_A => write_buff(2*i), 
            write_B => write_buff(2*i+1),
            write_enable_A => write_enable(2*i), 
            write_enable_B => write_enable(2*i+1),
            clk => clk,
            read_A => read_buff(2*i), 
            read_B => read_buff(2*i+1),
            select_bank => select_bank
        );
        twiddle_rom: rom
        generic map (
            width => 2*width_twiddle,
            length => N - 1
        )
        port map (
            clk => clk,
            addr => twiddle_addr(i),
            value => twiddle(i)
        );
    end generate gen_path;

    --buffering inputs, because mu needs a few cicles to get ready
    process(clk)
    begin
        if(rising_edge(clk)) then
            inA_buff1 <= inA;
            inA_buff2 <= inA_buff1;
            inA_buff3 <= inA_buff2;
            inB_buff1 <= inB;
            inB_buff2 <= inB_buff1;
            inB_buff3 <= inB_buff2;
        end if;
    end process;
    --IO
    outA <= read_buff(to_integer(unsigned(outA_source)));
    outB <= read_buff(to_integer(unsigned(outB_source)));

    gen_write_switching: for i in 0 to paths-1 generate
        write_buff(i) <= bfu_out(to_integer(unsigned(write_ram_switch(i)))) when get_input = '0' else inA_buff3;
        write_buff(paths+i) <= bfu_out(to_integer(unsigned(write_ram_switch(paths+i)))) when get_input = '0' else inB_buff3;
    end generate gen_write_switching;



    output_valid <= generate_output;




    gen_read_switching: for i in 0 to 2*paths-1 generate
        bfu_in(i) <= read_buff(to_integer(unsigned(read_ram_switch(i))));
    end generate gen_read_switching;

    
end fft_b;
