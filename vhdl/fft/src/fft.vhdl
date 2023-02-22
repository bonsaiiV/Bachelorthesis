library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft is
    generic(N : integer := 3;
            width : integer := 24; 
            width_twiddle : integer := 8);
    port (
        clk, fft_start : in std_logic;
        output_valid : out std_logic;
        inA, inB : in std_logic_vector(2*width-1 downto 0);
        outA, outB: out std_logic_vector(2*width-1 downto 0)
    );
end fft;

architecture fft_b of fft is
    component management_unit
    generic(
        N: integer;
        layer_l: integer);
    port(fft_start, clk: in std_logic;
        twiddle_addr: out std_logic_vector(N-2 downto 0);
        bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B: out std_logic_vector(N-1 downto 0);
        generate_output, write_A_enable, write_B_enable: out std_logic;
        get_input: out std_logic;
        select_bank_out: out std_logic);
    end component;
    signal twiddle_addr: std_logic_vector(N-2 downto 0);
    signal write_A_enable, write_B_enable: std_logic;
    signal bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B: std_logic_vector(N-1 downto 0);
    signal generate_output: std_logic;
    signal select_bank: std_logic;

    component butterfly
    generic(width_A, width_twiddle : integer);
    port(   inA, inB     : in  std_logic_vector(width_A*2-1 downto 0);
            twiddle : in  std_logic_vector(width_twiddle*2-1 downto 0);
            outA, outB : out std_logic_vector(width_A*2-1 downto 0));
    end component;

    signal twiddle: std_logic_vector(2*width_twiddle-1 downto 0);
    signal bfu_A, bfu_B : std_logic_vector(2*width-1 downto 0);
    signal data_read_A, data_read_B, data_write_A, data_write_B: std_logic_vector(2*width-1 downto 0);
    signal get_input: std_logic;

    component ram_group
        generic(width:integer;
            length:integer);
        port(bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B: in std_logic_vector(length-1 downto 0);
             data_write_A, data_write_B: in std_logic_vector(width-1 downto 0);
             write_enable_A, write_enable_B, clk: in std_logic;
             data_read_A, data_read_B: out std_logic_vector(width-1 downto 0):= (others => '0');
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
        layer_l => 2
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
        write_A_enable => write_A_enable,
        write_B_enable => write_B_enable,
        get_input => get_input,
        select_bank_out => select_bank
    );
    bfu: butterfly
    generic map(
        width_A => width,
        width_twiddle => width_twiddle
    )
    port map(
        inA => data_read_A,
        outA => bfu_A,
        twiddle => twiddle,
        inB => data_read_B,
        outB => bfu_B
    );
    ram: ram_group
    generic map (
        width => 2*width,
        length => N
    )
    port map(
        bank0_addr_A => bank0_addr_A,
        bank0_addr_B => bank0_addr_B,
        bank1_addr_A => bank1_addr_A,
        bank1_addr_B => bank1_addr_B,
        data_write_A => data_write_A, 
        data_write_B => data_write_B,
        write_enable_A => write_A_enable, 
        write_enable_B => write_B_enable,
        clk => clk,
        data_read_A => data_read_A, 
        data_read_B => data_read_B,
        select_bank => select_bank
    );
    twiddle_rom: rom
    generic map (
        width => 2*width_twiddle,
        length => N - 1
    )
    port map (
        clk => clk,
        addr => twiddle_addr,
        value => twiddle
    );
    data_write_A <= bfu_A when get_input = '0' else inA;
    data_write_B <= bfu_B when get_input = '0' else inB;
    output_valid <= generate_output;
    outA <= bfu_A;
    outB <= bfu_B;
    
end fft_b;
