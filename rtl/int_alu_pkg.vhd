library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package int_alu_pkg is

    -----------------------------------------------------------------------------------------------------
	-----------------------------------------ALU OPERATIONS----------------------------------------------
	-----------------------------------------------------------------------------------------------------

    --- Arithmetic Operations ---
	constant cv_ALU_ADD : std_logic_vector(3 downto 0) := "0000";
	constant cv_ALU_SUB : std_logic_vector(3 downto 0) := "1000";

	--- Logical Operations ---
	constant cv_ALU_XOR : std_logic_vector(3 downto 0) := "0100";
	constant cv_ALU_OR  : std_logic_vector(3 downto 0) := "0110";
	constant cv_ALU_AND : std_logic_vector(3 downto 0) := "0111";

	--- Logical Operations ---
	constant cv_ALU_SLL : std_logic_vector(3 downto 0) := "0001";
	constant cv_ALU_SRL : std_logic_vector(3 downto 0) := "0101";
	constant cv_ALU_SRA : std_logic_vector(3 downto 0) := "1101";

	--- Set less than (S/U) ---
	constant cv_ALU_SLT  : std_logic_vector(3 downto 0) := "0010";
	constant cv_ALU_SLTU : std_logic_vector(3 downto 0) := "0011";

	constant cv_ALU_temp2_pass : std_logic_vector(3 downto 0) := "1111";

end package int_alu_pkg;