library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity sys_register_file is
	generic (
		gb_RV32_E        : boolean          := false; -- true -> 16 GPRs, false -> 32 GPRs
		gb_GPR_HW_BACKUP : boolean          := false; -- true -> Regfiles would be backed up in HW during FAST IRQ
		gv_RESET_VAL     : std_logic_vector := X"00000000"
	);
	port (
		pil_clk             : in std_logic;
		pil_rst             : in std_logic;
		pil_we              : in std_logic;
		pil_irq_regfile_sel : in std_logic   := cl_DISABLE;
		pitv_raddr_rs1      : in tv_reg_size;
		pitv_raddr_rs2      : in tv_reg_size;
		pitv_waddr_rd       : in tv_reg_size;
		piv_wdata           : in std_logic_vector(31 downto 0);
		pov_rdata_rs1       : out std_logic_vector(31 downto 0);
		pov_rdata_rs2       : out std_logic_vector(31 downto 0)
	);
end entity sys_register_file;

architecture rtl of sys_register_file is

	function fi_get_register_count(
		core_type : boolean
	) return integer is
		variable vi_register_count : integer range 1 to 32;
	begin
		if core_type = true then
			vi_register_count := 16;
		else
			vi_register_count := 32;
		end if;
		return vi_register_count;
	end function;

	constant ci_register_count : integer := fi_get_register_count(core_type => gb_RV32_E);

	type tav_sys_register_file is array (0 to ci_register_count - 1) of std_logic_vector(31 downto 0);
	signal stav_sys_gpr      : tav_sys_register_file; -- gp register file
	signal stav_irq_sys_gpr  : tav_sys_register_file; -- irq register file

begin

	assert ci_register_count = 16 or ci_register_count = 32 report "INCORECT REGISTER SIZE" severity error;

	gen_hw_backup_gpr: if gb_GPR_HW_BACKUP = true generate
		assert false report "*** Hardware backup register file selected ***" severity warning;

		proc_gp_register_file : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				for ii in 0 to ci_register_count - 1 loop
					stav_sys_gpr(ii)     <= gv_RESET_VAL;
					stav_irq_sys_gpr(ii) <= gv_RESET_VAL;
				end loop;
			elsif rising_edge(pil_clk) then
				if pil_we = cl_ENABLE and pitv_waddr_rd /= "00000" then
					--- write always ---
					stav_irq_sys_gpr(to_integer(unsigned(pitv_waddr_rd))) <= piv_wdata;
				end if;

				if pil_we = cl_ENABLE and pil_irq_regfile_sel = cl_DISABLE and pitv_waddr_rd /= "00000" then
					--- write only during normal code execution ---
					stav_sys_gpr(to_integer(unsigned(pitv_waddr_rd))) <= piv_wdata;
				end if;
			end if;
		end process proc_gp_register_file;

		pov_rdata_rs1 <= stav_sys_gpr(to_integer(unsigned(pitv_raddr_rs1))) when pil_irq_regfile_sel = cl_DISABLE else
			stav_irq_sys_gpr(to_integer(unsigned(pitv_raddr_rs1)));

		pov_rdata_rs2 <= stav_sys_gpr(to_integer(unsigned(pitv_raddr_rs2))) when pil_irq_regfile_sel = cl_DISABLE else
			stav_irq_sys_gpr(to_integer(unsigned(pitv_raddr_rs2)));
	else gen_regular_gpr: generate
		assert false report "*** Regular register file selected ***" severity warning;

		proc_gp_register_file : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				for ii in 0 to ci_register_count - 1 loop
					stav_sys_gpr(ii) <= gv_RESET_VAL;
				end loop;
			elsif rising_edge(pil_clk) then
				if pil_we = cl_ENABLE and pitv_waddr_rd /= "00000" then
					stav_sys_gpr(to_integer(unsigned(pitv_waddr_rd))) <= piv_wdata;
				end if;
			end if;
		end process proc_gp_register_file;

		pov_rdata_rs1 <= stav_sys_gpr(to_integer(unsigned(pitv_raddr_rs1)));
		pov_rdata_rs2 <= stav_sys_gpr(to_integer(unsigned(pitv_raddr_rs2)));
	end generate;

end architecture rtl;