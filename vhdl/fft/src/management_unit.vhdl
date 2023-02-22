library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity management_unit is
    generic(
            N: integer;
            layer_l: integer);
    port(fft_start, clk: in std_logic;
         twiddle_addr: out std_logic_vector(N-2 downto 0);
         bank0_addr_A, bank0_addr_B, bank1_addr_A, bank1_addr_B: out std_logic_vector(N-1 downto 0);
         generate_output, write_A_enable, write_B_enable: out std_logic;
         get_input: out std_logic;
         select_bank_out: out std_logic);
end management_unit;

architecture management_unit_b of management_unit is
    component counter
        generic (count_width : integer; max : integer);
        port(enable, clk : in std_logic;
             clr : in std_logic;
             value : out std_logic_vector(count_width-1 downto 0);
             resets : out std_logic);
    end component;

    signal is_doing_io, is_getting_input : std_logic:= '0';
    signal io_is_in: std_logic := '1';
    signal layer_incr, layer_incr_buff : std_logic:='0';
    signal fft_finished, fft_calc_finished: std_logic:='1';
    signal fft_start_impulse: std_logic := '0';
    signal index_resets, fft_running, index_clr: std_logic := '0';
    
    signal select_bank: std_logic := '0';
    signal calc_write_enable: std_logic;

    signal rev_index, index, index_buff: std_logic_vector(N-2 downto 0);
    signal layer: std_logic_vector(layer_l-1 downto 0):= (others => '0');

    signal addr_A_read, addr_B_read, addr_A_write, addr_B_write: std_logic_vector(N-1 downto 0):= (others => '0');

    signal twiddle_mask: std_logic_vector(N-1 downto 0) := (others => '0');
    signal tmp_mask, constant_mask: std_logic_vector(N-1 downto 0) := ('1', others => '0');
begin
    Index_cnt: counter
        generic map (
            count_width => N-1,
            max => 2**(N-1)-1
        )
        port map(
            enable => fft_running,
            clr => index_clr,
            clk => clk,
            value => index_buff,
            resets => index_resets
        );
    LayerNr: counter
        generic map (
            count_width => layer_l,
            max => n-1
        )
        port map(
            enable => layer_incr,
            clr => fft_calc_finished,
            clk => clk,
            value => layer,
            resets => fft_calc_finished
        );


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
            if(fft_start_impulse = '1') then
                fft_finished <= '0';
            elsif(index_resets = '1' and io_is_in = '0') then
                fft_finished <= '0';
            end if;
        end if;
    end process;

    index_clr <= index_resets or fft_finished;
    generate_output <= is_doing_io and not io_is_in;


    process(clk)
    begin
        if(rising_edge(clk)) then
            if(index_resets = '1') then
                select_bank <= not select_bank;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if(rising_edge(clk)) then
            if(index_resets = '1' and is_doing_io = '1') then
                io_is_in <= not io_is_in;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if(rising_edge(clk)) then
            if (index_resets = '1') then
                is_doing_io <= '0';
            elsif (fft_start_impulse = '1' or fft_calc_finished = '1') then
                is_doing_io <= '1';
            end if;
        end if;
    end process;

    process(clk)
    begin
        if(rising_edge(clk)) then
            layer_incr <= index_resets and layer_incr_buff;
        end if;
    end process;
    process(clk)
    begin
        if(rising_edge(clk)) then
            layer_incr_buff <= not is_getting_input;
        end if;
    end process;
    process(clk)
    begin
        if(rising_edge(clk)) then
            select_bank_out <= select_bank;
            index <= index_buff;
            addr_A_write <= addr_A_read;
            addr_B_write <= addr_B_read;
        end if;
    end process;
--    process(clk)
--    begin
--        if(rising_edge(clk)) then
--            if(fft_start_impulse = '1' or fft_calc_finished = '1') then
--                is_doing_io <= '1';
--            elsif(index_resets = '1') then
--                is_doing_io <= '0';
--            end if;
--        end if;
--    end process;
    gen_rev_index: for i in 0 to N-2 generate
        rev_index(i) <= index(N-2-i);
    end generate gen_rev_index;
    addr_A_read <= std_logic_vector(unsigned(index & '0') ROL to_integer(unsigned(layer))) when is_getting_input = '0' else '0' & rev_index;
    addr_B_read <= std_logic_vector(unsigned(index & '1') ROL to_integer(unsigned(layer))) when is_getting_input = '0' else '1' & rev_index;
    bank0_addr_A <= addr_A_read when select_bank = '1' else addr_A_write;
    bank0_addr_B <= addr_B_read when select_bank = '1' else addr_B_write;
    bank1_addr_A <= addr_A_read when select_bank = '0' else addr_A_write;
    bank1_addr_B <= addr_B_read when select_bank = '0' else addr_B_write;
    get_input <= is_getting_input;
    is_getting_input <= is_doing_io and io_is_in;

    process(clk)
    begin
        if(rising_edge(clk)) then
            calc_write_enable <= (not index_resets);
            if(is_doing_io = '0') then
                write_A_enable <= calc_write_enable and not fft_calc_finished;
                write_B_enable <= calc_write_enable and not fft_calc_finished;
            else
                write_A_enable <= io_is_in;
                write_B_enable <= io_is_in;
            end if;
        end if;
    end process;

    twiddle_addr <= index and twiddle_mask(N-2 downto 0);
    twiddle_mask <= std_logic_vector(shift_right(signed(constant_mask), to_integer(unsigned(layer))));

end management_unit_b;
    