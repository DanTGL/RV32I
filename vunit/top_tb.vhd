library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.RandomPkg.RandomPType;

entity top_tb is

  generic (runner_cfg : string);

end entity top_tb;

architecture rtl of top_tb is

  constant MEM_CELL_WIDTH : natural := 32;
  constant MEMORY_SIZE : natural := 16#10000#;

  type mem_t is array (0 to MEMORY_SIZE-1) of std_logic_vector(MEM_CELL_WIDTH-1 downto 0);

  impure function init_mem(mem_file_name: in string) return mem_t is
    file mem_file : text open read_mode is mem_file_name;
    variable file_line : line;
    variable mem : mem_t;
  begin
    for i in 0 to MEMORY_SIZE-1 loop
      readline(mem_file, file_line);
      hread(file_line, mem(i));
    end loop;

    return mem;
  end function;

  constant new_mem : mem_t := init_mem("tests/test.hex");

  signal OP        : std_logic_vector(2 downto 0);
  signal A, B, C   : std_logic_vector(31 downto 0);
  signal test_done : std_logic;
  signal clk       : std_logic := '0';
  signal reset_n   : std_logic := '0';
  signal code : std_logic_vector(31 downto 0);
  signal caddr : std_logic_vector(31 downto 0);
  signal daddr : std_logic_vector(31 downto 0);
  signal data_read : std_logic_vector(31 downto 0);
  signal data_write: std_logic_vector(31 downto 0);
  signal data_cs_n, data_we_n : std_logic;
  signal data_cnt : std_logic_vector(2 downto 0);
  signal data_width : integer;
  signal trap : std_logic;

  signal reset_n_t1, reset_n_t2 : std_logic;

  component CPU
    port (
      clk         : in  std_logic;
      reset_n     : in  std_logic;
      i_code      : in  std_logic_vector(31 downto 0);
      o_caddr     : out std_logic_vector(31 downto 0);
      o_data_cs_n : out std_logic;
      o_data_we_n : out std_logic;
      o_data_cnt  : out std_logic_vector(2 downto 0);
      i_data      : in  std_logic_vector(31 downto 0);
      o_data      : out std_logic_vector(31 downto 0);
      o_daddr     : out std_logic_vector(31 downto 0);
      o_trap      : out std_logic
      );
  end component CPU;

  component ALU
    generic (
      BIT_SIZE : natural := 32
      );
    port (
      ALU_OP : in  std_logic_vector(2 downto 0);
      ALU_SW : in  std_logic;
      IMM_OP : in  std_logic;
      A_in   : in  std_logic_vector(BIT_SIZE-1 downto 0);
      B_in   : in  std_logic_vector(BIT_SIZE-1 downto 0);
      C_out  : out std_logic_vector(BIT_SIZE-1 downto 0)
      );
  end component ALU;

begin

  ALU_inst : ALU
    generic map(
      BIT_SIZE => 32
      )
    port map(
      ALU_OP => OP,
      ALU_SW => '0',
      IMM_OP => '0',
      A_in   => A,
      B_in   => B,
      C_out  => C
      );

  CPU_inst : CPU
    port map(
      clk         => clk,
      reset_n     => reset_n_t2,
      i_code      => code,
      o_caddr     => caddr,
      o_data_cs_n => data_cs_n,
      o_data_we_n => data_we_n,
      o_data_cnt  => data_cnt,
      i_data      => data_read,
      o_data      => data_write,
      o_daddr     => daddr,
      o_trap      => trap
      );

  reset_process: process(clk, reset_n)
  begin
    if reset_n = '0' then
      reset_n_t1 <= '0';
      reset_n_t2 <= '0';
    elsif rising_edge(clk) then
      reset_n_t1 <= '1';
      reset_n_t2 <= reset_n_t1;
    end if;
  end process;

  process(clk, reset_n)
  variable mem : mem_t;
  variable l : line;
  variable word_idx_upper : natural range 0 to 31;
  variable word_idx_lower : natural range 0 to 31;
  variable bit_count : natural;
  begin
    if reset_n = '0' then

      mem := new_mem;
    elsif falling_edge(clk) then

      code <= mem(to_integer(unsigned(caddr)/4));

      with data_cnt(1 downto 0) select bit_count := 8 when "00", 16 when "01", 32 when "10", 0 when others;
      word_idx_lower := to_integer(unsigned(daddr(1 downto 0))) * 8;
      word_idx_upper := word_idx_lower + (bit_count - 1);
      if data_cs_n = '0' then
        if data_we_n = '1' then
          if bit_count >= 32 then
            data_read <= mem(to_integer(unsigned(daddr)/4));
          else
            data_read <= (31 downto bit_count => '0') & mem(to_integer(unsigned(daddr)/4))(word_idx_upper downto word_idx_lower);
          end if;
        elsif data_we_n = '0' then
          if unsigned(daddr) = x"10000000" then
            if character'val(to_integer(unsigned(data_write(7 downto 0)))) = LF then
              writeline(output, l);
            else
              write(l, character'val(to_integer(unsigned(data_write(7 downto 0)))));
            end if;
          else
            mem(to_integer(unsigned(daddr)/4))(word_idx_upper downto word_idx_lower) := data_write(bit_count-1 downto 0);
          end if;
        end if;
      end if;
    end if;

  end process;

  main : process
    variable rnd : RandomPType;
  begin
    test_runner_setup(runner, runner_cfg);
    rnd.InitSeed(rnd'instance_name);

    wait for 5 ns;

    while test_suite loop
      if run("test_add") then
        OP <= "001";
        A  <= rnd.RandSlv(32);
        B  <= rnd.RandSlv(32);

        check_equal(to_integer_string(C), to_integer_string(std_logic_vector(unsigned(A)+unsigned(B))), "A=" & to_integer_string(A) & "B=" & to_integer_string(B));

      elsif run("test_cpu") then -- TODO
        while trap /= '1' loop
          wait until rising_edge(clk);
        end loop;

      end if;

    end loop;
    test_runner_cleanup(runner);
  end process;

  clk <= not clk after 10 ns;
  reset_n <= '1' after 100 ns;

  test_runner_watchdog(runner, 5 sec, do_runner_cleanup => false);

end architecture rtl;
