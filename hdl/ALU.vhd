library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--! | ALU_OP | C_out         | Note                                                    |
--! | 0b000  | A_in + B_in   | Addtion                                                 |
--! | 0b001  | A_in << B_in  | Shift Left Logical                                      |
--! | 0b010  | A_in < B_in   | "1" if A_in is less than B_in, otherwise "0" (signed)   |
--! | 0b011  | A_in < B_in   | "1" if A_in is less than B_in, otherwise "0" (unsigned) |
--! | 0b100  | A_in XOR B_in | Exclusive OR                                            |
--! | 0b101  | A_in >> B_in  | Shift Right Logical                                     |
--! | 0b110  | A_in OR B_in  | OR                                                      |
--! | 0b111  | A_in AND B_in | AND                                                     |
entity ALU is
  generic (
    BIT_SIZE : natural := 32
    );
  port (
    ALU_OP : in  std_logic_vector(2 downto 0);
    A_in   : in  std_logic_vector(BIT_SIZE-1 downto 0);
    B_in   : in  std_logic_vector(BIT_SIZE-1 downto 0);
    C_out  : out std_logic_vector(BIT_SIZE-1 downto 0)
    );
end entity ALU;


architecture rtl of ALU is

  pure function bool_to_sl(cond : boolean)
    return std_logic is
  begin
    if cond then
      return '1';
    else
      return '0';
    end if;
  end function bool_to_sl;
begin

  alu_comb : process(all)
  begin
    case ALU_OP is
      when "000" =>                     -- Addition Operation
        C_out <= std_logic_vector(unsigned(A_in) + unsigned(B_in));

      when "001" =>                     -- Shift Left Logical Operation
        C_out <= A_in sll TO_INTEGER(unsigned(B_in));

      when "010" =>                     -- Set Less Than Operation (Signed)
        C_out <= (BIT_SIZE-1 downto 1 => '0') & bool_to_sl(signed(A_in) < signed(B_in));

      when "011" =>                     -- Set Less Than Operation (Unsigned)
        C_out <= (BIT_SIZE-1 downto 1 => '0') & bool_to_sl(unsigned(A_in) < unsigned(B_in));

      when "100" =>                     -- Exclusive OR Operation
        C_out <= A_in xor B_in;

      when "101" =>                     -- Shift Right Logical Operation
        C_out <= A_in srl to_integer(unsigned(B_in));

      when "110" =>                     -- OR Operation
        C_out <= A_in or B_in;

      when "111" =>                     -- AND Operation
        C_out <= A_in and B_in;

      when others =>
    end case;
  end process alu_comb;

end architecture rtl;
