library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library fft_types;
use fft_types.types.all;

entity management_unit is
    generic(
            N: integer;
            layer_l: integer;
            log2_paths: integer:=1;
            paths: integer:=2); --amount of splits in paths of fft
    port(fft_start, clk: in std_logic;
         twiddle_addr: out std_logic_vector(N-2 downto 0) := (others => '0');
         addr_A_read, addr_A_write: out std_logic_vector(N-log2_paths-1 downto 0) := (others => '0');
         addr_B_read, addr_B_write: out std_logic_vector(N-log2_paths-1 downto 0) := (others => '1');
         generate_output: out std_logic := '0';
         get_input: out std_logic := '1';
         read_ram_switch, write_ram_switch: out addr_MUX := (others => (others => '0'));
         write_enable: out std_logic_vector(2*paths-1 downto 0));
end management_unit;

architecture management_unit_b of management_unit is
    
    --control signals
    signal io_done, index_resets, fft_running: std_logic := '0';
    signal is_merging: std_logic := '0';
    signal fft_finished: std_logic:='1'; -- internal impulse to end calculation, default to 1 for make sure everything gets set correctly
    signal is_getting_input, is_getting_input_buff1, is_getting_input_buff2 : std_logic:= '1';

    signal io_active_ram: std_logic_vector(log2_paths-2 downto 0) := (others => '0');

    signal layer_incr, layer_incr_enable : std_logic:='0';

    --address generation signals

    signal index: std_logic_vector(N-log2_paths-2 downto 0);
    signal layer: std_logic_vector(layer_l-1 downto 0):= (others => '0');
    signal ram_A_addresses, ram_B_addresses, addr_A_write_buff1, addr_B_write_buff1, addr_A_write_buff2, addr_B_write_buff2: std_logic_vector(N-log2_paths-1 downto 0) := (others => '0');

    signal merge_step: std_logic_vector(log2_paths-1 downto 0) := (others => '0');

    signal io_addresses: std_logic_vector(N-log2_paths-1 downto 0);
    signal io_element_nr, rev_io_element_nr: std_logic_vector(N-2 downto 0);
    signal io_write_enable: std_logic_vector(2*paths-1 downto 0);
    signal chunk: std_logic_vector(log2_paths-1 downto 0);

    signal write_ram_switch_buff1, write_ram_switch_buff2: addr_MUX := (others => (others => '0'));

    --twiddle address signals
    signal twiddle_mask: std_logic_vector(N-log2_paths-1 downto 0) := (others => '0');
    signal tmp_mask, constant_mask: std_logic_vector(N-log2_paths-1 downto 0) := ('1', others => '0');


    component counter
        generic (count_width : integer; max : integer);
        port(enable, clk : in std_logic;
             clr : in std_logic;
             value : out std_logic_vector(count_width-1 downto 0);
             resets : out std_logic);
    end component;

begin
    --managing state of fft
    process(fft_start, fft_finished) 
    begin
        if(fft_start = '1') then
            fft_running <= '1';
        elsif(fft_finished = '1') then
            fft_running <= '0';
        end if;
    end process;

    gen_rev_io_if: if log2_paths = 1 generate
        io_write_enable(0) <= '1';
        io_write_enable(1) <= '0';
        io_write_enable(2) <= '1';
        io_write_enable(3) <= '0';
    end generate gen_rev_io_if;

    gen_rev_io_else: if log2_paths > 1 generate
        io_active_ram <= rev_io_element_nr(N-2 downto N-log2_paths) & '0';
        gen_ram_enable: for i in 0 to paths-1 generate 
            io_write_enable(i) <= '1' when to_integer(unsigned(io_active_ram)) = i else '0';
            io_write_enable(paths + i) <= '1' when to_integer(unsigned(io_active_ram)) = i else '0';
        end generate gen_ram_enable;
    end generate gen_rev_io_else;

    write_enable <= io_write_enable when is_getting_input_buff2 = '1' else (others => '1');


    process(fft_start, fft_finished) 
    begin
        if(fft_start = '1') then
            generate_output <= '1';
        elsif(fft_finished = '1') then
            generate_output <= '0';
        end if;
    end process;
    generate_output <= '1' when to_integer(unsigned(layer)) = n-1 else '0';

    process(clk)
    begin
        if(rising_edge(clk)) then
            layer_incr_enable <= not is_getting_input;
        end if;
    end process;

    process(fft_finished, index_resets)
    begin
        if(fft_finished = '1') then
            is_getting_input <= '1';
        elsif(io_done = '1') then
            is_getting_input <= '0';
        end if;
    end process;

    get_input <= is_getting_input_buff2;

    process(clk)
    begin
        if(rising_edge(clk)) then
            -- this buffer is important since bfu is 2 cycles
            is_getting_input_buff1 <= is_getting_input;
            is_getting_input_buff2 <= is_getting_input_buff1;

        end if;
    end process;

    is_merging <= '1' when to_integer(unsigned(layer)) >= n-log2_paths-1 else '0';



    --address generation


    --this counter is for IO:
    --since the index doesn't iterate over N/2 anymore (instead N/(2*2^log2_paths))
    --this is because there are 2^log2_paths butterfly units, each acting on 2 elements
    --io hoever stays on 2 wires, so it needs 2^log2_paths iterations
    IO_Chunk_cnt: counter
        generic map (
            count_width => log2_paths,
            max => paths-1
        )
        port map (
            enable => is_getting_input,
            clr => fft_finished,
            clk => index_resets,
            value => chunk,
            resets => io_done
        );
    
    merge_cnt: counter
        generic map (
            count_width => log2_paths,
            max => log2_paths
        )
        port map (
            enable => is_merging,
            clr => fft_finished,
            clk => index_resets,
            value => merge_step,
            resets => fft_finished
        );

    Index_cnt: counter
        generic map (
            count_width => N-log2_paths-1,
            max => 2**(N-log2_paths-1)-1
        )
        port map(
            enable => fft_running,
            clr => fft_finished,
            clk => clk,
            value => index,
            resets => index_resets
        );

    Layer_cnt: counter
        generic map (
            count_width => layer_l,
            max => n-1
        )
        port map(
            enable => layer_incr_enable,
            clr => fft_finished,
            clk => index_resets,
            value => layer,
            resets => fft_finished
        );
    
    io_element_nr <= chunk & index;

    gen_rev_io: for i in 0 to N-2 generate
        rev_io_element_nr(i) <= io_element_nr(N-2-i);
    end generate gen_rev_io;

    io_addresses <= rev_io_element_nr(N-log2_paths-1 downto 0);


    addr_A_read <= ram_A_addresses;
    addr_B_read <= ram_B_addresses;
    
    --when merging, ram elements are taken in order since permutation happens on ram level not address level
    ram_A_addresses <= std_logic_vector(unsigned(index & '0') ROL to_integer(unsigned(layer))) when is_merging = '0' else index & '0';
    ram_B_addresses <= std_logic_vector(unsigned(index & '1') ROL to_integer(unsigned(layer))) when is_merging = '0' else index & '1';
    process(clk)
    begin
        if(rising_edge(clk)) then
            addr_A_write <= addr_A_write_buff2;
            addr_B_write <= addr_B_write_buff2;

            addr_A_write_buff2 <= addr_A_write_buff1;
            addr_B_write_buff2 <= addr_B_write_buff1;
            
        end if;
    end process;


    addr_A_write_buff1 <= io_addresses when is_getting_input = '1' else ram_A_addresses;
    addr_B_write_buff1 <= io_addresses when is_getting_input = '1' else ram_B_addresses;

    gen_ram_switch: for i in 0 to 2*(log2_paths+1)-1 generate
            read_ram_switch(i) <= std_logic_vector(to_unsigned(i, log2_paths+1) ROL to_integer(unsigned(merge_step)));
            write_ram_switch_buff2(i) <= std_logic_vector(to_unsigned(i, log2_paths+1) ROR to_integer(unsigned(merge_step)));
    end generate gen_ram_switch;


    process(clk)
    begin
        if(rising_edge(clk)) then
            write_ram_switch_buff1 <= write_ram_switch_buff2;
            write_ram_switch <= write_ram_switch_buff1;
        end if;
    end process;


    --twiddle
    twiddle_addr <= '0' & (index and twiddle_mask(N-log2_paths-2 downto 0));
    twiddle_mask <= std_logic_vector(shift_right(signed(constant_mask), to_integer(unsigned(layer))));

end management_unit_b;
    