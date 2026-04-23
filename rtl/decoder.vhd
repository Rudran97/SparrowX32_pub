library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.int_alu_pkg.all;
use work.core_pkg.all;

entity decoder is
	generic (
		gb_EXT_M          : boolean := true
	);
	port (
		pitr_dec_inst     : in tr_IF_base_format;
		pov_dec_intalu_op : out std_logic_vector(3 downto 0);
		pov_dec_md_op     : out std_logic_vector(2 downto 0);
		pov_dec_csr_op    : out std_logic_vector(2 downto 0);
		pol_illegal_inst  : out std_logic;
		potr_dec_cpu_ctrl : out tr_CS_CPU
	);
end entity;

architecture rtl of decoder is

	function fl_check_rv32i(
		instruction : tr_IF_base_format
	) return std_logic is
		variable vl_illegal_inst : std_logic;
	begin
		vl_illegal_inst := cl_DISABLE;
		case instruction.v_opcode is
			when cv_IC_R =>
				case instruction.v_funct3 & instruction.v_funct7 is
					when "000" & "0000000" =>
						--- add ---
					when "000" & "0100000" =>
						--- sub ---
					when "100" & "0000000" =>
						--- xor ---
					when "110" & "0000000" =>
						--- or ---
					when "111" & "0000000" =>
						--- and ---
					when "001" & "0000000" =>
						--- sll ---
					when "101" & "0000000" =>
						--- srl ---
					when "101" & "0100000" =>
						--- sra ---
					when "010" & "0000000" =>
						--- slt ---
					when "011" & "0000000" =>
						--- sltu ---
					when others =>
						vl_illegal_inst := cl_ENABLE;
				end case;
			when cv_IC_I =>
				case instruction.v_funct3 is
					when "001" =>
						--- slli ---
						if instruction.v_funct7 /= "0000000" then
							vl_illegal_inst := cl_ENABLE;
						end if;
					when "101" =>
						--- srli ---
						--- srai ---
						if instruction.v_funct7 /= "0000000" and instruction.v_funct7 /= "0100000" then
							vl_illegal_inst := cl_ENABLE;
						end if;
					when others =>
						--- all cases are redundant ---
						vl_illegal_inst := cl_DISABLE;
				end case;
			when cv_IC_I_LD =>
				case instruction.v_funct3 is
					when "011" | "110" | "111" =>
						vl_illegal_inst := cl_ENABLE;
					when others =>
				end case;
			when cv_IC_I_JALR =>
				--- jalr ---
				if instruction.v_funct3 /= "000" then
					vl_illegal_inst := cl_ENABLE;
				end if;
			when cv_IC_S =>
				case instruction.v_funct3 is
					when "000" | "001" | "010" =>
					when others                =>
						vl_illegal_inst := cl_ENABLE;
				end case;
			when cv_IC_SB =>
				case instruction.v_funct3 is
					when "010" | "011" =>
						vl_illegal_inst := cl_ENABLE;
					when others =>
				end case;
			when cv_IC_J | cv_IC_UI | cv_IC_AUIPC =>
			when cv_IC_SYS =>
				case instruction.v_funct3 is
					when "000" =>
						if instruction.v_funct7 = "0011000" and instruction.v_reg_rs2 = "00010" and instruction.v_reg_rs1 = "00000" and instruction.v_reg_rd = "00000" then -- mret
							vl_illegal_inst := cl_DISABLE;
						elsif instruction.v_funct7 = "0000000" and instruction.v_reg_rs2 = "00000" and instruction.v_reg_rs1 = "00000" and instruction.v_reg_rd = "00000" then -- ecall
							vl_illegal_inst := cl_DISABLE;
						elsif instruction.v_funct7 = "0000000" and instruction.v_reg_rs2 = "00001" and instruction.v_reg_rs1 = "00000" and instruction.v_reg_rd = "00000" then -- ebreak
							vl_illegal_inst := cl_DISABLE;
						else
							vl_illegal_inst := cl_ENABLE;
						end if;
					when "100" =>
						vl_illegal_inst := cl_ENABLE;
					when others =>
						if instruction.v_funct7(6 downto 5) = "11" then -- Read Only CSR
							if instruction.v_funct3(1 downto 0) = "01" then
								vl_illegal_inst := cl_ENABLE; -- CSRRW[I] on Read Only CSR raises illegal instruction flag
							elsif instruction.v_reg_rs1 /= "00000" then
								vl_illegal_inst := cl_ENABLE; --- CSRRS/C[I] and non-zero rs1 raises illegal instruction flag
							end if;
						elsif instruction.v_funct7 = "0111101" then
							if instruction.v_reg_rs2(4) = '1' then
								--- 0x7B0 - 0x7BF are Debug mode only CSRs, i.e. the user cannot access it ---
								vl_illegal_inst := cl_ENABLE;
							end if;
						end if;
				end case;
			when others =>
				vl_illegal_inst := cl_ENABLE;
		end case;

		return vl_illegal_inst;
	end function;

	function fl_check_ext_m(
		instruction : tr_IF_base_format
	) return std_logic is
		variable vl_illegal_inst : std_logic;
	begin
		vl_illegal_inst := cl_DISABLE;
		case instruction.v_opcode is
			when cv_IC_R =>
				if instruction.v_funct7 /= "0000001" then
					vl_illegal_inst := cl_ENABLE;
				end if;
			when others =>
				vl_illegal_inst := cl_ENABLE;
		end case;

		return vl_illegal_inst;
	end function;

	signal sv_dec_intalu_op : std_logic_vector(pov_dec_intalu_op'length - 1 downto 0);
	signal sv_dec_md_op     : std_logic_vector(pov_dec_md_op'length - 1 downto 0);
	signal sv_dec_csr_op    : std_logic_vector(pov_dec_csr_op'length - 1 downto 0);

	signal sl_illegal_inst : std_logic;

	signal str_dec_cpu_ctrl : tr_CS_CPU;

begin

	proc_id_decode : process (pitr_dec_inst)
	begin
		sv_dec_intalu_op              <= (others => '0');
		sv_dec_md_op                  <= (others => '0');
		sv_dec_csr_op                 <= (others => '0');
		str_dec_cpu_ctrl.tr_id_stage  <= ctr_CS_ID_DISABLE;
		str_dec_cpu_ctrl.tr_exe_stage <= ctr_CS_EXE_DISABLE;
		str_dec_cpu_ctrl.tr_ma_stage  <= ctr_CS_MA_DISABLE;
		str_dec_cpu_ctrl.tr_wb_stage  <= ctr_CS_WB_DISABLE;
		str_dec_cpu_ctrl.tr_rvfi      <= ctr_CS_RVFI_RESET;
		case pitr_dec_inst.v_opcode is
			when cv_IC_R =>
				--- alu unit ---
				sv_dec_intalu_op <= pitr_dec_inst.v_funct7(5) & pitr_dec_inst.v_funct3;
				sv_dec_md_op     <= pitr_dec_inst.v_funct3;
				--- id stage control signal ---
				str_dec_cpu_ctrl.tr_id_stage.v_alu_src_mux <= ctr_MUX_alu.src2_R;
				--- exe stage control signal ---
				str_dec_cpu_ctrl.tr_exe_stage.l_intalu_EN  <= not pitr_dec_inst.v_funct7(0);
				str_dec_cpu_ctrl.tr_exe_stage.l_md_EN      <= pitr_dec_inst.v_funct7(0);
				--- wb stage control signal ---
				str_dec_cpu_ctrl.tr_wb_stage.l_rd_WEN <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_wb_stage.v_wb_mux <= ctr_MUX_wb.alu_result;
				--- rvfi control signal ---
				str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_ENABLE;
			when cv_IC_I =>
				--- alu unit ---
				-- uses funct7[5] for srli / srai instructions, for other instructions it is used as immediate value
				sv_dec_intalu_op <= (pitr_dec_inst.v_funct7(5) and pitr_dec_inst.v_funct3(2) and not pitr_dec_inst.v_funct3(1) and pitr_dec_inst.v_funct3(0)) & pitr_dec_inst.v_funct3;
				--- id stage control signal ---
				str_dec_cpu_ctrl.tr_id_stage.v_alu_src_mux <= ctr_MUX_alu.src2_I_imm;
				--- exe stage control signal ---
				str_dec_cpu_ctrl.tr_exe_stage.l_intalu_EN  <= cl_ENABLE;
				--- wb stage control signal ---
				str_dec_cpu_ctrl.tr_wb_stage.l_rd_WEN <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_wb_stage.v_wb_mux <= ctr_MUX_wb.alu_result;
				--- rvfi control signal ---
				str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_DISABLE;
			when cv_IC_I_LD =>
				--- alu unit ---
				sv_dec_intalu_op <= cv_ALU_ADD;
				--- id stage control signal ---
				str_dec_cpu_ctrl.tr_id_stage.v_alu_src_mux <= ctr_MUX_alu.src2_I_imm;
				--- exe stage control signal ---
				str_dec_cpu_ctrl.tr_exe_stage.l_intalu_EN <= cl_ENABLE;
				--- ma stage control signal ---
				str_dec_cpu_ctrl.tr_ma_stage.l_is_mem_inst    <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_ma_stage.v_data_width_mux <= pitr_dec_inst.v_funct3(1 downto 0);
				str_dec_cpu_ctrl.tr_ma_stage.l_sign_ext       <= pitr_dec_inst.v_funct3(2);
				--- wb stage control signal ---
				str_dec_cpu_ctrl.tr_wb_stage.l_rd_WEN <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_wb_stage.v_wb_mux <= ctr_MUX_wb.wb_memory;
				--- rvfi control signal ---
				str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_DISABLE;
			when cv_IC_I_JALR =>
				--- alu unit ---
				sv_dec_intalu_op <= cv_ALU_ADD;
				--- id stage control signal ---
				str_dec_cpu_ctrl.tr_id_stage.v_alu_src_mux <= ctr_MUX_alu.src2_I_imm;
				--- exe stage control signal ---
				str_dec_cpu_ctrl.tr_exe_stage.l_intalu_EN           <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_exe_stage.l_branch_addr_src_mux <= ctr_MUX_branch_src_addr.I_type_addr;
				--- ma stage control signal ---
				str_dec_cpu_ctrl.tr_ma_stage.l_is_branch_inst <= cl_ENABLE;
				--- wb stage control signal ---
				str_dec_cpu_ctrl.tr_wb_stage.l_rd_WEN <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_wb_stage.v_wb_mux <= ctr_MUX_wb.prog_addr;
				--- rvfi control signal ---
				str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_DISABLE;
			when cv_IC_S =>
				--- alu unit ---
				sv_dec_intalu_op <= cv_ALU_ADD;
				--- id stage control signal ---
				str_dec_cpu_ctrl.tr_id_stage.v_alu_src_mux <= ctr_MUX_alu.src2_S_imm;
				--- exe stage control signal ---
				str_dec_cpu_ctrl.tr_exe_stage.l_intalu_EN <= cl_ENABLE;
				--- ma stage control signal ---
				str_dec_cpu_ctrl.tr_ma_stage.l_is_mem_inst    <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_ma_stage.v_data_width_mux <= pitr_dec_inst.v_funct3(1 downto 0);
				str_dec_cpu_ctrl.tr_ma_stage.l_RAM_WEN        <= cl_ENABLE;
				--- rvfi control signal ---
				str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_ENABLE;
			when cv_IC_SB =>
				--- alu unit ---
				sv_dec_intalu_op <= "001" & (pitr_dec_inst.v_funct3(2) and pitr_dec_inst.v_funct3(1)); -- unsigned -> ltu is selected, signed -> lt/sub
				--- id stage control signal ---
				str_dec_cpu_ctrl.tr_id_stage.v_alu_src_mux <= ctr_MUX_alu.src2_R;
				--- exe stage control signal ---
				str_dec_cpu_ctrl.tr_exe_stage.l_intalu_EN           <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_exe_stage.l_branch_offset_mux   <= ctr_MUX_branch_offset.B_type;
				str_dec_cpu_ctrl.tr_exe_stage.l_branch_addr_src_mux <= ctr_MUX_branch_src_addr.B_UJ_type_addr;
				--- ma stage control signal ---
				str_dec_cpu_ctrl.tr_ma_stage.l_is_branch_inst <= cl_ENABLE;
				--- rvfi control signal ---
				str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_ENABLE;
			when cv_IC_UI =>
				--- alu unit ---
				sv_dec_intalu_op <= cv_ALU_temp2_pass;
				--- id stage control signal ---
				str_dec_cpu_ctrl.tr_id_stage.v_alu_src_mux <= ctr_MUX_alu.src2_U_imm;
				--- exe stage control signal ---
				str_dec_cpu_ctrl.tr_exe_stage.l_intalu_EN <= cl_ENABLE;
				--- wb stage control signal ---
				str_dec_cpu_ctrl.tr_wb_stage.l_rd_WEN <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_wb_stage.v_wb_mux <= ctr_MUX_wb.alu_result;
				--- rvfi control signal ---
				str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= cl_DISABLE;
				str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_DISABLE;
			when cv_IC_AUIPC =>
				--- alu unit ---
				sv_dec_intalu_op <= cv_ALU_ADD;
				--- id stage control signal ---
				str_dec_cpu_ctrl.tr_id_stage.v_alu_src_mux <= ctr_MUX_alu.src1_src2_auipc;
				--- exe stage control signal ---
				str_dec_cpu_ctrl.tr_exe_stage.l_intalu_EN <= cl_ENABLE;
				--- wb stage control signal ---
				str_dec_cpu_ctrl.tr_wb_stage.l_rd_WEN <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_wb_stage.v_wb_mux <= ctr_MUX_wb.alu_result;
				--- rvfi control signal ---
				str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= cl_DISABLE;
				str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_DISABLE;
			when cv_IC_J =>
				--- exe stage control signal ---
				str_dec_cpu_ctrl.tr_exe_stage.l_branch_offset_mux   <= ctr_MUX_branch_offset.UJ_type;
				str_dec_cpu_ctrl.tr_exe_stage.l_branch_addr_src_mux <= ctr_MUX_branch_src_addr.B_UJ_type_addr;
				--- ma stage control signal ---
				str_dec_cpu_ctrl.tr_ma_stage.l_is_branch_inst <= cl_ENABLE;
				--- wb stage control signal ---
				str_dec_cpu_ctrl.tr_wb_stage.l_rd_WEN <= cl_ENABLE;
				str_dec_cpu_ctrl.tr_wb_stage.v_wb_mux <= ctr_MUX_wb.prog_addr;
				--- rvfi control signal ---
				str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= cl_DISABLE;
				str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_DISABLE;
			when cv_IC_SYS =>
				if pitr_dec_inst.v_funct3 = "000" then
					--- ecall, ebreak, mret, wfi ---
					--- mret ---
					if pitr_dec_inst.v_funct7 = "0011000" and pitr_dec_inst.v_reg_rs2 = "00010" and pitr_dec_inst.v_reg_rs1 = "00000" and pitr_dec_inst.v_reg_rd = "00000" then
						str_dec_cpu_ctrl.tr_ma_stage.l_is_mret <= cl_ENABLE;
					end if;
					--- ecall ---
					if pitr_dec_inst.v_funct7 = "0000000" and pitr_dec_inst.v_reg_rs2 = "00000" and pitr_dec_inst.v_reg_rs1 = "00000" and pitr_dec_inst.v_reg_rd = "00000" then
						str_dec_cpu_ctrl.tr_ma_stage.l_is_ecall <= cl_ENABLE;
					end if;
					--- ebreak ---
					if pitr_dec_inst.v_funct7 = "0000000" and pitr_dec_inst.v_reg_rs2 = "00001" and pitr_dec_inst.v_reg_rs1 = "00000" and pitr_dec_inst.v_reg_rd = "00000" then
						str_dec_cpu_ctrl.tr_ma_stage.l_is_ebreak <= cl_ENABLE;
					end if;
				else
					--- csr instruction ---
					sv_dec_csr_op <= pitr_dec_inst.v_funct3;
					--- exe stage control signal ---
					str_dec_cpu_ctrl.tr_exe_stage.l_csr_EN <= cl_ENABLE;
					--- ma stage control signal ---
					str_dec_cpu_ctrl.tr_ma_stage.l_CSR_WEN <= cl_ENABLE;
					--- wb stage control signal ---
					str_dec_cpu_ctrl.tr_wb_stage.l_rd_WEN <= cl_ENABLE;
					str_dec_cpu_ctrl.tr_wb_stage.v_wb_mux <= ctr_MUX_wb.alu_result;
					--- rvfi control signal ---
					str_dec_cpu_ctrl.tr_rvfi.l_rs1_ren <= not pitr_dec_inst.v_funct3(2);
					str_dec_cpu_ctrl.tr_rvfi.l_rs2_ren <= cl_DISABLE;
				end if;
			when others =>
				str_dec_cpu_ctrl.tr_exe_stage <= ctr_CS_EXE_DISABLE;
				str_dec_cpu_ctrl.tr_ma_stage  <= ctr_CS_MA_DISABLE;
				str_dec_cpu_ctrl.tr_wb_stage  <= ctr_CS_WB_DISABLE;
				str_dec_cpu_ctrl.tr_rvfi      <= ctr_CS_RVFI_RESET;
		end case;
	end process proc_id_decode;

	gen_illegal_inst_check_rv32im : if gb_EXT_M = true generate
		proc_illegal_inst_check : process (pitr_dec_inst)
			variable vl_check_rv32i : std_logic;
			variable vl_check_ext_m : std_logic;
		begin
			vl_check_rv32i := fl_check_rv32i(instruction => pitr_dec_inst);
			vl_check_ext_m := fl_check_ext_m(instruction => pitr_dec_inst);
			sl_illegal_inst <= vl_check_rv32i and vl_check_ext_m;
		end process proc_illegal_inst_check;
	else gen_illegal_inst_check_rv32i : generate
		proc_illegal_inst_check : process (pitr_dec_inst)
		begin
			sl_illegal_inst <= fl_check_rv32i(instruction => pitr_dec_inst);
		end process proc_illegal_inst_check;
	end generate;

	pov_dec_intalu_op <= sv_dec_intalu_op;
	pov_dec_md_op     <= sv_dec_md_op;
	pov_dec_csr_op    <= sv_dec_csr_op;

	pol_illegal_inst <= sl_illegal_inst;

	potr_dec_cpu_ctrl.tr_id_stage  <= ctr_CS_ID_DISABLE when sl_illegal_inst = cl_ENABLE else str_dec_cpu_ctrl.tr_id_stage;
	potr_dec_cpu_ctrl.tr_exe_stage <= ctr_CS_EXE_DISABLE when sl_illegal_inst = cl_ENABLE else str_dec_cpu_ctrl.tr_exe_stage;
	potr_dec_cpu_ctrl.tr_ma_stage  <= ctr_CS_MA_DISABLE when sl_illegal_inst = cl_ENABLE else str_dec_cpu_ctrl.tr_ma_stage;
	potr_dec_cpu_ctrl.tr_wb_stage  <= ctr_CS_WB_DISABLE when sl_illegal_inst = cl_ENABLE else str_dec_cpu_ctrl.tr_wb_stage;
	potr_dec_cpu_ctrl.tr_rvfi      <= ctr_CS_RVFI_RESET when sl_illegal_inst = cl_ENABLE else str_dec_cpu_ctrl.tr_rvfi;

end architecture;