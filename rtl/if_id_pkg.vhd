library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

package if_id_pkg is

	type tr_ifid_stage_reg is record
		t_inst                    : tr_IF_base_format;
		v_compressed_inst         : std_logic_vector(31 downto 0); -- The 16 MSBs are zero extended
		v_addr                    : std_logic_vector(31 downto 0);
		l_rvfi_intr               : std_logic;
		l_irq_regfile_sel         : std_logic;
		l_is_compressed           : std_logic;
		l_illegal_compressed_inst : std_logic;
		l_nop_inst                : std_logic;
	end record tr_ifid_stage_reg;

	constant ctr_ifid_stage_reg_FLUSH : tr_ifid_stage_reg := (
		t_inst                    => ctr_IF_base_format_ZERO,
		v_compressed_inst         => (others => '0'),
		v_addr                    => (others => '0'),
		l_rvfi_intr               => cl_DISABLE,
		l_irq_regfile_sel         => cl_DISABLE,
		l_is_compressed           => cl_DISABLE,
		l_illegal_compressed_inst => cl_DISABLE,
		l_nop_inst                => cl_DISABLE
	);

end package if_id_pkg;