library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top is
  port (
    clk     : in std_logic;
    reset_n : in std_logic
    );
end entity top;

architecture rtl of top is
  signal reset_n_t1, reset_n_t2 : std_logic;
begin

  CPU_inst : entity work.CPU
    port map(
      clk         => clk,
      reset_n     => reset_n_t2,
      i_code      => (others => '0'),
      o_caddr     => open,
      o_wb_cyc    => open,
      o_wb_we     => open,
      o_wb_stb    => open,
      o_wb_sel    => open,
      i_wb_ack    => '0',
      i_data      => (others => '0'),
      o_data      => open,
      o_daddr     => open,
      o_trap      => open
      );

  reset_process : process(clk, reset_n)
  begin
    if reset_n = '0' then
      reset_n_t1 <= '0';
      reset_n_t2 <= '0';
    elsif rising_edge(clk) then
      reset_n_t1 <= '1';
      reset_n_t2 <= reset_n_t1;
    end if;
  end process reset_process;

end architecture rtl;
