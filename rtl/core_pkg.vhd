library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package core_pkg is

	-----------------------------------------------------------------------------------------------------
	------------------------------------INSTRUCTION FORMAT (IF)------------------------------------------
	-----------------------------------------------------------------------------------------------------

	--- Base format ---

	constant ci_IF_opcode_l : integer := 0;
	constant ci_IF_opcode_u : integer := 6;

	constant ci_IF_rd_l : integer := 7;
	constant ci_IF_rd_u : integer := 11;

	constant ci_IF_funct3_l : integer := 12;
	constant ci_IF_funct3_u : integer := 14;

	constant ci_IF_rs1_l : integer := 15;
	constant ci_IF_rs1_u : integer := 19;

	constant ci_IF_rs2_l : integer := 20;
	constant ci_IF_rs2_u : integer := 24;

	constant ci_IF_funct7_l : integer := 25;
	constant ci_IF_funct7_u : integer := 31;

	--- Immediate format I type ---

	constant ci_IF_I_imm_l : integer := ci_IF_rs2_l;
	constant ci_IF_I_imm_u : integer := ci_IF_funct7_u;

	--- Immediate format S type ---

	constant ci_IF_S_imml_l : integer := ci_IF_rd_l;
	constant ci_IF_S_imml_u : integer := ci_IF_rd_u;
	constant ci_IF_S_immu_l : integer := ci_IF_funct7_l;
	constant ci_IF_S_immu_u : integer := ci_IF_funct7_u;

	--- Immediate format U type ---

	constant ci_IF_U_imm_l : integer := ci_IF_funct3_l;
	constant ci_IF_U_imm_u : integer := ci_IF_funct7_u;

	-----------------------------------------------------------------------------------------------------
	-------------------------------------CPU STATUS FLAGS (SF)-------------------------------------------
	-----------------------------------------------------------------------------------------------------
	
	type tr_SF_CPU is record
		int_alu_CF : std_logic; -- CPU Carry Flag 
		int_alu_ZF : std_logic; -- CPU Zero Flag
		int_alu_VF : std_logic; -- CPU Overflow Flag
		int_alu_NF : std_logic; -- CPU Negative result Flag
	end record tr_SF_CPU;

	-----------------------------------------------------------------------------------------------------
	-----------------------------------CPU CONTROL SIGNALS (CS)------------------------------------------
	-----------------------------------------------------------------------------------------------------

	type tr_CS_ID is record
		--- alu source mux controls ---
		v_alu_src_mux : std_logic_vector(2 downto 0); --- mux2 mux1 mux0 ---
													  ---   0    0    0   -> alu_src2 = R_src2
													  ---   0    0    1   -> alu_src2 = I type Immediate
													  ---   0    1    0   -> alu_src2 = S type Immediate
													  ---   1    0    0   -> alu_src2 = U type Immediate
													  ---   1    0    1   -> alu_src1 = PC Address, alu_src2 = U type Immediate
	end record tr_CS_ID;

	type tr_CS_EXE is record
		--- alu controls ---
		l_intalu_EN : std_logic; -- ALU is always enabled by default
		l_md_EN     : std_logic;
		l_csr_EN    : std_logic;
		--- branch offset formation mux control ---
		l_branch_offset_mux : std_logic; -- '1' -> Immediate offset formed for UJ type, '0' -> Immediate offset formed for SB type
		--- branch source address calculation mux control ---
		l_branch_addr_src_mux : std_logic; -- Selects the source value to calculate the branch address.
										   -- It will either use the immediate offset to the PC (UJ and SB - type) or directly use the alu result
										   -- to jump to the correct address i.e. in case of jalr (I - type)
										   -- '1' -> alu_result (result of I type branch), '0' -> from add_gen_unit i.e. PC relative (UJ and SB - type)
	end record tr_CS_EXE;

	type tr_CS_MA is record
		l_is_mem_inst : std_logic; -- This bit must be set when the instruction accesses any memory module
		--- csr controls ---
		l_CSR_WEN : std_logic;
		--- ram controls ---
		l_RAM_WEN : std_logic;
		--- mem data signedness control ---
		l_sign_ext : std_logic; -- '0' -> sign extended load, '1' -> zero extended load
		--- mret branch control ---
		l_is_mret   : std_logic;
		--- SYS call ---
		l_is_ecall  : std_logic;
		l_is_ebreak : std_logic;
		--- branch instruction control ---
		l_is_branch_inst : std_logic; -- for all branch instruction types I, J and SB, this bit must be set indicating a branch instruction
		--- mem data width mux control ---
		v_data_width_mux : std_logic_vector(1 downto 0); --- mux1 mux0 ---
													     ---  0    0   -> byte
													     ---  0    1   -> half-word
													     ---  1    0   -> word
	end record tr_CS_MA;

	type tr_CS_WB is record
		--- destination register write enable ---
		l_rd_WEN : std_logic;
		--- destination register write data select ---
		v_wb_mux : std_logic_vector(1 downto 0); --- mux1 mux0 ---
												 ---  0    0   -> alu result
												 ---  0    1   -> memory
												 ---  1    0   -> prog address
	end record tr_CS_WB;

	type tr_CS_rvfi is record
		l_rs1_ren : std_logic; -- '1' -> rs1 is used to read, '0' -> rs1 not in use 
		l_rs2_ren : std_logic; -- '1' -> rs2 is used to read, '0' -> rs2 not in use 
	end record tr_CS_rvfi;

	type tr_CS_CPU is record
		tr_id_stage  : tr_CS_ID;
		tr_exe_stage : tr_CS_EXE;
		tr_ma_stage  : tr_CS_MA;
		tr_wb_stage  : tr_CS_WB;
		tr_rvfi      : tr_CS_rvfi;
	end record tr_CS_CPU;

	-----------------------------------------------------------------------------------------------------
	-----------------------------------CPU INSTRUCTION CODE (IC)-----------------------------------------
	-----------------------------------------------------------------------------------------------------

	--- instruction type ---

	--- R type ---
	constant cv_IC_R : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "0110011";

	--- I type ---
	constant cv_IC_I      : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "0010011";
	constant cv_IC_I_LD   : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "0000011"; -- Load from Memory
	constant cv_IC_I_JALR : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "1100111"; -- Jump and Link Register

	--- S type ---
	constant cv_IC_S : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "0100011";

	--- SB type ---
	constant cv_IC_SB : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "1100011";

	--- UI type ---
	constant cv_IC_UI    : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "0110111"; -- Upper immediate : loads upper 20 bits into the destination register
	constant cv_IC_AUIPC : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "0010111"; -- Add upper immediate to PC and store it in rd

	--- UJ / J type ---
	constant cv_IC_J : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "1101111"; -- Jump and Link

	--- SYSTEM type ---
	constant cv_IC_SYS : std_logic_vector(ci_IF_opcode_u downto ci_IF_opcode_l) := "1110011"; -- csr, ebrake, ecall instructions

	-----------------------------------------------------------------------------------------------------
	--------------------------------------DATA PATH MUX VALUES-------------------------------------------
	-----------------------------------------------------------------------------------------------------
	
	--- alu src mux ---
	type tr_MUX_alu is record
		src2_R          : std_logic_vector(2 downto 0);
		src2_I_imm      : std_logic_vector(2 downto 0);
		src2_S_imm      : std_logic_vector(2 downto 0);
		src2_U_imm      : std_logic_vector(2 downto 0);
		src1_src2_auipc : std_logic_vector(2 downto 0);
	end record tr_MUX_alu;

	constant ctr_MUX_alu : tr_MUX_alu := (
		src2_R    		=> "000",
		src2_I_imm		=> "001",
		src2_S_imm		=> "010",
		src2_U_imm		=> "100",
		src1_src2_auipc => "101"
	);

	--- branch offset formation mux ---
	type tr_MUX_branch_offset is record
		B_type  : std_logic;
		UJ_type : std_logic;
	end record tr_MUX_branch_offset;

	constant ctr_MUX_branch_offset : tr_MUX_branch_offset := (
		B_type  => '0',
		UJ_type => '1'
	);

	--- branch source address calculation mux ---
	type tr_MUX_branch_src_addr is record
		B_UJ_type_addr : std_logic;
		I_type_addr    : std_logic;
	end record tr_MUX_branch_src_addr;
	
	constant ctr_MUX_branch_src_addr : tr_MUX_branch_src_addr := (
		B_UJ_type_addr => '0',
		I_type_addr    => '1'
	);

	--- memory access data width mux ---
	type tr_MUX_mem_data_width is record
		byte_sel  : std_logic_vector(1 downto 0);
		hword_sel : std_logic_vector(1 downto 0);
		word_sel  : std_logic_vector(1 downto 0);
	end record tr_MUX_mem_data_width;

	constant ctr_MUX_mem_data_width : tr_MUX_mem_data_width := (
		byte_sel  => "00",
		hword_sel => "01",
		word_sel  => "10"
	);
	
	--- wb mux ---
	type tr_MUX_wb is record
		alu_result : std_logic_vector(1 downto 0);
		wb_memory  : std_logic_vector(1 downto 0);
		prog_addr  : std_logic_vector(1 downto 0);
	end record tr_MUX_wb;

	constant ctr_MUX_wb : tr_MUX_wb := (
		alu_result => "00",
		wb_memory  => "01",
		prog_addr  => "10"
	);

	-----------------------------------------------------------------------------------------------------
	-----------------------------General Constants / Types / Functions-----------------------------------
	-----------------------------------------------------------------------------------------------------

	constant cv_zeroaddr   : std_logic_vector(31 downto 0) := (others => '0');
	constant cv_zerodata   : std_logic_vector(31 downto 0) := (others => '0');
	constant cv_pipebubble : std_logic_vector(31 downto 0) := (others => '0');

	constant cl_ENABLE  : std_logic := '1';
	constant cl_DISABLE : std_logic := '0';

	constant cl_RESET    : std_logic := '1';
	constant cl_NOTRESET : std_logic := '0';

	type tr_pipe_status is record
		l_ready : std_logic;
		l_stb   : std_logic;
	end record tr_pipe_status;

	type tr_IF_base_format is record
		v_opcode  : std_logic_vector(6 downto 0);
		v_reg_rd  : std_logic_vector(4 downto 0);
		v_funct3  : std_logic_vector(2 downto 0);
		v_reg_rs1 : std_logic_vector(4 downto 0);
		v_reg_rs2 : std_logic_vector(4 downto 0);
		v_funct7  : std_logic_vector(6 downto 0);
	end record tr_IF_base_format;

	type tr_CSR is record
		v_MISA      : std_logic_vector(31 downto 0);
		v_MVENDORID : std_logic_vector(31 downto 0);
		v_MARCHID   : std_logic_vector(31 downto 0);
		v_MIMPID    : std_logic_vector(31 downto 0);
		v_MHARTID   : std_logic_vector(31 downto 0);
		v_MINSTRET  : std_logic_vector(31 downto 0);
		v_MSTATUS   : std_logic_vector(31 downto 0);
		v_MIE       : std_logic_vector(31 downto 0);
		v_MTVEC     : std_logic_vector(31 downto 0);
		v_MIP       : std_logic_vector(31 downto 0);
		v_MCAUSE    : std_logic_vector(31 downto 0);
		v_MEPC      : std_logic_vector(31 downto 0);
		v_MSCRATCH  : std_logic_vector(31 downto 0);
		v_MTVAL     : std_logic_vector(31 downto 0);
		v_TSELECT   : std_logic_vector(31 downto 0);
		v_TDATA1    : std_logic_vector(31 downto 0);
		v_TDATA2    : std_logic_vector(31 downto 0);
		v_DCSR      : std_logic_vector(31 downto 0);
		v_DPC       : std_logic_vector(31 downto 0);
		v_DSCRATCH0 : std_logic_vector(31 downto 0);
		v_DSCRATCH1 : std_logic_vector(31 downto 0);
	end record tr_CSR;

	subtype tv_reg_size is std_logic_vector(4 downto 0);

	function fv_gen_SB_offset(
		instruction : std_logic_vector(31 downto 0)
	) return std_logic_vector;

	function fv_gen_UJ_offset(
		instruction : std_logic_vector(31 downto 0)
	) return std_logic_vector;
	
	function fv_gen_mem_data_signedness(
		data       : std_logic_vector(31 downto 0);
		data_width : std_logic_vector(1 downto 0);
		signedness : std_logic
	) return std_logic_vector;
	
	function fi_get_leading_one(
		v_value : std_logic_vector(31 downto 0)
	) return integer;	

	function ftr_inst_slv2rec(
		instruction : std_logic_vector(31 downto 0)
	) return tr_IF_base_format;

	function fv_inst_rec2slv(
		instruction : tr_IF_base_format
	) return std_logic_vector;

	constant ctr_IF_base_format_ZERO : tr_IF_base_format := (
		v_funct7  => (others => '0'), 
		v_reg_rs2 => (others => '0'), 
		v_reg_rs1 => (others => '0'), 
		v_funct3  => (others => '0'), 
		v_reg_rd  => (others => '0'), 
		v_opcode  => (others => '0') 
	);

	constant ctr_IF_base_format_NOP : tr_IF_base_format := (
		v_funct7  => (others => '0'), 
		v_reg_rs2 => (others => '0'), 
		v_reg_rs1 => (others => '0'), 
		v_funct3  => (others => '0'), 
		v_reg_rd  => (others => '0'), 
		v_opcode  => cv_IC_I 
	);

	constant ctr_CSR_ZERO : tr_CSR := (
		v_MISA      => (others => '0'),
		v_MVENDORID => (others => '0'),
		v_MARCHID   => (others => '0'),
		v_MIMPID    => (others => '0'),
		v_MHARTID   => (others => '0'),
		v_MINSTRET  => (others => '0'),
		v_MSTATUS   => (others => '0'),
		v_MIE       => (others => '0'),
		v_MTVEC     => (others => '0'),
		v_MIP       => (others => '0'),
		v_MCAUSE    => (others => '0'),
		v_MEPC      => (others => '0'),
		v_MSCRATCH  => (others => '0'),
		v_MTVAL     => (others => '0'),
		v_TSELECT   => (others => '0'),
		v_TDATA1    => (others => '0'),
		v_TDATA2    => (others => '0'),
        v_DCSR      => (others => '0'),
        v_DPC       => (others => '0'),
        v_DSCRATCH0 => (others => '0'),
        v_DSCRATCH1 => (others => '0')
	);

	constant ctr_CS_ID_DISABLE : tr_CS_ID := (
		v_alu_src_mux => (others => '0')
	);

	constant ctr_CS_EXE_DISABLE : tr_CS_EXE := (
		l_intalu_EN           => cl_DISABLE, 
		l_md_EN 			  => cl_DISABLE,
		l_csr_EN              => cl_DISABLE,
		l_branch_offset_mux   => cl_DISABLE,
		l_branch_addr_src_mux => cl_DISABLE
	);

	constant ctr_CS_MA_DISABLE : tr_CS_MA := (
		l_is_mem_inst    => cl_DISABLE,
		l_CSR_WEN        => cl_DISABLE,
		l_RAM_WEN        => cl_DISABLE,
		l_sign_ext       => cl_DISABLE,
		l_is_mret        => cl_DISABLE,
		l_is_ecall       => cl_DISABLE,
		l_is_ebreak      => cl_DISABLE,
		l_is_branch_inst => cl_DISABLE,
		v_data_width_mux => (others => '0')
	);

	constant ctr_CS_WB_DISABLE : tr_CS_WB := (
		l_rd_WEN => cl_DISABLE,
		v_wb_mux => (others => '0')
	);

	constant ctr_CS_RVFI_RESET : tr_CS_rvfi := (
		l_rs1_ren => cl_DISABLE,
		l_rs2_ren => cl_DISABLE
	);

end package;

package body core_pkg is

	--- 32 bit immediate formed from 32 bit instruction ---

	--- 31 -- 30 ---------- 20 19 ------------- 12 ------ 11 10 --------- 5 4 --------- 1 - 0
	-- |___________________inst31_________________|__inst7__|__inst30..25__|__inst11..8__| 0 |   SB Immediate format
	-- |________inst31________|_____inst19..12____|__inst20_|__inst30..25__|__inst24..21_| 0 |   UJ Immediate format

	function fv_gen_SB_offset(
		instruction : std_logic_vector(31 downto 0)) return std_logic_vector is
		variable vv_offset : std_logic_vector(instruction'length - 1 downto 0);
	begin
		--- immediate offset is a multiple of 2 so the last bit is always 0. In total including the last bit, the immediate field is 13 bit widde.
		vv_offset := (31 downto 12 => instruction(31)) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0';
		return vv_offset;
	end function;

	function fv_gen_UJ_offset(
		instruction : std_logic_vector(31 downto 0)) return std_logic_vector is
		variable vv_offset : std_logic_vector(instruction'length - 1 downto 0);
	begin
		--- immediate offset is a multiple of 2 so the last bit is always 0. In total including the last bit, the immediate field is 21 bit widde.
		vv_offset := (31 downto 20 => instruction(31)) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 25) & instruction(24 downto 21) & '0';
		return vv_offset;
	end function;

	function fv_gen_mem_data_signedness(
		data       : std_logic_vector(31 downto 0);
		data_width : std_logic_vector(1 downto 0);
		signedness : std_logic) return std_logic_vector is
		variable vv_data : std_logic_vector(data'length - 1 downto 0);
	begin
		case data_width is
			when ctr_MUX_mem_data_width.byte_sel =>
				vv_data := (vv_data'high downto 8 => not signedness and data(7)) & data(7 downto 0);
			when ctr_MUX_mem_data_width.hword_sel =>
				vv_data := (vv_data'high downto 16 => not signedness and data(15)) & data(15 downto 0);
			when others =>
				vv_data := data;
		end case;
		return vv_data;
	end function;

	function fi_get_leading_one(
		v_value : std_logic_vector(31 downto 0)
	) return integer is
  	begin
		for bit_position in v_value'high downto v_value'low loop
			if v_value(bit_position) = '1' then
				return bit_position;
			end if;
		end loop;
		return 0;  -- when no 1 then return 0 as bit position
	end function;

	function ftr_inst_slv2rec(
		instruction : std_logic_vector(31 downto 0)
	) return tr_IF_base_format is
		variable vtr_inst : tr_IF_base_format;
	begin
		vtr_inst.v_funct7  := instruction(ci_IF_funct7_u downto ci_IF_funct7_l);
		vtr_inst.v_reg_rs2 := instruction(ci_IF_rs2_u downto ci_IF_rs2_l);
		vtr_inst.v_reg_rs1 := instruction(ci_IF_rs1_u downto ci_IF_rs1_l);
		vtr_inst.v_funct3  := instruction(ci_IF_funct3_u downto ci_IF_funct3_l);
		vtr_inst.v_reg_rd  := instruction(ci_IF_rd_u downto ci_IF_rd_l);
		vtr_inst.v_opcode  := instruction(ci_IF_opcode_u downto ci_IF_opcode_l);

		return vtr_inst;
	end function;

	function fv_inst_rec2slv(
		instruction : tr_IF_base_format
	) return std_logic_vector is
		variable vv_inst : std_logic_vector(31 downto 0);
  	begin
		vv_inst(ci_IF_funct7_u downto ci_IF_funct7_l) := instruction.v_funct7;
		vv_inst(ci_IF_rs2_u downto ci_IF_rs2_l)       := instruction.v_reg_rs2;
		vv_inst(ci_IF_rs1_u downto ci_IF_rs1_l)       := instruction.v_reg_rs1;
		vv_inst(ci_IF_funct3_u downto ci_IF_funct3_l) := instruction.v_funct3;
		vv_inst(ci_IF_rd_u downto ci_IF_rd_l)         := instruction.v_reg_rd;
		vv_inst(ci_IF_opcode_u downto ci_IF_opcode_l) := instruction.v_opcode;

		return vv_inst;
  	end function;

end package body;
