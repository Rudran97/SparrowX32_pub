library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity data_forward_mux_reg is
	port (
		piv_src_mux         : in std_logic_vector(2 downto 0);
		piv_write_ctrl_cond : in std_logic_vector(3 downto 0) := "0000"; --- 3 -> write control after wb, 2 -> write control at ma, 1 -> write control at exe, 0 -> write control for Load Inst.
		piv_ifid_addr       : in std_logic_vector(31 downto 0);
		piv_rsrc1           : in std_logic_vector(31 downto 0);
		piv_rsrc2           : in std_logic_vector(31 downto 0);
		piv_ifid_imm        : in std_logic_vector(31 downto 0);
		piv_exe_src         : in std_logic_vector(31 downto 0);
		piv_ma_src          : in std_logic_vector(31 downto 0);
		piv_ma_ld_src       : in std_logic_vector(31 downto 0);
		piv_wb_src          : in std_logic_vector(31 downto 0);
		piv_rd_exe_addr     : in std_logic_vector(4 downto 0);
		piv_rd_ma_addr      : in std_logic_vector(4 downto 0);
		piv_rd_wb_addr      : in std_logic_vector(4 downto 0);
		piv_ifid_src_raddr  : in std_logic_vector(9 downto 0); --- rs2, rs1
		pov_src1            : out std_logic_vector(31 downto 0);
		pov_src2            : out std_logic_vector(31 downto 0);
		pov_fw_rsrc2        : out std_logic_vector(31 downto 0)
	);
end entity data_forward_mux_reg;

architecture rtl of data_forward_mux_reg is

	constant ci_wb_cond    : integer := 3;
	constant ci_ma_cond    : integer := 2;
	constant ci_exe_cond   : integer := 1;
	constant ci_ma_ld_cond : integer := 0;

	constant ci_rs1_l : integer := 0;
	constant ci_rs1_u : integer := 4;
	constant ci_rs2_l : integer := 5;
	constant ci_rs2_u : integer := 9;

	signal sv_src1     : std_logic_vector(pov_src1'length - 1 downto 0);
	signal sv_src2     : std_logic_vector(pov_src2'length - 1 downto 0);
	signal sv_fw_rsrc2 : std_logic_vector(pov_src2'length - 1 downto 0);

begin

	proc_alu_src1_mux : process (piv_write_ctrl_cond, piv_ifid_src_raddr, piv_rd_exe_addr, piv_rd_ma_addr, piv_rd_wb_addr, piv_exe_src, piv_ma_src, piv_ma_ld_src, piv_wb_src, piv_rsrc1, piv_src_mux, piv_ifid_addr) is
	begin
		if piv_write_ctrl_cond(ci_exe_cond) = cl_ENABLE and piv_ifid_src_raddr(ci_rs1_u downto ci_rs1_l) /= "00000" and piv_ifid_src_raddr(ci_rs1_u downto ci_rs1_l) = piv_rd_exe_addr then
			sv_src1 <= piv_exe_src;
		elsif piv_write_ctrl_cond(ci_ma_ld_cond) = cl_ENABLE and piv_ifid_src_raddr(ci_rs1_u downto ci_rs1_l) /= "00000" and piv_ifid_src_raddr(ci_rs1_u downto ci_rs1_l) = piv_rd_ma_addr then
			sv_src1 <= piv_ma_ld_src;
		elsif piv_write_ctrl_cond(ci_ma_cond) = cl_ENABLE and piv_ifid_src_raddr(ci_rs1_u downto ci_rs1_l) /= "00000" and piv_ifid_src_raddr(ci_rs1_u downto ci_rs1_l) = piv_rd_ma_addr then
			sv_src1 <= piv_ma_src;
		elsif piv_write_ctrl_cond(ci_wb_cond) = cl_ENABLE and piv_ifid_src_raddr(ci_rs1_u downto ci_rs1_l) /= "00000" and piv_ifid_src_raddr(ci_rs1_u downto ci_rs1_l) = piv_rd_wb_addr then
			sv_src1 <= piv_wb_src;
		else
			sv_src1 <= piv_rsrc1;
		end if;

		if piv_src_mux = ctr_MUX_alu.src1_src2_auipc then
			sv_src1 <= (others => '0');
			sv_src1 <= piv_ifid_addr;
		end if;
	end process proc_alu_src1_mux;

	proc_alu_src2_mux : process (piv_write_ctrl_cond, piv_ifid_src_raddr, piv_rd_exe_addr, piv_rd_ma_addr, piv_rd_wb_addr, piv_exe_src, piv_ma_src, piv_ma_ld_src, piv_wb_src, piv_rsrc2, piv_src_mux, piv_ifid_imm) is
	begin
		if piv_write_ctrl_cond(ci_exe_cond) = cl_ENABLE and piv_ifid_src_raddr(ci_rs2_u downto ci_rs2_l) /= "00000" and piv_ifid_src_raddr(ci_rs2_u downto ci_rs2_l) = piv_rd_exe_addr then
			sv_src2     <= piv_exe_src;
			sv_fw_rsrc2 <= piv_exe_src;
		elsif piv_write_ctrl_cond(ci_ma_ld_cond) = cl_ENABLE and piv_ifid_src_raddr(ci_rs2_u downto ci_rs2_l) /= "00000" and piv_ifid_src_raddr(ci_rs2_u downto ci_rs2_l) = piv_rd_ma_addr then
			sv_src2     <= piv_ma_ld_src;
			sv_fw_rsrc2 <= piv_ma_ld_src;
		elsif piv_write_ctrl_cond(ci_ma_cond) = cl_ENABLE and piv_ifid_src_raddr(ci_rs2_u downto ci_rs2_l) /= "00000" and piv_ifid_src_raddr(ci_rs2_u downto ci_rs2_l) = piv_rd_ma_addr then
			sv_src2     <= piv_ma_src;
			sv_fw_rsrc2 <= piv_ma_src;
		elsif piv_write_ctrl_cond(ci_wb_cond) = cl_ENABLE and piv_ifid_src_raddr(ci_rs2_u downto ci_rs2_l) /= "00000" and piv_ifid_src_raddr(ci_rs2_u downto ci_rs2_l) = piv_rd_wb_addr then
			sv_src2     <= piv_wb_src;
			sv_fw_rsrc2 <= piv_wb_src;
		else
			sv_src2     <= piv_rsrc2;
			sv_fw_rsrc2 <= piv_rsrc2;
		end if;

		case piv_src_mux is
			when ctr_MUX_alu.src2_I_imm =>
				sv_src2 <= (31 downto 12 => piv_ifid_imm(ci_IF_funct7_u)) & piv_ifid_imm(ci_IF_I_imm_u downto ci_IF_I_imm_l);
			when ctr_MUX_alu.src2_S_imm =>
				sv_src2 <= (31 downto 12 => piv_ifid_imm(ci_IF_funct7_u)) & piv_ifid_imm(ci_IF_S_immu_u downto ci_IF_S_immu_l) & piv_ifid_imm(ci_IF_S_imml_u downto ci_IF_S_imml_l);
			when ctr_MUX_alu.src2_U_imm | ctr_MUX_alu.src1_src2_auipc =>
				sv_src2 <= piv_ifid_imm(ci_IF_U_imm_u downto ci_IF_U_imm_l) & X"000";
			when others =>
		end case;
	end process proc_alu_src2_mux;

	pov_src1     <= sv_src1;
	pov_src2     <= sv_src2;
	pov_fw_rsrc2 <= sv_fw_rsrc2;

end architecture rtl;
