library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity management_unit is
    generic(
            N: integer;
            layer_l: integer);
    port(fft_start, clk: in std_logic;
         twiddle_addr: out std_logic_vector(N-2 downto 0);
         addr_A_read, addr_B_read, addr_A_write, addr_B_write: out std_logic_vector(N-1 downto 0);
         generate_output, write_A_enable, write_B_enable: out std_logic;
         get_input: out std_logic);
end management_unit;

architecture management_unit_b of management_unit is
    component counter
        generic (count_width : integer; max : integer);
        port(clk : in std_logic;
             clr : in std_logic;
             value : out std_logic_vector(count_width-1 downto 0);
             resets : out std_logic);
    end component;

    signal is_getting_input : std_logic:= '1';
    signal layer_incr, layer_incr_buff : std_logic:='0';
    signal fft_finished: std_logic:='1'; -- internal impulse to end calculation 
    signal index_resets, fft_running, active_clk: std_logic := '0';
    signal index: std_logic_vector(N-2 downto 0);
    signal twiddle_mask: std_logic_vector(N-1 downto 0) := (others => '0');
    signal layer: std_logic_vector(layer_l-1 downto 0):= (others => '0');
    signal tmp_mask, constant_mask: std_logic_vector(N-1 downto 0) := ('1', others => '0');
begin
    Index_cnt: counter
        generic map (
            count_width => N-1,
            max => 2**(N-1)-1
        )
        port map(
            clr => fft_finished,
            clk => active_clk,
            value => index,
            resets => index_resets
        );
    LayerNr: counter
        generic map (
            count_width => layer_l,
            max => n-1
        )
        port map(
            clr => fft_finished,
            clk => layer_incr,
            value => layer,
            resets => fft_finished
        );
    process(fft_start, fft_finished) 
    begin
        if(fft_start = '1') then
            fft_running <= '1';
        elsif(fft_finished = '1') then
            fft_running <= '0';
        end if;
    end process;
    fft_done <= not fft_running;
    active_clk <= fft_running and clk;
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
    process(fft_finished, index_resets)
    begin
        if(fft_finished = '1') then
            is_getting_input <= '1';
        elsif(index_resets = '1') then
            is_getting_input <= '0';
        end if;
    end process;
    addr_A_read <= std_logic_vector(unsigned(index & '0') ROL to_integer(unsigned(layer)));
    addr_B_read <= std_logic_vector(unsigned(index & '1') ROL to_integer(unsigned(layer)));
    addr_A_write <= std_logic_vector(unsigned(index & '0') ROL to_integer(unsigned(layer)));
    addr_B_write <= std_logic_vector(unsigned(index & '1') ROL to_integer(unsigned(layer)));
    get_input <= is_getting_input;
    write_A_enable <= fft_running;
    write_b_enable <= fft_running;
    twiddle_addr <= index and twiddle_mask(N-2 downto 0);
    twiddle_mask <= std_logic_vector(shift_right(signed(constant_mask), to_integer(unsigned(layer))));

end management_unit_b;
    