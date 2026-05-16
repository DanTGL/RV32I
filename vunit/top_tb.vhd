library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.RandomPkg.RandomPType;

entity top_tb is

  generic (runner_cfg : string);

end entity top_tb;

architecture rtl of top_tb is

  signal OP        : std_logic_vector(2 downto 0);
  signal A, B, C   : std_logic_vector(31 downto 0);
  signal test_done : std_logic;
  signal clk       : std_logic := '0';
  signal reset_n   : std_logic := '0';
  component CPU
    port (
      clk         : in  std_logic;
      reset_n     : in  std_logic;
      i_code      : in  std_logic_vector(31 downto 0);
      o_caddr     : out std_logic_vector(31 downto 0);
      o_data_cs_n : out std_logic;
      o_data_we_n : out std_logic;
      i_data      : in  std_logic_vector(31 downto 0);
      o_data      : out std_logic_vector(31 downto 0);
      o_daddr     : out std_logic_vector(31 downto 0)
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
      reset_n     => reset_n,
      i_code      => "000000000001" & "00001" & "000" & "00001" & "0010011",
      o_caddr     => open,
      o_data_cs_n => open,
      o_data_we_n => open,
      i_data      => (others => '0'),
      o_data      => open,
      o_daddr     => open
      );

  main : process
    variable rnd : RandomPType;
  begin
    test_runner_setup(runner, runner_cfg);
    rnd.InitSeed(rnd'instance_name);

    reset_n <= '0';
    wait for 100 ns;
    reset_n <= '1';
    wait until rising_edge(clk);

    while test_suite loop
      if run("test_add") then
        OP <= "001";
        A  <= rnd.RandSlv(32);
        B  <= rnd.RandSlv(32);

        check_equal(to_integer_string(C), to_integer_string(std_logic_vector(unsigned(A)+unsigned(B))), "A=" & to_integer_string(A) & "B=" & to_integer_string(B));

      elsif run("test_cpu") then -- TODO
        for i in 0 to 500 loop
          --report to_string(i) & to_string(<<signal CPU_inst.reg1 : std_logic_vector(31 downto 0)>>);
          wait until rising_edge(clk);

        end loop;

      end if;

    end loop;
    test_runner_cleanup(runner);
  end process;

  clk <= not clk after 10 ns;

end architecture rtl;
