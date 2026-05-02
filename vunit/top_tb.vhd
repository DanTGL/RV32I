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

  component ALU
    generic (
      BIT_SIZE : natural := 32
      );
    port (
      ALU_OP : in  std_logic_vector(2 downto 0);
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
      A_in   => A,
      B_in   => B,
      C_out  => C
      );


  main : process
    variable rnd : RandomPType;
  begin
    test_runner_setup(runner, runner_cfg);
    rnd.InitSeed(rnd'instance_name);

    while test_suite loop
      if run("test_add") then
        OP <= "001";
        A  <= rnd.RandSlv(32);
        B  <= rnd.RandSlv(32);

        check_equal(to_integer_string(C), to_integer_string(std_logic_vector(unsigned(A)+unsigned(B))), "A=" & to_integer_string(A) & "B=" & to_integer_string(B));

      elsif run("test_fail") then
        assert false report "It fails";

      end if;

    end loop;
    test_runner_cleanup(runner);
  end process;

end architecture rtl;
