library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity id_unit is
	generic (
		gb_EXT_M         : boolean := true;
		gb_GPR_HW_BACKUP : boolean := false;
		gb_RV32_E        : boolean := false
	);
	port (
		pil_clk                 : in std_logic;
		pil_rst                 : in std_logic;
		pitr_id_inst            : in tr_IF_base_format;
		piv_id_addr             : in std_logic_vector(31 downto 0);

		--- register file forwards ---
		pil_irq_regfile_sel     : in std_logic;
		pil_we                  : in std_logic;
		pitv_waddr_rd           : in tv_reg_size;
		piv_wdata               : in std_logic_vector(31 downto 0);

		--- forward unit signals / data ---
		piv_dfu_write_ctrl_cond : in std_logic_vector(3 downto 0); -- 3 -> write control after wb, 2 -> write control at ma, 1 -> write control at exe, 0 -> write control for Load Inst.
		piv_dfu_exe_src         : in std_logic_vector(31 downto 0);
		piv_dfu_ma_src          : in std_logic_vector(31 downto 0);
		piv_dfu_ma_ld_src       : in std_logic_vector(31 downto 0);
		piv_dfu_wb_src          : in std_logic_vector(31 downto 0);
		pitv_dfu_exe_rd_addr    : in tv_reg_size;
		pitv_dfu_ma_rd_addr     : in tv_reg_size;
		pitv_dfu_wb_rd_addr     : in tv_reg_size;

		--- ID stage output ---
		pov_id_intalu_op        : out std_logic_vector(3 downto 0);
		pov_id_md_op            : out std_logic_vector(2 downto 0);
		pov_id_csr_op           : out std_logic_vector(2 downto 0);
		potr_id_cpu_ctrl        : out tr_CS_CPU;
		pov_id_src1             : out std_logic_vector(31 downto 0);
		pov_id_src2             : out std_logic_vector(31 downto 0);
		pov_id_fw_rsrc2         : out std_logic_vector(31 downto 0);
		pol_id_illegal_inst     : out std_logic;

		--- Debug GPR access interface ---
		pil_gpr_access_req      : in std_logic;
		piv_gpr_access_addr     : in std_logic_vector(4 downto 0);
		pil_gpr_access_wen      : in std_logic;
		piv_gpr_access_wdata    : in std_logic_vector(31 downto 0);
		pov_gpr_access_rdata    : out std_logic_vector(31 downto 0)
	);
end entity;

architecture rtl of id_unit is

	--- signals decalred for decoder unit ---
	signal sv_id_intalu_op    : std_logic_vector(3 downto 0);
	signal sv_id_md_op        : std_logic_vector(2 downto 0);
	signal sv_id_csr_op       : std_logic_vector(2 downto 0);
	signal sl_id_illegal_inst : std_logic;
	signal str_id_cpu_ctrl    : tr_CS_CPU;

	--- signals declared for regsiter file ---
	signal sl_wen_rd          : std_logic;
	signal stv_raddr_rs1      : tv_reg_size;
	signal stv_raddr_rs2      : tv_reg_size;
	signal stv_waddr_rd       : tv_reg_size;
	signal sv_wdata_rd        : std_logic_vector(31 downto 0);
	signal sv_rsrc1           : std_logic_vector(31 downto 0);
	signal sv_rsrc2           : std_logic_vector(31 downto 0);

	--- signals declared for data forwarding unit ---
	signal sv_dfu_src_mux     : std_logic_vector(2 downto 0);
	signal sv_dfu_rsrc1       : std_logic_vector(31 downto 0);
	signal sv_dfu_rsrc2       : std_logic_vector(31 downto 0);
	signal sv_dfu_id_imm      : std_logic_vector(31 downto 0);
	signal sv_ifid_src_raddr  : std_logic_vector(9 downto 0);
	signal sv_dfu_src1_out    : std_logic_vector(31 downto 0);
	signal sv_dfu_src2_out    : std_logic_vector(31 downto 0);
	signal sv_dfu_fw_rsrc2    : std_logic_vector(31 downto 0);

begin

	inst_decoder : entity work.decoder
		generic map(
			gb_EXT_M          => gb_EXT_M
		)
		port map(
			pitr_dec_inst     => pitr_id_inst,
			pov_dec_intalu_op => sv_id_intalu_op,
			pov_dec_md_op     => sv_id_md_op,
			pov_dec_csr_op    => sv_id_csr_op,
			pol_illegal_inst  => sl_id_illegal_inst,
			potr_dec_cpu_ctrl => str_id_cpu_ctrl
		);

	sl_wen_rd     <= pil_gpr_access_wen when pil_gpr_access_req = cl_ENABLE else
		pil_we;
	stv_raddr_rs1 <= piv_gpr_access_addr when pil_gpr_access_req = cl_ENABLE else
		pitr_id_inst.v_reg_rs1;
	stv_raddr_rs2 <= pitr_id_inst.v_reg_rs2;
	stv_waddr_rd  <= piv_gpr_access_addr when pil_gpr_access_req = cl_ENABLE else
		pitv_waddr_rd;
	sv_wdata_rd   <= piv_gpr_access_wdata when pil_gpr_access_req = cl_ENABLE else
		piv_wdata;

	inst_register_file : entity work.sys_register_file
		generic map (
			gb_RV32_E        => gb_RV32_E,
			gb_GPR_HW_BACKUP => gb_GPR_HW_BACKUP
		)
		port map(
			pil_clk             => pil_clk,
			pil_rst             => pil_rst,
			pil_we              => sl_wen_rd,
			pil_irq_regfile_sel => pil_irq_regfile_sel,
			pitv_raddr_rs1      => stv_raddr_rs1,
			pitv_raddr_rs2      => stv_raddr_rs2,
			pitv_waddr_rd       => stv_waddr_rd,
			piv_wdata           => sv_wdata_rd,
			pov_rdata_rs1       => sv_rsrc1,
			pov_rdata_rs2       => sv_rsrc2
		);

	sv_dfu_src_mux <= str_id_cpu_ctrl.tr_id_stage.v_alu_src_mux;
	sv_dfu_rsrc1   <= sv_rsrc1;
	sv_dfu_rsrc2   <= sv_rsrc2;

	sv_dfu_id_imm     <= fv_inst_rec2slv(instruction => pitr_id_inst);
	sv_ifid_src_raddr <= pitr_id_inst.v_reg_rs2 & pitr_id_inst.v_reg_rs1;

	inst_data_forward_mux_reg : entity work.data_forward_mux_reg
		port map(
			piv_src_mux         => sv_dfu_src_mux,
			piv_write_ctrl_cond => piv_dfu_write_ctrl_cond,
			piv_ifid_addr       => piv_id_addr,
			piv_rsrc1           => sv_dfu_rsrc1,
			piv_rsrc2           => sv_dfu_rsrc2,
			piv_ifid_imm        => sv_dfu_id_imm,
			piv_exe_src         => piv_dfu_exe_src,
			piv_ma_src          => piv_dfu_ma_src,
			piv_ma_ld_src       => piv_dfu_ma_ld_src,
			piv_wb_src          => piv_dfu_wb_src,
			piv_rd_exe_addr     => pitv_dfu_exe_rd_addr,
			piv_rd_ma_addr      => pitv_dfu_ma_rd_addr,
			piv_rd_wb_addr      => pitv_dfu_wb_rd_addr,
			piv_ifid_src_raddr  => sv_ifid_src_raddr,
			pov_src1            => sv_dfu_src1_out,
			pov_src2            => sv_dfu_src2_out,
			pov_fw_rsrc2        => sv_dfu_fw_rsrc2
		);

	pov_id_intalu_op     <= sv_id_intalu_op;
	pov_id_md_op         <= sv_id_md_op;
	pov_id_csr_op        <= sv_id_csr_op;
	potr_id_cpu_ctrl     <= str_id_cpu_ctrl;
	pov_id_src1          <= sv_dfu_src1_out;
	pov_id_src2          <= sv_dfu_src2_out;
	pov_id_fw_rsrc2      <= sv_dfu_fw_rsrc2;
	pol_id_illegal_inst  <= sl_id_illegal_inst;
	
	pov_gpr_access_rdata <= sv_rsrc1;

end architecture;