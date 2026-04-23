library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.int_alu_pkg.all;

entity int_alu is
	port (
		piv_int_alu_oper  : in std_logic_vector(3 downto 0);
		piv_int_alu_op1   : in std_logic_vector(31 downto 0);
		piv_int_alu_op2   : in std_logic_vector(31 downto 0);
		pol_int_alu_busy  : out std_logic;
		potr_int_alu_flag : out tr_SF_CPU;
		pov_int_alu_res   : out std_logic_vector(31 downto 0)
	);
end entity;

architecture rtl of int_alu is

	signal su_result : unsigned(32 downto 0);

begin

	proc_comb_alu_ops : process (piv_int_alu_oper, piv_int_alu_op1, piv_int_alu_op2)
	begin
		case piv_int_alu_oper is
			when cv_ALU_ADD =>
				su_result <= unsigned(piv_int_alu_op1(31) & piv_int_alu_op1) + unsigned(piv_int_alu_op2(31) & piv_int_alu_op2);
			when cv_ALU_SUB | cv_ALU_SLT =>
				su_result <= unsigned(piv_int_alu_op1(31) & piv_int_alu_op1) - unsigned(piv_int_alu_op2(31) & piv_int_alu_op2);
			when cv_ALU_XOR =>
				su_result(31 downto 0) <= unsigned(piv_int_alu_op1 xor piv_int_alu_op2);
				su_result(32)          <= '0';
			when cv_ALU_OR =>
				su_result(31 downto 0) <= unsigned(piv_int_alu_op1 or piv_int_alu_op2);
				su_result(32)          <= '0';
			when cv_ALU_AND =>
				su_result(31 downto 0) <= unsigned(piv_int_alu_op1 and piv_int_alu_op2);
				su_result(32)          <= '0';
			when cv_ALU_SLL =>
				su_result(31 downto 0) <= shift_left(unsigned(piv_int_alu_op1), to_integer(unsigned(piv_int_alu_op2(4 downto 0))));
				su_result(32)          <= '0';
			when cv_ALU_SRL =>
				su_result(31 downto 0) <= shift_right(unsigned(piv_int_alu_op1), to_integer(unsigned(piv_int_alu_op2(4 downto 0))));
				su_result(32)          <= '0';
			when cv_ALU_SRA =>
				su_result(31 downto 0) <= shift_right(unsigned(piv_int_alu_op1), to_integer(unsigned(piv_int_alu_op2(4 downto 0))));
				for ii in 31 downto 0 loop
					if ii >= 32 - to_integer(unsigned(piv_int_alu_op2(4 downto 0))) then
						su_result(ii) <= piv_int_alu_op1(31);
					end if;
				end loop;
				su_result(32) <= '0';
			when cv_ALU_SLTU =>
				su_result <= unsigned('0' & piv_int_alu_op1) - unsigned('0' & piv_int_alu_op2);
			when cv_ALU_temp2_pass =>
				su_result(31 downto 0) <= unsigned(piv_int_alu_op2);
				su_result(32)          <= '0';
			when others          =>
				su_result <= (others => '1');
		end case;
	end process proc_comb_alu_ops;

	potr_int_alu_flag.int_alu_CF <= su_result(32);
	potr_int_alu_flag.int_alu_ZF <= '1' when su_result(31 downto 0) = X"00000000" else '0';
	potr_int_alu_flag.int_alu_VF <= (not piv_int_alu_op1(31) and piv_int_alu_op2(31) and su_result(31)) or (piv_int_alu_op1(31) and not piv_int_alu_op2(31) and not su_result(31)) when piv_int_alu_oper = cv_ALU_SUB or piv_int_alu_oper = cv_ALU_SLT else
	(not piv_int_alu_op1(31) and not piv_int_alu_op2(31) and su_result(31)) or (piv_int_alu_op1(31) and piv_int_alu_op2(31) and not su_result(31));
	potr_int_alu_flag.int_alu_NF <= su_result(31);

	pov_int_alu_res <= (0 => ((not piv_int_alu_op1(31) and piv_int_alu_op2(31) and su_result(31)) or (piv_int_alu_op1(31) and not piv_int_alu_op2(31) and not su_result(31))) xor su_result(31), others => '0') when piv_int_alu_oper = cv_ALU_SLT else
		(0 => su_result(32), others => '0') when piv_int_alu_oper = cv_ALU_SLTU else
		std_logic_vector(su_result(31 downto 0));

	pol_int_alu_busy <= '0';

end architecture;