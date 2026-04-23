library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

package id_exe_pkg is

	type tr_idexe_stage_reg is record
		t_inst                : tr_IF_base_format;
		v_compressed_inst     : std_logic_vector(31 downto 0);
		v_addr                : std_logic_vector(31 downto 0);
		v_src1                : std_logic_vector(31 downto 0);
		v_src2                : std_logic_vector(31 downto 0);
		v_fw_rsrc2            : std_logic_vector(31 downto 0);
		v_intalu_op           : std_logic_vector(3 downto 0);
		v_md_op               : std_logic_vector(2 downto 0);
		v_csr_op              : std_logic_vector(2 downto 0);
		t_exe_ctrl            : tr_CS_EXE;
		t_ma_ctrl             : tr_CS_MA;
		t_wb_ctrl             : tr_CS_WB;
		t_rvfi                : tr_CS_rvfi;
		l_rvfi_intr           : std_logic;
		l_irq_regfile_sel     : std_logic;
		l_is_compressed       : std_logic;
		l_is_branch_inst_copy : std_logic;
		l_is_mret_copy        : std_logic;
		l_nop_inst            : std_logic;
		l_inst_tag            : std_logic;
		l_illegal_inst        : std_logic;
	end record tr_idexe_stage_reg;

	constant ctr_idexe_stage_reg_FLUSH : tr_idexe_stage_reg := (
		t_inst                => ctr_IF_base_format_ZERO,
		v_compressed_inst     => (others => '0'),
		v_addr                => (others => '0'),
		v_src1                => (others => '0'),
		v_src2                => (others => '0'),
		v_fw_rsrc2            => (others => '0'),
		v_intalu_op           => (others => '0'),
		v_md_op               => (others => '0'),
		v_csr_op              => (others => '0'),
		t_exe_ctrl            => ctr_CS_EXE_DISABLE,
		t_ma_ctrl             => ctr_CS_MA_DISABLE,
		t_wb_ctrl             => ctr_CS_WB_DISABLE,
		t_rvfi                => ctr_CS_RVFI_RESET,
        l_rvfi_intr           => cl_DISABLE,
		l_irq_regfile_sel     => cl_DISABLE,
		l_is_compressed       => cl_DISABLE,
		l_is_branch_inst_copy => cl_DISABLE,
		l_is_mret_copy        => cl_DISABLE,
		l_nop_inst            => cl_DISABLE,
		l_inst_tag            => cl_DISABLE,
		l_illegal_inst        => cl_DISABLE
	);

end package id_exe_pkg;