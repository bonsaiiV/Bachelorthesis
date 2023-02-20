library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library xil_defaultlib;
use xil_defaultlib.types.all;

entity management_unit is
    generic(
            N: integer;
            layer_l: integer;
            log2_paths: integer:=1;
            paths: integer:=2); --amount of splits in paths of fft
    port(fft_start, clk: in std_logic;
         twiddle_addr: out twiddle_addr_ARRAY := (others => (others => '0'));
         bank0_addr_A, bank1_addr_A: out std_logic_vector(N-log2_paths-1 downto 0) := (others => '0');
         bank0_addr_B, bank1_addr_B: out std_logic_vector(N-log2_paths-1 downto 0) := (others => '1');
         generate_output: out std_logic := '0';
         get_input: out std_logic := '1';
         read_ram_switch, write_ram_switch: out addr_MUX := (others => (others => '0'));
         write_enable: out std_logic_vector(2*paths-1 downto 0);
         outA_source, outB_source: out std_logic_vector(log2_paths downto 0);
         select_bank_out: out std_logic);
end management_unit;

architecture management_unit_b of management_unit is
    
    --control signals
    signal io_is_in: std_logic := '1';
    signal io_done, is_doing_io: std_logic := '0'; 
    signal index_resets, fft_running: std_logic := '0';
    signal fft_start_impulse: std_logic := '0';
    signal is_merging: std_logic := '0';
    signal fft_finished, fft_calc_finished: std_logic:='1'; -- internal impulse to end calculation, default to 1 for make sure everything gets set correctly

    signal io_active_ram: std_logic_vector(log2_paths-2 downto 0) := (others => '0');
    signal io_write_enable, in_write_enable, calc_write_enable: std_logic_vector(2*paths-1 downto 0);

    signal layer_incr: std_logic:='0';
    signal io_chunk_incr, merge_cnt_incr, index_clr : std_logic :='0';
    signal disable_calc_write, disable_calc_write_buff: std_logic;

    signal discard_bit: std_logic;
    --address generation signals

    signal index, index_buff1, index_buff2, rev_index: std_logic_vector(N-log2_paths-2 downto 0) := (others => '0');
    signal layer: std_logic_vector(layer_l-1 downto 0):= (others => '0');
    signal ram_A_addresses, ram_B_addresses: std_logic_vector(N-log2_paths-1 downto 0) := (others => '0');

    signal merge_step, merge_zero: std_logic_vector(log2_paths-1 downto 0) := (others => '0');
    signal io_addr_A, io_addr_B: std_logic_vector(N-log2_paths-1 downto 0);
    signal io_element_nr, rev_io_element_nr: std_logic_vector(N-2 downto 0);
    signal chunk, chunk_buff: std_logic_vector(log2_paths-1 downto 0) := (others => '0');
    signal addr_A, addr_B, addr_A_write, addr_B_write: std_logic_vector(N-log2_paths-1 downto 0) := (others => '0');

    signal select_bank, select_bank_buff: std_logic := '0';

    --twiddle address signals
    signal twiddle_mask: std_logic_vector(N-1 downto 0) := (others => '0');
    signal constant_mask: std_logic_vector(N-1 downto 0) := ('1', others => '0'); 
    type path_index_ARRAY is array(0 to paths-1) of std_logic_vector(log2_paths-1 downto 0);
    signal rev_path_index, merge_step_dependend_path_index, tmp_path_index: path_index_ARRAY;

    signal layer_independend_twiddle_addr, full_index: twiddle_addr_ARRAY;


    component counter
        generic (count_width : integer; max : integer);
        port(enable, clk : in std_logic;
             clr : in std_logic;
             value : out std_logic_vector(count_width-1 downto 0);
             resets : out std_logic);
    end component;

begin
    --managing state of fft
    process(clk) 
    begin
        if(rising_edge(clk)) then
            if(fft_running = '0') then
                fft_start_impulse <= fft_start;
            else
                fft_start_impulse <= '0';
            end if;
        end if;
    end process;

    process(clk) 
    begin
        if(rising_edge(clk)) then
            if(fft_start_impulse = '1') then
                fft_running <= '1';
            elsif(fft_finished = '1') then
                fft_running <= '0';
            end if;
        end if;
    end process;

    process(clk) 
    begin
        if(rising_edge(clk)) then
            if(io_done = '1') then
                io_is_in <= not io_is_in;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if(rising_edge(clk)) then
            if(io_done = '1') then
                if(io_is_in = '0') then
                    fft_finished <= '1';
                end if;
            elsif(fft_start_impulse = '1') then
                fft_finished <= '0';
            end if;
        end if;
    end process;

    process(clk)
    begin
        if(rising_edge(clk)) then
            if(fft_calc_finished = '1' or fft_start_impulse = '1') then
                is_doing_io <= '1';
            elsif(io_done = '1') then
                is_doing_io <= '0';
            end if;
        end if;
    end process;


    gen_rev_io_if: if log2_paths = 1 generate
        in_write_enable(0) <= '1';
        in_write_enable(1) <= '0';
        in_write_enable(2) <= '1';
        in_write_enable(3) <= '0';
    end generate gen_rev_io_if;

    gen_rev_io_else: if log2_paths > 1 generate
        process(clk)
        begin
            if (rising_edge(clk)) then
                io_active_ram <= rev_io_element_nr(N-2 downto N-log2_paths+1) & '0';
            end if;
        end process;
        gen_ram_enable: for i in 0 to paths-1 generate 
            in_write_enable(i) <= '1' when to_integer(unsigned(io_active_ram)) = i else '0';
            in_write_enable(paths + i) <= '1' when to_integer(unsigned(io_active_ram)) = i else '0';
        end generate gen_ram_enable;
    end generate gen_rev_io_else;

    io_write_enable <= in_write_enable when io_is_in = '1' else (others => '0');
    calc_write_enable <= (others => '0') when disable_calc_write = '1' else (others => '1');
    write_enable <= io_write_enable when is_doing_io = '1' else calc_write_enable;

    process(clk)
    begin
        if rising_edge(clk) then
            disable_calc_write_buff <= index_resets;
            disable_calc_write <= disable_calc_write_buff;
        end if ;
    end process;


    process(clk) 
    begin
        if(rising_edge(clk)) then
            if(fft_calc_finished = '1') then
                generate_output <= '1';
            elsif(io_done = '1') then
                generate_output <= '0';
            end if;
        end if;
    end process;

    --process(clk)
    --begin
    --    if(rising_edge(clk)) then
            layer_incr <= index_resets and (not is_doing_io);
    --    end if;
    --end process;

    

    get_input <= is_doing_io;

 

    process(clk)
    begin
        if(rising_edge(clk)) then
            if(to_integer(unsigned(layer)) >= n-log2_paths-1) then
                is_merging <= '1';
            else
                is_merging <= '0';
            end if;
            merge_cnt_incr <= index_resets and is_merging;
        end if;
    end process;
    --is_merging <= '1' when to_integer(unsigned(layer)) >= n-log2_paths-1 else '0';

    io_chunk_incr <= index_resets and is_doing_io;
 
    index_clr <= index_resets or fft_finished when to_integer(unsigned(chunk)) = paths-1 or is_doing_io = '0' else '0'; 



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
            enable => io_chunk_incr,
            clr => io_done,
            clk => clk,
            value => chunk,
            resets => io_done
        );
    
    merge_cnt: counter
        generic map (
            count_width => log2_paths,
            max => log2_paths
        )
        port map (
            enable => merge_cnt_incr,
            clr => fft_calc_finished,
            clk => clk,
            value => merge_step,
            resets => fft_calc_finished
        );

    Index_cnt: counter
        generic map (
            count_width => N-log2_paths-1,
            max => 2**(N-log2_paths-1)-1
        )
        port map(
            enable => fft_running,
            clr => index_clr,
            clk => clk,
            value => index_buff1,
            resets => index_resets
        );

    Layer_cnt: counter
        generic map (
            count_width => layer_l,
            max => n-1
        )
        port map(
            enable => layer_incr,
            clr => fft_finished,
            clk => clk,
            value => layer,
            resets => discard_bit
        );
    --buffering to line signals up
    process(clk)
    begin
        if(rising_edge(clk)) then
            --chunk <= chunk_buff;
            --index_buff2 <= index_buff1;
            index <= index_buff1;
            addr_A_write <= addr_A;
            addr_B_write <= addr_B;
        end if;
    end process;
    
    io_element_nr <= chunk & index;

    gen_rev_io: for i in 0 to N-2 generate
        rev_io_element_nr(i) <= io_element_nr(N-2-i);
    end generate gen_rev_io;

    --io_addresses <= rev_io_element_nr(N-log2_paths-2 downto 0) when io_is_in = '1' else io_element_nr(N-log2_paths-2 downto 0);
    process(clk)
    begin
        if(rising_edge(clk)) then
            outA_source <= io_element_nr(N-2 downto N-log2_paths-1) & '0'; --appending 0 means reading output from slot A of the ram
            outB_source <= io_element_nr(N-2 downto N-log2_paths-1) & '1';
        end if;
    end process;

    select_bank_out <= select_bank_buff;
    process(clk)
    begin
        if(rising_edge(clk)) then
            if (layer_incr = '1' or io_done = '1') then
                select_bank <= not select_bank;
            end if ;
            if (io_done = '1') then
                select_bank_buff <= not select_bank;
            else
                select_bank_buff <= select_bank;
            end if;
        end if;
    end process;
    
    --when merging, ram elements are taken in order since permutation happens on ram level not address level
    ram_A_addresses <= std_logic_vector(unsigned(index & '0') ROL to_integer(unsigned(layer))) when merge_step = merge_zero else index & '0';
    ram_B_addresses <= std_logic_vector(unsigned(index & '1') ROL to_integer(unsigned(layer))) when merge_step = merge_zero else index & '1';

    io_addr_A <= rev_io_element_nr(N-log2_paths-1 downto 0) when io_is_in = '1' else io_element_nr(N-log2_paths-2 downto 0) & '0';
    io_addr_B <= rev_io_element_nr(N-log2_paths-1 downto 0) when io_is_in = '1' else io_element_nr(N-log2_paths-2 downto 0) & '1';

    addr_A <= io_addr_A when is_doing_io = '1' else ram_A_addresses;
    addr_B <= io_addr_B when is_doing_io = '1' else ram_B_addresses;

    bank0_addr_A <= addr_A when select_bank_buff = '1' else addr_A_write;
    bank0_addr_B <= addr_B when select_bank_buff = '1' else addr_B_write;
    bank1_addr_A <= addr_A when select_bank_buff = '0' else addr_A_write;
    bank1_addr_B <= addr_B when select_bank_buff = '0' else addr_B_write;

    gen_ram_switch: for i in 0 to 2*(log2_paths+1)-1 generate
            read_ram_switch(i) <= std_logic_vector(to_unsigned(i, log2_paths+1) ROL to_integer(unsigned(merge_step)));
            write_ram_switch(i) <= std_logic_vector(to_unsigned(i, log2_paths+1) ROR to_integer(unsigned(merge_step)));
    end generate gen_ram_switch;



    --todo twiddle gen for multiple paths
    gen_rev_index: for i in 0 to N-log2_paths-2 generate
        rev_index(i) <= index(N-log2_paths-2-i);
    end generate gen_rev_index;

    --twiddle
    gen_twiddle_addr: for path_index in 0 to paths-1 generate
        tmp_path_index(path_index) <= std_logic_vector(to_unsigned(path_index, log2_paths));
        gen_rev_path_index: for i in 0 to log2_paths-1 generate
            rev_path_index(path_index)(log2_paths-1-i) <= tmp_path_index(path_index)(i);
        end generate gen_rev_path_index;
        merge_step_dependend_path_index(path_index) <= std_logic_vector(unsigned(unsigned(rev_path_index(path_index)) ROR 1) ROL to_integer(unsigned(merge_step)));
        full_index(path_index) <= index & merge_step_dependend_path_index(path_index);
        layer_independend_twiddle_addr(path_index) <= full_index(path_index) when merge_step = merge_zero else std_logic_vector((unsigned(full_index(path_index)) ROL 1) ROR to_integer(unsigned(merge_step)));
        twiddle_addr(path_index) <= (layer_independend_twiddle_addr(path_index) and twiddle_mask(N-2 downto 0));
    end generate gen_twiddle_addr;
    twiddle_mask <= std_logic_vector(shift_right(signed(constant_mask), to_integer(unsigned(layer))));

end management_unit_b;
    