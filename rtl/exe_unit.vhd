library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity exe_unit is
    generic (
        gb_EXT_M               : boolean          := true;
        gb_EXT_C               : boolean          := true;
        gv_reg_MVENDORID       : std_logic_vector := X"0000_0000";
        gv_reg_MARCHID         : std_logic_vector := X"0600_A033";
        gv_reg_MIMPID          : std_logic_vector := X"0001_0001";
        gv_reg_MHARTID         : std_logic_vector := X"0000_0001";
        gb_RISCV_FORMAL_ALTOPS : boolean          := false
    );
    port (
        pil_clk                   : in std_logic;
        pil_rst                   : in std_logic;
        pil_valid_inst            : in std_logic;
        pil_exe_halt              : in std_logic;
        pitr_exe_inst             : in tr_IF_base_format;
        piv_exe_addr              : in std_logic_vector(31 downto 0);
        piv_exe_intalu_op         : in std_logic_vector(3 downto 0);
        piv_exe_md_op             : in std_logic_vector(2 downto 0);
        piv_exe_csr_op            : in std_logic_vector(2 downto 0);
        piv_src_op1               : in std_logic_vector(31 downto 0);
        piv_src_op2               : in std_logic_vector(31 downto 0);
        pitr_exe_ctrl             : in tr_CS_EXE;

        --- EXE stage output ---
        pol_exe_branch_taken      : out std_logic;
        pol_exe_busy              : out std_logic;
        pov_exe_intalu_result     : out std_logic_vector(31 downto 0);
        pov_exe_result            : out std_logic_vector(31 downto 0);

        --- Exposed csr ---
        pil_exe_ctrl_mepc_wen     : in std_logic;
        piv_exe_ctrl_mepc         : in std_logic_vector(31 downto 0);
        pil_exe_ctrl_mtval_wen    : in std_logic;
        piv_exe_ctrl_mtval        : in std_logic_vector(31 downto 0);
        pil_exe_ctrl_minstret_wen : in std_logic;
        piv_exe_ctrl_minstret     : in std_logic_vector(31 downto 0);
        pil_exe_ctrl_mstatus_wen  : in std_logic;
        piv_exe_ctrl_mstatus      : in std_logic_vector(7 downto 0);
        pil_exe_ctrl_mcause_wen   : in std_logic;
        piv_exe_ctrl_mcause       : in std_logic_vector(31 downto 0);
        piv_exe_ctrl_mip          : in std_logic_vector(11 downto 0);
        pil_csr_ctrl_dcsr_wen     : in std_logic;
        piv_csr_ctrl_dcsr         : in std_logic_vector(31 downto 0);
        pil_csr_ctrl_dpc_wen      : in std_logic;
        piv_csr_ctrl_dpc          : in std_logic_vector(31 downto 0);

        pil_csr_halt_bypass       : in std_logic;
        pil_csr_wen               : in std_logic;
        piv_csr_waddr             : in std_logic_vector(11 downto 0);
        piv_csr_wdata             : in std_logic_vector(31 downto 0);
        potr_csr                  : out tr_CSR;
        pov_csr_modify            : out std_logic_vector(31 downto 0);

        pol_exe_trigger_match     : out std_logic;

		--- Debug CSR access interface ---
		pil_csr_access_req        : in std_logic;
		piv_csr_access_addr       : in std_logic_vector(11 downto 0);
		pil_csr_access_wen        : in std_logic;
		piv_csr_access_wdata      : in std_logic_vector(31 downto 0);
		pov_csr_access_rdata      : out std_logic_vector(31 downto 0);
        pol_csr_access_err        : out std_logic
    );
end entity exe_unit;

architecture rtl of exe_unit is

    constant cv_flow_cond_EQ     : std_logic_vector(2 downto 0) := "000";
    constant cv_flow_cond_NE     : std_logic_vector(2 downto 0) := "001";
    constant cv_flow_cond_LT     : std_logic_vector(2 downto 0) := "100";
    constant cv_flow_cond_GE     : std_logic_vector(2 downto 0) := "101";
    constant cv_flow_cond_LTU    : std_logic_vector(2 downto 0) := "110";
    constant cv_flow_cond_GEU    : std_logic_vector(2 downto 0) := "111";

    --- intalu unit ---
    signal sl_int_alu_busy       : std_logic;
    signal str_int_alu_flag      : tr_SF_CPU;
    signal sv_int_alu_res        : std_logic_vector(31 downto 0);

    --- mul div unit ---
    signal sl_int_md_halt        : std_logic;
    signal sv_int_md_op          : std_logic_vector(3 downto 0);
    signal sv_int_md_out         : std_logic_vector(31 downto 0);
    signal sl_int_md_busy        : std_logic;

    --- csr unit ---
    signal sl_csr_wen            : std_logic;
    signal sv_csr_op             : std_logic_vector(1 downto 0);
    signal sv_csr_raddr          : std_logic_vector(11 downto 0);
    signal sv_csr_src_data       : std_logic_vector(31 downto 0);
    signal sv_csr_rdata          : std_logic_vector(31 downto 0);
    signal sv_csr_modify         : std_logic_vector(31 downto 0);
    signal sv_csr_waddr          : std_logic_vector(11 downto 0);
    signal sv_csr_wdata          : std_logic_vector(31 downto 0);
    signal sl_csr_illegal_access : std_logic;

    signal str_csr               : tr_CSR;

    signal sl_exe_branch_taken   : std_logic;
    signal sl_trigger_match      : std_logic;

begin

    inst_int_alu : entity work.int_alu
        port map(
            piv_int_alu_oper  => piv_exe_intalu_op,
            piv_int_alu_op1   => piv_src_op1,
            piv_int_alu_op2   => piv_src_op2,
            pol_int_alu_busy  => sl_int_alu_busy,
            potr_int_alu_flag => str_int_alu_flag,
            pov_int_alu_res   => sv_int_alu_res
        );

    sv_int_md_op <= pitr_exe_ctrl.l_md_EN & piv_exe_md_op;

    gen_mul_div_module : if gb_EXT_M = true generate
        assert false report "*** Hardware MULTIPLIER and DIVIDE module Added ***" severity warning;
        sl_int_md_halt <= pil_exe_halt or not pil_valid_inst;

        inst_int_mul_div : entity work.int_mul_div
            generic map(
                gb_RISCV_FORMAL_ALTOPS => gb_RISCV_FORMAL_ALTOPS
            )
            port map(
                pil_clk          => pil_clk,
                pil_rst          => pil_rst,
                pil_int_md_halt  => sl_int_md_halt,
                piv_int_md_oper  => sv_int_md_op,
                piv_int_md_temp1 => piv_src_op1,
                piv_int_md_temp2 => piv_src_op2,
                pov_int_md_out   => sv_int_md_out,
                pol_int_md_busy  => sl_int_md_busy
            );
    end generate;

    sl_csr_wen      <= pil_csr_access_wen when pil_csr_access_req = cl_ENABLE else
        pil_csr_wen when pil_csr_halt_bypass = cl_ENABLE else
        pil_csr_wen and not pil_exe_halt;
    sv_csr_op       <= piv_exe_csr_op(1 downto 0);
    sv_csr_raddr    <= piv_csr_access_addr when pil_csr_access_req = cl_ENABLE else
        pitr_exe_inst.v_funct7 & pitr_exe_inst.v_reg_rs2;
    sv_csr_waddr    <= piv_csr_access_addr when pil_csr_access_req = cl_ENABLE else
        piv_csr_waddr;
    sv_csr_src_data <= (31 downto 5 => '0') & pitr_exe_inst.v_reg_rs1 when piv_exe_csr_op(2) = cl_ENABLE else
        piv_src_op1;
    sv_csr_wdata    <= piv_csr_access_wdata when pil_csr_access_req = cl_ENABLE else
        piv_csr_wdata;

    inst_csr : entity work.csr_op_unit
        generic map(
            gb_EXT_M         => gb_EXT_M,
            gb_EXT_C         => gb_EXT_C,
            gv_reg_MVENDORID => gv_reg_MVENDORID,
            gv_reg_MARCHID   => gv_reg_MARCHID,
            gv_reg_MIMPID    => gv_reg_MIMPID,
            gv_reg_MHARTID   => gv_reg_MHARTID
        )
        port map(
            pil_clk                   => pil_clk,
            pil_rst                   => pil_rst,
            piv_exe_addr              => piv_exe_addr,
            piv_csr_op                => sv_csr_op,
            piv_csr_src_data          => sv_csr_src_data,
            piv_csr_raddr             => sv_csr_raddr,
            pov_csr_rdata             => sv_csr_rdata,
            pil_csr_wen               => sl_csr_wen,
            piv_csr_waddr             => sv_csr_waddr,
            piv_csr_wdata             => sv_csr_wdata,
            pov_csr_modify            => sv_csr_modify,
            pol_csr_illegal_access    => sl_csr_illegal_access,
            pol_trigger_match         => sl_trigger_match,
            pil_csr_ctrl_mepc_wen     => pil_exe_ctrl_mepc_wen,
            piv_csr_ctrl_mepc         => piv_exe_ctrl_mepc,
            pil_csr_ctrl_mtval_wen    => pil_exe_ctrl_mtval_wen,
            piv_csr_ctrl_mtval        => piv_exe_ctrl_mtval,
            pil_csr_ctrl_minstret_wen => pil_exe_ctrl_minstret_wen,
            piv_csr_ctrl_minstret     => piv_exe_ctrl_minstret,
            pil_csr_ctrl_mstatus_wen  => pil_exe_ctrl_mstatus_wen,
            piv_csr_ctrl_mstatus      => piv_exe_ctrl_mstatus,
            pil_csr_ctrl_mcause_wen   => pil_exe_ctrl_mcause_wen,
            piv_csr_ctrl_mcause       => piv_exe_ctrl_mcause,
            piv_csr_ctrl_mip          => piv_exe_ctrl_mip,
            pil_csr_ctrl_dcsr_wen     => pil_csr_ctrl_dcsr_wen,
            piv_csr_ctrl_dcsr         => piv_csr_ctrl_dcsr,
            pil_csr_ctrl_dpc_wen      => pil_csr_ctrl_dpc_wen,
            piv_csr_ctrl_dpc          => piv_csr_ctrl_dpc,
            potr_csr                  => str_csr
        );

    proc_branch_decision : process (pitr_exe_inst, str_int_alu_flag)
    begin
        sl_exe_branch_taken <= cl_DISABLE;
        case pitr_exe_inst.v_opcode is
            when cv_IC_SB =>
                case pitr_exe_inst.v_funct3 is
                    when cv_flow_cond_EQ =>
                        sl_exe_branch_taken <= str_int_alu_flag.int_alu_ZF;
                    when cv_flow_cond_NE =>
                        sl_exe_branch_taken <= not str_int_alu_flag.int_alu_ZF;
                    when cv_flow_cond_LT =>
                        sl_exe_branch_taken <= str_int_alu_flag.int_alu_VF xor str_int_alu_flag.int_alu_NF;
                    when cv_flow_cond_GE =>
                        sl_exe_branch_taken <= not (str_int_alu_flag.int_alu_VF xor str_int_alu_flag.int_alu_NF);
                    when cv_flow_cond_LTU =>
                        sl_exe_branch_taken <= str_int_alu_flag.int_alu_CF;
                    when cv_flow_cond_GEU =>
                        sl_exe_branch_taken <= not str_int_alu_flag.int_alu_CF;
                    when others =>
                        sl_exe_branch_taken <= cl_DISABLE;
                end case;
            when cv_IC_I_JALR | cv_IC_J =>
                sl_exe_branch_taken <= cl_ENABLE;
            when others =>
                sl_exe_branch_taken <= cl_DISABLE;
        end case;
    end process proc_branch_decision;

    pol_exe_busy <= sl_int_md_busy when pitr_exe_ctrl.l_md_EN = cl_ENABLE else
        sl_int_alu_busy;

    pov_exe_intalu_result <= sv_int_alu_res;

    pov_exe_result <= sv_int_md_out when pitr_exe_ctrl.l_md_EN = cl_ENABLE else
        sv_csr_rdata when pitr_exe_ctrl.l_csr_EN = cl_ENABLE else
        sv_int_alu_res;

    pol_exe_branch_taken <= sl_exe_branch_taken;

    potr_csr              <= str_csr;
    pov_csr_modify        <= sv_csr_modify;
    pol_exe_trigger_match <= sl_trigger_match;
    pov_csr_access_rdata  <= sv_csr_rdata;
    pol_csr_access_err    <= sl_csr_illegal_access;

end architecture;
