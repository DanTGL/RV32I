library vunit_lib;
context vunit_lib.vunit_context;

entity top_tb is

  generic (runner_cfg : string);

end entity top_tb;

architecture rtl of top_tb is

begin

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_pass") then
        report "This will pass";

      elsif run("test_fail") then
        assert false report "It fails";

      end if;

    end loop;
    test_runner_cleanup(runner);
  end process;

end architecture rtl;
