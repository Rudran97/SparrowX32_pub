library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

package ma_wb_pkg is

	type tr_mawb_stage_reg is record
		t_inst                : tr_IF_base_format;
		v_compressed_inst     : std_logic_vector(31 downto 0);
		v_addr                : std_logic_vector(31 downto 0);
		v_mem_data            : std_logic_vector(31 downto 0);
		v_result              : std_logic_vector(31 downto 0);
		v_csr_wdata           : std_logic_vector(31 downto 0);
		l_branch_taken        : std_logic;
		t_wb_ctrl             : tr_CS_WB;
		l_is_compressed       : std_logic;
		l_is_branch_inst_copy : std_logic;
		l_inst_tag            : std_logic;
		l_irq_regfile_sel     : std_logic;
		l_illegal_inst        : std_logic;
		t_rvfi_csr            : tr_CSR;
	end record tr_mawb_stage_reg;

	constant ctr_mawb_stage_reg_FLUSH : tr_mawb_stage_reg := (
		t_inst                => ctr_IF_base_format_ZERO,
		v_compressed_inst     => (others => '0'),
		v_addr                => (others => '0'),
		v_mem_data            => (others => '0'),
		v_result              => (others => '0'),
		v_csr_wdata           => (others => '0'),
		l_branch_taken        => cl_DISABLE,
		t_wb_ctrl             => ctr_CS_WB_DISABLE,
		l_is_compressed       => cl_DISABLE,
		l_is_branch_inst_copy => cl_DISABLE,
		l_inst_tag            => cl_DISABLE,
		l_illegal_inst        => cl_DISABLE,
		l_irq_regfile_sel     => cl_DISABLE,
		t_rvfi_csr            => ctr_CSR_ZERO
	);

end package ma_wb_pkg;