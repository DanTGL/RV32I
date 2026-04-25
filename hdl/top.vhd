library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top is
  port (
    CLK     : in std_logic;
    RESET_n : in std_logic
    );
end entity top;

architecture rtl of top is
  signal reset_n_t1, reset_n_t2 : std_logic;
begin

  reset_process : process(CLK, RESET_N)
  begin
    if RESET_n = '0' then
      reset_n_t1 <= '0';
      reset_n_t2 <= '0';
    elsif rising_edge(CLK) then
      reset_n_t1 <= '1';
      reset_n_t2 <= reset_n_t1;
    end if;
  end process reset_process;

end architecture rtl;
