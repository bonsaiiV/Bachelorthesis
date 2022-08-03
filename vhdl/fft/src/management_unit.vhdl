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
         fft_done, write_A_enable, write_B_enable: out std_logic;
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

    signal fft_finished: std_logic;
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
            clk => index_resets,
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
    addr_A_read <= std_logic_vector(unsigned(index & '0') ROL to_integer(unsigned(layer)));
    addr_B_read <= std_logic_vector(unsigned(index & '1') ROL to_integer(unsigned(layer)));
    addr_A_write <= std_logic_vector(unsigned(index & '0') ROL to_integer(unsigned(layer)));
    addr_B_write <= std_logic_vector(unsigned(index & '1') ROL to_integer(unsigned(layer)));
    get_input <= '1' when unsigned(layer) = 0 else '0';
    write_A_enable <= not fft_running;
    write_b_enable <= not fft_running;
    twiddle_addr <= index and twiddle_mask(N-2 downto 0);
    twiddle_mask <= std_logic_vector(shift_right(signed(constant_mask), to_integer(unsigned(layer))));

end management_unit_b;
    