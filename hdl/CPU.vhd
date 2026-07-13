library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CPU is
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
end entity CPU;

architecture rtl of CPU is

  pure function bool_to_sl(cond : boolean)
    return std_logic is
  begin
    if cond then
      return '1';
    else
      return '0';
    end if;
  end function bool_to_sl;

  signal ALU_OP : std_logic_vector(2 downto 0);
  signal ALU_IMM_OP : std_logic;
  signal ALU_A  : std_logic_vector(31 downto 0);
  signal ALU_B  : std_logic_vector(31 downto 0);
  signal ALU_C  : std_logic_vector(31 downto 0);

  signal PC : unsigned(31 downto 0);

  signal inst : std_logic_vector(31 downto 0);

  type REGISTERS_t is array (0 to 31) of std_logic_vector(31 downto 0);

  type CPU_STATE is (
    STATE_FETCH,
    STATE_DECODE,
    STATE_EXECUTE,
    STATE_MEM,
    STATE_REG_WB
    );

  signal state : CPU_STATE;
  type INSTRUCTION_FORMAT is (INST_FORMAT_I, INST_FORMAT_J, INST_FORMAT_S, INST_FORMAT_U, INST_FORMAT_B, INST_FORMAT_R, INST_FORMAT_INVALID);

  type INSTRUCTION_TYPE is (
    INST_TYPE_LOAD, INST_TYPE_OP_IMM, INST_TYPE_AUIPC, -- INST_TYPE_OP_IMM_32,
    INST_TYPE_STORE, INST_TYPE_OP, INST_TYPE_LUI, -- INST_TYPE_OP_32,
    INST_TYPE_BRANCH, INST_TYPE_JALR, INST_TYPE_JAL, INST_TYPE_SYSTEM,
    INST_TYPE_MISC_MEM, INST_TYPE_UNIMPL
  );

  signal regs : REGISTERS_t;

  type INSTRUCTION is record
    instr_type : INSTRUCTION_TYPE;
    instr_format : INSTRUCTION_FORMAT;
    rs1        : std_logic_vector(4 downto 0);
    rs2        : std_logic_vector(4 downto 0);
    rd         : std_logic_vector(4 downto 0);
    imm        : std_logic_vector(31 downto 0);
    branch_cond: std_logic;
  end record INSTRUCTION;

  signal cur_instr : INSTRUCTION;
  signal reg_a1 : std_logic_vector(31 downto 0); -- Purely here for debug purposes

begin

  reg_a1 <= regs(11);

  ALU_IMM_OP <= '1' when cur_instr.instr_format = INST_FORMAT_I else '0';

  ALU_A <= regs(to_integer(unsigned(cur_instr.rs1)));
  ALU_B <= regs(to_integer(unsigned(cur_instr.rs2))) when cur_instr.instr_format = INST_FORMAT_R else cur_instr.imm;
  ALU_OP <= inst(14 downto 12);

  ALU_inst : entity work.ALU
    generic map(
      BIT_SIZE => 32
      )
    port map(
      ALU_OP => ALU_OP,
      ALU_SW => inst(30), -- 5th bit of funct7 field
      IMM_OP => ALU_IMM_OP,
      A_in   => ALU_A,
      B_in   => ALU_B,
      C_out  => ALU_C
      );

  -- TODO: Improve this
  -- NOTE: Design was chosen as it should be simpler to parallelize later on
  pipeline_process : process(clk, reset_n)
  begin
    if reset_n = '0' then
      state       <= STATE_FETCH;
      PC          <= (others => '0');
      o_caddr     <= (others => '0');
      o_data_we_n <= '1';
      o_data_cs_n <= '1';
      inst <= (others => '0');
      regs <= (others => (others => '0'));

    elsif rising_edge(clk) then
      o_data_we_n <= '1';
      o_data_cs_n <= '1';
      PC          <= PC;
      inst        <= inst;

      case state is
        when STATE_FETCH =>
          o_caddr <= std_logic_vector(PC);
          state   <= STATE_DECODE;

        when STATE_DECODE =>
          inst  <= i_code;
          state <= STATE_EXECUTE;

        when STATE_EXECUTE =>
          state  <= STATE_MEM;

        when STATE_MEM =>

          state <= STATE_REG_WB;

        when STATE_REG_WB => -- Register Write Back
          PC <= PC + 4;
          if cur_instr.instr_type = INST_TYPE_BRANCH and cur_instr.branch_cond = '1' then
            PC <= PC + unsigned(cur_instr.imm);
          end if;

          if cur_instr.rd = "00000" then -- Writes to register 0 are ignored
            regs(0) <= (others => '0');
          else
            regs(to_integer(unsigned(cur_instr.rd))) <= ALU_C;
          end if;
          state <= STATE_FETCH;

      end case;
    end if;
  end process pipeline_process;

  with inst(6 downto 2) select
    cur_instr.instr_type <= INST_TYPE_LOAD  when  "00000",
                            INST_TYPE_MISC_MEM when "00011",
                            INST_TYPE_OP_IMM when "00100",
                            INST_TYPE_AUIPC when  "00101",
                            --INST_TYPE_OP_IMM_32 when "00110",
                            INST_TYPE_STORE when "01000",
                            INST_TYPE_OP when "01100",
                            INST_TYPE_LUI when "01101",
                            --INST_TYPE_OP_32 when "01110",
                            INST_TYPE_BRANCH when "11000",
                            INST_TYPE_JALR when "11001",
                            INST_TYPE_JAL when "11011",
                            INST_TYPE_SYSTEM when "11100",
                            INST_TYPE_UNIMPL when others;

  with cur_instr.instr_type select
    cur_instr.instr_format <= INST_FORMAT_I when INST_TYPE_LOAD | INST_TYPE_OP_IMM | INST_TYPE_JALR | INST_TYPE_SYSTEM | INST_TYPE_MISC_MEM,
                              INST_FORMAT_R when INST_TYPE_OP,
                              INST_FORMAT_S when INST_TYPE_STORE,
                              INST_FORMAT_B when INST_TYPE_BRANCH,
                              INST_FORMAT_U when INST_TYPE_LUI | INST_TYPE_AUIPC,
                              INST_FORMAT_J when INST_TYPE_JAL,
                              INST_FORMAT_INVALID when INST_TYPE_UNIMPL;

  with cur_instr.instr_format select
    cur_instr.rd <= inst(11 downto 7) when INST_FORMAT_R | INST_FORMAT_I | INST_FORMAT_U | INST_FORMAT_J,
                    (others => '0') when others;

  with cur_instr.instr_format select
    cur_instr.rs1 <= inst(19 downto 15) when INST_FORMAT_R | INST_FORMAT_I | INST_FORMAT_S | INST_FORMAT_B,
                    (others => '0') when others;

  with cur_instr.instr_format select
    cur_instr.rs2 <= inst(24 downto 20) when INST_FORMAT_R | INST_FORMAT_S | INST_FORMAT_B,
                    (others => '0') when others;

  immediate: process(all)
  begin
    cur_instr.imm <= (others => '0');

    case cur_instr.instr_format is
      when INST_FORMAT_I =>
        cur_instr.imm <= (31 downto 11 => inst(31), 10 downto 0 => inst(30 downto 20));

      when INST_FORMAT_S =>
        cur_instr.imm <= (31 downto 11 => inst(31), 10 downto 5 => inst(30 downto 25), 4 downto 0 => inst(11 downto 7));

      when INST_FORMAT_B =>
        cur_instr.imm <= (31 downto 12 => inst(31), 11 => inst(7), 10 downto 5 => inst(30 downto 25), 4 downto 1 => inst(11 downto 8), 0 => '0');

      when INST_FORMAT_J =>
        cur_instr.imm <= (31 downto 20 => inst(31), 19 downto 12 => inst(19 downto 12), 11 => inst(20), 10 downto 1 => inst(30 downto 21), 0 => '0');

      when INST_FORMAT_U =>
        cur_instr.imm <= (31 downto 12 => inst(31 downto 12), others => '0');

      when others =>
        cur_instr.imm <= (others => '0');
    end case;
  end process immediate;


  branch_cond: process(all)
  begin
    case ALU_OP is
      when "000" => -- BEQ: Branch if Equal
        cur_instr.branch_cond <= bool_to_sl(regs(to_integer(unsigned(cur_instr.rs1))) = regs(to_integer(unsigned(cur_instr.rs2))));

      when "001" => -- BNE: Branch if Not Equal
        cur_instr.branch_cond <= bool_to_sl(regs(to_integer(unsigned(cur_instr.rs1))) /= regs(to_integer(unsigned(cur_instr.rs2))));

      when "100" => -- BLT: Branch if Less Than (signed)
        cur_instr.branch_cond <= bool_to_sl(signed(regs(to_integer(unsigned(cur_instr.rs1)))) < signed(regs(to_integer(unsigned(cur_instr.rs2)))));

      when "101" => -- BEQ: Branch if Greater than or Equal (signed)
        cur_instr.branch_cond <= bool_to_sl(signed(regs(to_integer(unsigned(cur_instr.rs1)))) >= signed(regs(to_integer(unsigned(cur_instr.rs2)))));

      when "110" => -- BLTU: Branch if Less Than (Unsigned)
        cur_instr.branch_cond <= bool_to_sl(unsigned(regs(to_integer(unsigned(cur_instr.rs1)))) < unsigned(regs(to_integer(unsigned(cur_instr.rs2)))));

      when "111" => -- BGEU: Branch if Greater than or Equal (Unsigned)
        cur_instr.branch_cond <= bool_to_sl(unsigned(regs(to_integer(unsigned(cur_instr.rs1)))) >= unsigned(regs(to_integer(unsigned(cur_instr.rs2)))));

      when others =>
        cur_instr.branch_cond <= '0';

    end case;

  end process branch_cond;
end architecture rtl;
