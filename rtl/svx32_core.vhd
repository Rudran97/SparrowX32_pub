library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.options_pkg.all;

use work.core_pkg.all;
use work.if_id_pkg.all;
use work.id_exe_pkg.all;
use work.exe_ma_pkg.all;
use work.ma_wb_pkg.all;
use work.csr_op_unit_pkg.all;

entity svx32_core is
    port (
        pil_clk                  : in std_logic;
        pil_rst                  : in std_logic;
        pil_run_prg              : in std_logic;
        pol_next_inst            : out std_logic;
        pol_ben                  : out std_logic;

        --- Instruction fetch signals ---
        pil_fetch_mem_valid      : in std_logic;
        pil_fetch_mem_ack        : in std_logic;
        pol_fetch_mem_req        : out std_logic;
        piv_fetch_mem_rdata      : in std_logic_vector(31 downto 0);
        pov_fetch_mem_addr       : out std_logic_vector(31 downto 0);

        --- Mem unit signals ---
        pil_mem_valid            : in std_logic;
        pil_mem_ack              : in std_logic;
        pol_mem_req              : out std_logic;
        pol_mem_wen              : out std_logic;

        piv_mem_rdata            : in std_logic_vector(31 downto 0);
        pov_mem_wdata            : out std_logic_vector(31 downto 0);
        pov_mem_addr             : out std_logic_vector(31 downto 0);
        pov_mem_byte_sel         : out std_logic_vector(3 downto 0);

        --- IRQs ---
        pil_soft_irq             : in std_logic;
        pil_timer_irq            : in std_logic;
        pil_ext_irq              : in std_logic;

        pil_fast_irq             : in std_logic;
        piv_fast_irq_id          : in std_logic_vector(3 downto 0);
        piv_fast_irq_vect        : in std_logic_vector(31 downto 0);

        pol_irq_pending          : out std_logic;

        --- Debug Input/Outputs ---
        pil_debug_haltreq        : in std_logic                       := cl_DISABLE;
        pil_debug_resumereq      : in std_logic                       := cl_DISABLE;
        pol_debug_havereset      : out std_logic;
        pol_debug_running        : out std_logic;
        pol_debug_halted         : out std_logic;
        pov_debug_pc_retired     : out std_logic_vector(31 downto 0);

        --- Debug abstract reg/CSR access ---
        pil_debug_regreq         : in std_logic                       := cl_DISABLE;
        piv_debug_regno          : in std_logic_vector(11 downto 0)   := (others => '0');
        pil_debug_write          : in std_logic                       := cl_DISABLE;
        piv_debug_wdata          : in std_logic_vector(31 downto 0)   := (others => '0');
        pov_debug_rdata          : out std_logic_vector(31 downto 0);
        pol_debug_ack            : out std_logic;
        pol_debug_err            : out std_logic;

        --- Risc-v formal interface ---
        rvfi_valid               : out std_logic;
        rvfi_order               : out std_logic_vector(63 downto 0);
        rvfi_insn                : out std_logic_vector(31 downto 0);
        rvfi_trap                : out std_logic;
        rvfi_halt                : out std_logic;
        rvfi_intr                : out std_logic;
        rvfi_mode                : out std_logic_vector(1 downto 0);
        rvfi_ixl                 : out std_logic_vector(1 downto 0);
        rvfi_rs1_addr            : out std_logic_vector(4 downto 0);
        rvfi_rs2_addr            : out std_logic_vector(4 downto 0);
        rvfi_rs1_rdata           : out std_logic_vector(31 downto 0);
        rvfi_rs2_rdata           : out std_logic_vector(31 downto 0);
        rvfi_rd_addr             : out std_logic_vector(4 downto 0);
        rvfi_rd_wdata            : out std_logic_vector(31 downto 0);
        rvfi_pc_rdata            : out std_logic_vector(31 downto 0);
        rvfi_pc_wdata            : out std_logic_vector(31 downto 0);
        rvfi_mem_addr            : out std_logic_vector(31 downto 0);
        rvfi_mem_rmask           : out std_logic_vector(3 downto 0);
        rvfi_mem_wmask           : out std_logic_vector(3 downto 0);
        rvfi_mem_rdata           : out std_logic_vector(31 downto 0);
        rvfi_mem_wdata           : out std_logic_vector(31 downto 0);

        rvfi_csr_misa_rmask      : out std_logic_vector(31 downto 0);
        rvfi_csr_misa_wmask      : out std_logic_vector(31 downto 0);
        rvfi_csr_misa_rdata      : out std_logic_vector(31 downto 0);
        rvfi_csr_misa_wdata      : out std_logic_vector(31 downto 0);

        rvfi_csr_mvendorid_rmask : out std_logic_vector(31 downto 0);
        rvfi_csr_mvendorid_wmask : out std_logic_vector(31 downto 0);
        rvfi_csr_mvendorid_rdata : out std_logic_vector(31 downto 0);
        rvfi_csr_mvendorid_wdata : out std_logic_vector(31 downto 0);

        rvfi_csr_marchid_rmask   : out std_logic_vector(31 downto 0);
        rvfi_csr_marchid_wmask   : out std_logic_vector(31 downto 0);
        rvfi_csr_marchid_rdata   : out std_logic_vector(31 downto 0);
        rvfi_csr_marchid_wdata   : out std_logic_vector(31 downto 0);

        rvfi_csr_mimpid_rmask    : out std_logic_vector(31 downto 0);
        rvfi_csr_mimpid_wmask    : out std_logic_vector(31 downto 0);
        rvfi_csr_mimpid_rdata    : out std_logic_vector(31 downto 0);
        rvfi_csr_mimpid_wdata    : out std_logic_vector(31 downto 0);

        rvfi_csr_mstatus_rmask   : out std_logic_vector(31 downto 0);
        rvfi_csr_mstatus_wmask   : out std_logic_vector(31 downto 0);
        rvfi_csr_mstatus_rdata   : out std_logic_vector(31 downto 0);
        rvfi_csr_mstatus_wdata   : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of svx32_core is

    --- signals declared for IF Stage ---
    signal sl_is_compressed           : std_logic;
    signal sl_illegal_compressed_inst : std_logic;
    signal sv_rvfi_compressed_isnt    : std_logic_vector(31 downto 0);
    signal str_inst                   : tr_IF_base_format;
    signal sl_if_pipe_start           : std_logic;
    signal sl_next_stage_ready        : std_logic;
    signal sl_fetch_en                : std_logic;
    signal sl_insn_first_fetch        : std_logic;
    signal sl_insn_valid              : std_logic;
    signal sl_if_prefetch_stall       : std_logic;
    signal sl_if_ben                  : std_logic;
    signal sl_if_cen                  : std_logic;
    signal sv_if_baddr                : std_logic_vector(31 downto 0);
    signal sv_if_addr                 : std_logic_vector(31 downto 0);

    signal str_ifid_pipe_status_in  : tr_pipe_status;
    signal sl_if_halt               : std_logic;
    signal sl_if_mem_valid          : std_logic;
    signal sl_ifid_nop_inst         : std_logic;
    signal str_ifid_stage_reg_in    : tr_ifid_stage_reg;
    signal str_ifid_stage_reg_out   : tr_ifid_stage_reg;
    signal str_ifid_pipe_status_out : tr_pipe_status;

    --- signals declared for ID Stage ---
    signal str_id_inst            : tr_IF_base_format;
    signal sv_ifid_addr           : std_logic_vector(31 downto 0);
    signal sl_id_irq_regfile_sel  : std_logic;
    signal sl_regf_we             : std_logic;
    signal stv_regf_waddr_rd      : tv_reg_size;
    signal sv_regf_wdata          : std_logic_vector(31 downto 0);
    signal sv_dfu_write_ctrl_cond : std_logic_vector(3 downto 0);
    signal sv_dfu_exe_src         : std_logic_vector(31 downto 0);
    signal sv_dfu_ma_src          : std_logic_vector(31 downto 0);
    signal sv_dfu_ma_ld_src       : std_logic_vector(31 downto 0);
    signal sv_dfu_wb_src          : std_logic_vector(31 downto 0);
    signal stv_dfu_exe_rd_addr    : tv_reg_size;
    signal stv_dfu_ma_rd_addr     : tv_reg_size;
    signal stv_dfu_wb_rd_addr     : tv_reg_size;
    signal sv_id_intalu_op        : std_logic_vector(3 downto 0);
    signal sv_id_md_op            : std_logic_vector(2 downto 0);
    signal sv_id_csr_op           : std_logic_vector(2 downto 0);
    signal str_id_cpu_ctrl        : tr_CS_CPU;
    signal sv_id_rsrc1            : std_logic_vector(31 downto 0);
    signal sv_id_rsrc2            : std_logic_vector(31 downto 0);
    signal sv_id_fw_rsrc2         : std_logic_vector(31 downto 0);

    signal str_idexe_pipe_status_in  : tr_pipe_status;
    signal sl_id_halt                : std_logic;
    signal str_idexe_stage_reg_in    : tr_idexe_stage_reg;
    signal str_idexe_stage_reg_out   : tr_idexe_stage_reg;
    signal str_idexe_pipe_status_out : tr_pipe_status;
    signal sl_id_illegal_inst        : std_logic;
    signal sl_id_gpr_access_req      : std_logic;
    signal sv_id_gpr_access_addr     : std_logic_vector(4 downto 0);
    signal sl_id_gpr_access_wen      : std_logic;
    signal sv_id_gpr_access_wdata    : std_logic_vector(31 downto 0);
    signal sv_id_gpr_access_rdata    : std_logic_vector(31 downto 0);

    --- signals declared for EXE Stage ---
    signal str_exe_inst            : tr_IF_base_format;
    signal sv_exe_intalu_op        : std_logic_vector(3 downto 0);
    signal sv_exe_md_op            : std_logic_vector(2 downto 0);
    signal sv_exe_csr_op           : std_logic_vector(2 downto 0);
    signal sv_src_op1              : std_logic_vector(31 downto 0);
    signal sv_src_op2              : std_logic_vector(31 downto 0);
    signal str_exe_ctrl            : tr_CS_EXE;
    signal sl_exe_branch_taken     : std_logic;
    signal sl_exe_busy             : std_logic;
    signal sv_exe_intalu_result    : std_logic_vector(31 downto 0);
    signal sv_exe_result           : std_logic_vector(31 downto 0);
    signal sl_exe_mepc_wen         : std_logic;
    signal sv_exe_mepc             : std_logic_vector(31 downto 0);
    signal sl_exe_mtval_wen        : std_logic;
    signal sv_exe_mtval            : std_logic_vector(31 downto 0);
    signal sl_exe_minstret_wen     : std_logic;
    signal sv_exe_minstret         : std_logic_vector(31 downto 0);
    signal sl_exe_mstatus_wen      : std_logic;
    signal sv_exe_mstatus          : std_logic_vector(7 downto 0);
    signal sl_exe_mcause_wen       : std_logic;
    signal sv_exe_mcause           : std_logic_vector(31 downto 0);
    signal sv_exe_mip              : std_logic_vector(11 downto 0);
    signal sl_exe_dcsr_wen         : std_logic;
    signal sv_exe_dcsr             : std_logic_vector(31 downto 0);
    signal sl_exe_dpc_wen          : std_logic;
    signal sv_exe_dpc              : std_logic_vector(31 downto 0);
    signal sl_exe_csr_halt_bypass  : std_logic;
    signal sl_exe_csr_wen          : std_logic;
    signal sv_exe_csr_waddr        : std_logic_vector(11 downto 0);
    signal sv_exe_csr_wdata        : std_logic_vector(31 downto 0);
    signal str_exe_csr             : tr_CSR;
    signal sv_exe_csr_modify       : std_logic_vector(31 downto 0);
    signal sl_exe_trigger_match    : std_logic;
    signal sl_exe_csr_access_req   : std_logic;
    signal sv_exe_csr_access_addr  : std_logic_vector(11 downto 0);
    signal sl_exe_csr_access_wen   : std_logic;
    signal sv_exe_csr_access_wdata : std_logic_vector(31 downto 0);
    signal sv_exe_csr_access_rdata : std_logic_vector(31 downto 0);
    signal sl_exe_csr_access_err   : std_logic;

    signal str_exema_pipe_status_in  : tr_pipe_status;
    signal sl_exe_halt               : std_logic;
    signal sl_exe_unit_valid         : std_logic;
    signal str_exema_stage_reg_in    : tr_exema_stage_reg;
    signal str_exema_stage_reg_out   : tr_exema_stage_reg;
    signal str_exema_pipe_status_out : tr_pipe_status;

    ---signals decalred for data memory access stage ---
    signal sv_ma_mai_addr     : std_logic_vector(31 downto 0);
    signal sv_ma_mai_wdata    : std_logic_vector(31 downto 0);
    signal str_ma_ctrl        : tr_CS_MA;
    signal sl_ma_mem_req      : std_logic;
    signal sl_ma_mem_wen      : std_logic;
    signal sv_ma_mem_wdata    : std_logic_vector(31 downto 0);
    signal sv_ma_mem_addr     : std_logic_vector(31 downto 0);
    signal sv_ma_mem_byte_sel : std_logic_vector(3 downto 0);
    signal sv_ma_mai_rdata    : std_logic_vector(31 downto 0);
    signal sl_ma_ready        : std_logic;

    signal str_mawb_pipe_status_in  : tr_pipe_status;
    signal sl_ma_halt               : std_logic;
    signal sl_ma_unit_valid         : std_logic;
    signal str_mawb_stage_reg_in    : tr_mawb_stage_reg;
    signal str_mawb_stage_reg_out   : tr_mawb_stage_reg;
    signal str_mawb_pipe_status_out : tr_pipe_status;

    --- signals declared for register write back stage ---
    signal sv_wb_prog_addr : std_logic_vector(31 downto 0);
    signal sv_wb_reg_mux   : std_logic_vector(31 downto 0);
    signal sv_pc_retired   : std_logic_vector(31 downto 0);
    signal sl_instret_wen  : std_logic;
    signal sv_instret      : std_logic_vector(63 downto 0);

    --- signals declared for the main controller ---
    signal sl_ctrl_en                      : std_logic;
    signal sl_IALIGN_exc0                  : std_logic;
    signal sl_ILLINSN_exc2                 : std_logic;
    signal sl_BREAK_exc3                   : std_logic;
    signal sl_ECALL_exc11                  : std_logic;
    signal sv_exc_epc                      : std_logic_vector(31 downto 0);
    signal sv_exc_inst                     : std_logic_vector(31 downto 0);
    signal sv_ctrl_csr_MEPC                : std_logic_vector(31 downto 0);
    signal str_ctrl_csr_MSTATUS            : tr_csr_MSTATUS;
    signal str_ctrl_csr_MIE                : tr_csr_MIE;
    signal str_ctrl_csr_MTVEC              : tr_csr_MTVEC;
    signal str_ctrl_csr_DCSR               : tr_csr_DCSR;
    signal sv_ctrl_csr_DPC                 : std_logic_vector(31 downto 0);
    signal sl_ctrl_mepc_wen                : std_logic;
    signal sv_ctrl_mepc                    : std_logic_vector(31 downto 0);
    signal sl_ctrl_mtval_wen               : std_logic;
    signal sv_ctrl_mtval                   : std_logic_vector(31 downto 0);
    signal sl_ctrl_mstatus_wen             : std_logic;
    signal sv_ctrl_mstatus                 : std_logic_vector(31 downto 0);
    signal sl_ctrl_mcause_wen              : std_logic;
    signal sv_ctrl_mcause                  : std_logic_vector(31 downto 0);
    signal sv_ctrl_mip                     : std_logic_vector(31 downto 0);
    signal sl_ctrl_dcsr_wen                : std_logic;
    signal sv_ctrl_dcsr                    : std_logic_vector(31 downto 0);
    signal sl_ctrl_dpc_wen                 : std_logic;
    signal sv_ctrl_dpc                     : std_logic_vector(31 downto 0);
    signal sl_ctrl_rvfi_intr               : std_logic;
    signal sl_ctrl_exc_ben                 : std_logic;
    signal sv_ctrl_exc_baddr               : std_logic_vector(31 downto 0);
    signal sl_ctrl_irq_pin_pending         : std_logic;
    signal sl_ctrl_csr_halt_bypass         : std_logic;
    signal sl_ctrl_trigger_match           : std_logic;
    signal sl_ctrl_debug_mode              : std_logic;
    signal sl_ctrl_debug_havereset         : std_logic;
    signal sl_ctrl_debug_running           : std_logic;
    signal sl_ctrl_debug_halted            : std_logic;
    signal sl_ctrl_debug_ack               : std_logic;
    signal sl_ctrl_debug_err               : std_logic;
    signal sv_ctrl_debug_rdata             : std_logic_vector(31 downto 0);
    signal sl_ctrl_access_req              : std_logic;
    signal sv_ctrl_access_regno            : std_logic_vector(11 downto 0);
    signal sv_ctrl_access_gpr_rdata        : std_logic_vector(31 downto 0);
    signal sv_ctrl_access_csr_rdata        : std_logic_vector(31 downto 0);
    signal sl_ctrl_access_csr_err          : std_logic;
    signal sl_ctrl_access_gpr_wen          : std_logic;
    signal sl_ctrl_access_csr_wen          : std_logic;
    signal sv_ctrl_access_wdata            : std_logic_vector(31 downto 0);
    signal sl_ctrl_is_in_debug_mode        : std_logic;
    signal sl_ctrl_irq_regfile_sel         : std_logic;
    signal sl_ctrl_ignore_irq_regfile      : std_logic;
    signal sl_ctrl_pipe_start              : std_logic;
    signal sl_ctrl_illegal_inst_en_chk     : std_logic;
    signal sl_ctrl_rvfi_ld_hazard_end      : std_logic;
    signal stv_ctrl_ifid_rs1_addr          : tv_reg_size;
    signal stv_ctrl_ifid_rs2_addr          : tv_reg_size;
    signal stv_ctrl_idexe_rd_addr          : tv_reg_size;
    signal sl_ctrl_idexe_mem_req           : std_logic;
    signal sl_ctrl_idexe_mem_wen           : std_logic;
    signal sl_ctrl_prefetch_stall          : std_logic;
    signal sl_ctrl_if_cen                  : std_logic;
    signal sl_ctrl_ifid_nop_inst_in        : std_logic;
    signal sl_ctrl_if_stall                : std_logic;
    signal sl_ctrl_if_ben                  : std_logic;
    signal sv_ctrl_if_baddr                : std_logic_vector(31 downto 0);
    signal sl_ctrl_ifid_ready              : std_logic;
    signal sl_ctrl_ifid_nop_inst           : std_logic;
    signal sl_ctrl_idexe_nop_inst          : std_logic;
    signal sl_ctrl_step                    : std_logic;
    signal sl_ctrl_first_fetch             : std_logic;
    signal sv_ctrl_id_addr                 : std_logic_vector(31 downto 0);
    signal sl_ctrl_id_stall                : std_logic;
    signal sl_ignore_branch_at_exe         : std_logic;
    signal sl_ctrl_exe_stall               : std_logic;
    signal sv_ctrl_exe_addr                : std_logic_vector(31 downto 0);
    signal sv_ctrl_exe_inst                : std_logic_vector(31 downto 0);
    signal sl_ctrl_exe_is_valid_inst       : std_logic;
    signal sv_ctrl_exe_result              : std_logic_vector(31 downto 0);
    signal sl_ctrl_exe_boff_mux            : std_logic;
    signal sl_ctrl_exe_baddr_src_mux       : std_logic;
    signal sl_ctrl_exe_is_csr_inst         : std_logic;
    signal sl_ctrl_is_mret                 : std_logic;
    signal sl_ctrl_is_mret_copy            : std_logic;
    signal sl_ctrl_exe_is_branch_inst_copy : std_logic;
    signal sv_ctrl_exema_baddr             : std_logic_vector(31 downto 0);
    signal sl_ctrl_ma_is_branch_inst_copy  : std_logic;
    signal sl_ctrl_ma_is_valid_inst        : std_logic;
    signal sv_ctrl_ma_addr                 : std_logic_vector(31 downto 0);
    signal sl_ctrl_inst_raised_trap        : std_logic;
    signal sl_ctrl_ma_branch_taken         : std_logic;
    signal sl_ctrl_ma_is_branch_inst       : std_logic;
    signal sv_ctrl_ma_baddr                : std_logic_vector(31 downto 0);
    signal sl_wb_insn_retire               : std_logic;
    signal sl_ctrl_wb_is_branch_inst_copy  : std_logic;
    signal sl_ctrl_wb_is_valid_inst        : std_logic;
    signal sl_ctrl_wb_branch_taken         : std_logic;
    signal sv_ctrl_wb_addr                 : std_logic_vector(31 downto 0);

    --- signals declared for rv-formal interface functionality ---

    type tal_pipe_done is array (0 to 4) of std_logic;
    signal stal_pipe_done : tal_pipe_done;

    function fv_cnt_order64(
        order : std_logic_vector(63 downto 0)
    ) return std_logic_vector is
        variable vu_order_L : unsigned(31 downto 0);
        variable vu_order_H : unsigned(31 downto 0);
    begin
        vu_order_L := unsigned(order(31 downto 0));
        vu_order_H := unsigned(order(63 downto 32));

        if vu_order_L = X"FFFF_FFFF" then
            vu_order_L := (others => '0');
            if vu_order_H = X"FFFF_FFFF" then
                vu_order_H := (others => '0');
            else
                vu_order_H := vu_order_H + 1;
            end if;
        else
            vu_order_L := vu_order_L + 1;
        end if;

        return std_logic_vector(vu_order_H & vu_order_L);
    end function;

    signal sl_rvfi_valid : std_logic;

    type tav_rvfi_order is array (0 to 4) of std_logic_vector(63 downto 0);
    signal stav_rvfi_order : tav_rvfi_order;
    signal sv_rvfi_order   : std_logic_vector(63 downto 0);

    type tav_rvfi_insn is array (0 to 4) of std_logic_vector(31 downto 0);
    signal stav_rvfi_insn : tav_rvfi_insn;
    signal sv_rvfi_insn   : std_logic_vector(31 downto 0);

    type tal_rvfi_trap is array (0 to 4) of std_logic;
    signal stal_rvfi_trap : tal_rvfi_trap;
    signal sl_rvfi_trap   : std_logic;
    signal sl_trap        : std_logic;

    type tal_rvfi_halt is array (0 to 4) of std_logic;
    signal stal_rvfi_halt : tal_rvfi_halt;
    signal sl_rvfi_halt   : std_logic;

    type tal_rvfi_intr is array (0 to 4) of std_logic;
    signal stal_rvfi_intr : tal_rvfi_intr;
    signal sl_rvfi_intr   : std_logic;

    signal sv_rvfi_mode : std_logic_vector(1 downto 0);
    signal sv_rvfi_ixl  : std_logic_vector(1 downto 0);

    type tav_rvfi_raddr is array (0 to 4) of std_logic_vector(4 downto 0);
    signal stav_rvfi_rs1_addr : tav_rvfi_raddr;
    signal sv_rvfi_rs1_addr   : std_logic_vector(4 downto 0);

    signal stav_rvfi_rs2_addr : tav_rvfi_raddr;
    signal sv_rvfi_rs2_addr   : std_logic_vector(4 downto 0);

    signal stav_rvfi_rd_addr : tav_rvfi_raddr;
    signal sv_rvfi_rd_addr   : std_logic_vector(4 downto 0);

    type tav_rvfi_rdata is array (0 to 4) of std_logic_vector(31 downto 0);
    signal stav_rvfi_rs1_rdata : tav_rvfi_rdata;
    signal sv_rvfi_rs1_rdata   : std_logic_vector(31 downto 0);

    signal stav_rvfi_rs2_rdata : tav_rvfi_rdata;
    signal sv_rvfi_rs2_rdata   : std_logic_vector(31 downto 0);

    signal stav_rvfi_rd_wdata : tav_rvfi_rdata;
    signal sv_rvfi_rd_wdata   : std_logic_vector(31 downto 0);

    type tav_rvfi_pc is array (0 to 4) of std_logic_vector(31 downto 0);
    signal stav_rvfi_pc_rdata : tav_rvfi_pc;
    signal sv_rvfi_pc_rdata   : std_logic_vector(31 downto 0);

    signal stav_rvfi_pc_wdata : tav_rvfi_pc;
    signal sv_rvfi_pc_wdata   : std_logic_vector(31 downto 0);

    type tav_rvfi_mem_addr is array (0 to 4) of std_logic_vector(31 downto 0);
    signal stav_rvfi_mem_addr : tav_rvfi_mem_addr;
    signal sv_rvfi_mem_addr   : std_logic_vector(31 downto 0);

    type tav_rvfi_mem_data is array (0 to 4) of std_logic_vector(31 downto 0);
    signal stav_rvfi_mem_rdata : tav_rvfi_mem_data;
    signal sv_rvfi_mem_rdata   : std_logic_vector(31 downto 0);

    signal stav_rvfi_mem_wdata : tav_rvfi_mem_data;
    signal sv_rvfi_mem_wdata   : std_logic_vector(31 downto 0);

    type tav_rvfi_mem_mask is array (0 to 4) of std_logic_vector(3 downto 0);
    signal stav_rvfi_mem_rmask : tav_rvfi_mem_mask;
    signal stav_rvfi_mem_wmask : tav_rvfi_mem_mask;

    signal sv_rvfi_mem_mask : std_logic_vector(3 downto 0);

    type tav_rvfi_csr_rmask is array (0 to 4) of std_logic_vector(31 downto 0);
    type tav_rvfi_csr_wmask is array (0 to 4) of std_logic_vector(31 downto 0);
    type tav_rvfi_csr_rdata is array (0 to 4) of std_logic_vector(31 downto 0);
    type tav_rvfi_csr_wdata is array (0 to 4) of std_logic_vector(31 downto 0);

    signal stav_rvfi_csr_misa_rmask       : tav_rvfi_csr_rmask;
    signal stav_rvfi_csr_misa_wmask       : tav_rvfi_csr_wmask;
    signal stav_rvfi_csr_misa_rdata       : tav_rvfi_csr_rdata;
    signal stav_rvfi_csr_misa_wdata       : tav_rvfi_csr_wdata;
    signal sv_rvfi_csr_misa_rmask         : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_misa_wmask         : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_misa_rdata         : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_misa_wdata         : std_logic_vector(31 downto 0);

    signal stav_rvfi_csr_mvendorid_rmask  : tav_rvfi_csr_rmask;
    signal stav_rvfi_csr_mvendorid_wmask  : tav_rvfi_csr_wmask;
    signal stav_rvfi_csr_mvendorid_rdata  : tav_rvfi_csr_rdata;
    signal stav_rvfi_csr_mvendorid_wdata  : tav_rvfi_csr_wdata;
    signal sv_rvfi_csr_mvendorid_rmask    : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_mvendorid_wmask    : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_mvendorid_rdata    : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_mvendorid_wdata    : std_logic_vector(31 downto 0);

    signal stav_rvfi_csr_marchid_rmask    : tav_rvfi_csr_rmask;
    signal stav_rvfi_csr_marchid_wmask    : tav_rvfi_csr_wmask;
    signal stav_rvfi_csr_marchid_rdata    : tav_rvfi_csr_rdata;
    signal stav_rvfi_csr_marchid_wdata    : tav_rvfi_csr_wdata;
    signal sv_rvfi_csr_marchid_rmask      : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_marchid_wmask      : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_marchid_rdata      : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_marchid_wdata      : std_logic_vector(31 downto 0);

    signal stav_rvfi_csr_mimpid_rmask     : tav_rvfi_csr_rmask;
    signal stav_rvfi_csr_mimpid_wmask     : tav_rvfi_csr_wmask;
    signal stav_rvfi_csr_mimpid_rdata     : tav_rvfi_csr_rdata;
    signal stav_rvfi_csr_mimpid_wdata     : tav_rvfi_csr_wdata;
    signal sv_rvfi_csr_mimpid_rmask       : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_mimpid_wmask       : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_mimpid_rdata       : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_mimpid_wdata       : std_logic_vector(31 downto 0);

    signal stav_rvfi_csr_mstatus_rmask    : tav_rvfi_csr_rmask;
    signal stav_rvfi_csr_mstatus_wmask    : tav_rvfi_csr_wmask;
    signal stav_rvfi_csr_mstatus_rdata    : tav_rvfi_csr_rdata;
    signal stav_rvfi_csr_mstatus_wdata    : tav_rvfi_csr_wdata;
    signal sv_rvfi_csr_mstatus_rmask      : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_mstatus_wmask      : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_mstatus_rdata      : std_logic_vector(31 downto 0);
    signal sv_rvfi_csr_mstatus_wdata      : std_logic_vector(31 downto 0);

begin

    -----------------------------------------------------------------------------------------------------
    ---------------------------- IF, IF/ID STAGE : INSTRUCTION FETCH ------------------------------------
    -----------------------------------------------------------------------------------------------------

    sl_if_pipe_start    <= sl_ctrl_pipe_start;
    sl_insn_first_fetch <= sl_ctrl_first_fetch;

    gen_if_control_mc : if cb_MULTI_CYCLE_FETCH = true generate
        sl_if_ben   <= sl_ctrl_if_ben or sl_ctrl_exc_ben;
        sl_if_cen   <= str_ifid_pipe_status_out.l_ready and not sl_ctrl_if_stall;
        sv_if_baddr <= sv_ctrl_exc_baddr when sl_ctrl_exc_ben = cl_ENABLE else sv_ctrl_if_baddr;

        sl_next_stage_ready <= str_idexe_pipe_status_out.l_ready and not sl_ctrl_if_stall;
        sl_fetch_en         <= sl_ctrl_step when sl_ctrl_is_in_debug_mode = cl_ENABLE else
            cl_ENABLE;
    else gen_if_control : generate
        sl_if_ben   <= sl_ctrl_if_ben or sl_ctrl_exc_ben;
        sl_if_cen   <= str_ifid_pipe_status_out.l_ready and not sl_ctrl_if_stall when sl_ctrl_is_in_debug_mode = cl_DISABLE else
            cl_DISABLE;
        sv_if_baddr <= sv_ctrl_exc_baddr when sl_ctrl_exc_ben = cl_ENABLE else sv_ctrl_if_baddr;

        sl_next_stage_ready <= str_idexe_pipe_status_out.l_ready and not sl_ctrl_if_stall;
        sl_fetch_en         <= sl_ctrl_step when sl_ctrl_is_in_debug_mode = cl_ENABLE else
            cl_ENABLE;
    end generate;

    inst_if_unit : entity work.if_unit
        generic map(
            gv_PC_ORIGIN         => cv_PC_ORIGIN,
            gb_EXT_C             => cb_EXT_C,
            gb_MULTI_CYCLE_FETCH => cb_MULTI_CYCLE_FETCH,
            gb_RISCV_FORMAL      => cb_RISCV_FORMAL
        )
        port map(
            pil_clk                  => pil_clk,
            pil_rst                  => pil_rst,
            pol_is_compressed        => sl_is_compressed,
            pol_illegal_inst         => sl_illegal_compressed_inst,
            pov_rvfi_compressed_isnt => sv_rvfi_compressed_isnt,
            potr_inst                => str_inst,
            pil_pipe_start           => sl_if_pipe_start,
            pil_pipe_ready           => sl_next_stage_ready,
            pil_fetch_en             => sl_fetch_en,
            pil_insn_first_fetch     => sl_insn_first_fetch,
            pol_insn_valid           => sl_insn_valid,
            pol_prefetch_stall       => sl_if_prefetch_stall,
            pil_mem_valid            => pil_fetch_mem_valid,
            pil_mem_ack              => pil_fetch_mem_ack,
            pol_mem_req              => pol_fetch_mem_req,
            piv_mem_rdata            => piv_fetch_mem_rdata,
            pov_mem_addr             => pov_fetch_mem_addr,
            pil_if_ben               => sl_if_ben,
            pil_if_cen               => sl_if_cen,
            piv_if_baddr             => sv_if_baddr,
            pov_if_addr              => sv_if_addr
        );

    
    gen_ifid_halt_control_mc : if cb_MULTI_CYCLE_FETCH = true generate
        sl_if_halt                                      <= sl_ctrl_if_stall;
        sl_ifid_nop_inst                                <= sl_ctrl_ifid_nop_inst;   -- add a bubble in the pipeline e.g. during branch
        str_ifid_stage_reg_in.l_nop_inst                <= sl_ctrl_ifid_nop_inst; -- set the flag when it is a nop inst
    else gen_ifid_halt_control : generate
        sl_if_halt                                      <= sl_ctrl_if_stall when sl_ctrl_is_in_debug_mode = cl_DISABLE else
            not sl_ctrl_step;
        sl_ifid_nop_inst                                <= sl_ctrl_ifid_nop_inst when sl_ctrl_is_in_debug_mode = cl_DISABLE else
            not sl_ctrl_step;   -- add a bubble in the pipeline e.g. during branch
        str_ifid_stage_reg_in.l_nop_inst                <= sl_ctrl_ifid_nop_inst when sl_ctrl_is_in_debug_mode = cl_DISABLE else
            not sl_ctrl_step;   -- add a bubble in the pipeline e.g. during branch
    end generate;

    str_ifid_pipe_status_in.l_ready                 <= str_idexe_pipe_status_out.l_ready;
    str_ifid_pipe_status_in.l_stb                   <= cl_ENABLE;
    sl_if_mem_valid                                 <= sl_insn_valid and sl_ctrl_pipe_start;
    str_ifid_stage_reg_in.v_addr                    <= sv_if_addr;
    str_ifid_stage_reg_in.t_inst                    <= str_inst;
    str_ifid_stage_reg_in.l_rvfi_intr               <= sl_ctrl_rvfi_intr;       -- set when the new instruction is the first instruction of exc/intr handler
    str_ifid_stage_reg_in.l_irq_regfile_sel         <= sl_ctrl_irq_regfile_sel and not sl_ctrl_ignore_irq_regfile;
    str_ifid_stage_reg_in.v_compressed_inst         <= sv_rvfi_compressed_isnt;
    str_ifid_stage_reg_in.l_is_compressed           <= sl_is_compressed;
    str_ifid_stage_reg_in.l_illegal_compressed_inst <= sl_illegal_compressed_inst;

    inst_ifid_reg : entity work.if_id_reg
        generic map (
            gb_MULTI_CYCLE_FETCH => cb_MULTI_CYCLE_FETCH
        )
        port map(
            pil_clk             => pil_clk,
            pil_rst             => pil_rst,
            pitr_pipe_status    => str_ifid_pipe_status_in,
            pil_if_halt         => sl_if_halt,
            pil_if_mem_valid    => sl_if_mem_valid,
            pil_ifid_nop_inst   => sl_ifid_nop_inst,
            pitr_ifid_stage_reg => str_ifid_stage_reg_in,
            potr_ifid_stage_reg => str_ifid_stage_reg_out,
            potr_pipe_status    => str_ifid_pipe_status_out
        );

    -----------------------------------------------------------------------------------------------------
    --------------------------- ID, ID/EXE STAGE : INSTRUCTION DECODE -----------------------------------
    -----------------------------------------------------------------------------------------------------

    str_id_inst            <= str_ifid_stage_reg_out.t_inst;
    sv_ifid_addr           <= str_ifid_stage_reg_out.v_addr;
    sl_id_irq_regfile_sel  <= str_mawb_stage_reg_out.l_irq_regfile_sel;
    sl_regf_we             <= str_mawb_stage_reg_out.t_wb_ctrl.l_rd_wen;
    stv_regf_waddr_rd      <= str_mawb_stage_reg_out.t_inst.v_reg_rd;
    sv_regf_wdata          <= sv_wb_reg_mux;

    sv_dfu_write_ctrl_cond <= str_mawb_stage_reg_out.t_wb_ctrl.l_rd_WEN & str_exema_stage_reg_out.t_wb_ctrl.l_rd_WEN & str_idexe_stage_reg_out.t_wb_ctrl.l_rd_WEN & (str_exema_stage_reg_out.t_ma_ctrl.l_is_mem_inst and not str_exema_stage_reg_out.t_ma_ctrl.l_RAM_WEN);
    sv_dfu_exe_src         <= sv_exe_result;
    sv_dfu_ma_src          <= str_exema_stage_reg_out.v_exe_result;
    sv_dfu_ma_ld_src       <= sv_ma_mai_rdata;
    sv_dfu_wb_src          <= sv_wb_reg_mux;
    stv_dfu_exe_rd_addr    <= str_idexe_stage_reg_out.t_inst.v_reg_rd;
    stv_dfu_ma_rd_addr     <= str_exema_stage_reg_out.t_inst.v_reg_rd;
    stv_dfu_wb_rd_addr     <= str_mawb_stage_reg_out.t_inst.v_reg_rd;

    sl_id_gpr_access_req   <= sl_ctrl_access_req;
    sv_id_gpr_access_addr  <= sv_ctrl_access_regno(4 downto 0);
    sl_id_gpr_access_wen   <= sl_ctrl_access_gpr_wen;
    sv_id_gpr_access_wdata <= sv_ctrl_access_wdata;

    inst_id_unit : entity work.id_unit
        generic map(
            gb_EXT_M                => cb_EXT_M,
            gb_RV32_E               => cb_RV32_E,
            gb_GPR_HW_BACKUP        => cb_GPR_HW_BACKUP
        )
        port map(
            pil_clk                 => pil_clk,
            pil_rst                 => pil_rst,
            pitr_id_inst            => str_id_inst,
            piv_id_addr             => sv_ifid_addr,
            pil_irq_regfile_sel     => sl_id_irq_regfile_sel,
            pil_we                  => sl_regf_we,
            pitv_waddr_rd           => stv_regf_waddr_rd,
            piv_wdata               => sv_regf_wdata,
            piv_dfu_write_ctrl_cond => sv_dfu_write_ctrl_cond,
            piv_dfu_exe_src         => sv_dfu_exe_src,
            piv_dfu_ma_src          => sv_dfu_ma_src,
            piv_dfu_ma_ld_src       => sv_dfu_ma_ld_src,
            piv_dfu_wb_src          => sv_dfu_wb_src,
            pitv_dfu_exe_rd_addr    => stv_dfu_exe_rd_addr,
            pitv_dfu_ma_rd_addr     => stv_dfu_ma_rd_addr,
            pitv_dfu_wb_rd_addr     => stv_dfu_wb_rd_addr,
            pov_id_intalu_op        => sv_id_intalu_op,
            pov_id_md_op            => sv_id_md_op,
            pov_id_csr_op           => sv_id_csr_op,
            potr_id_cpu_ctrl        => str_id_cpu_ctrl,
            pov_id_src1             => sv_id_rsrc1,
            pov_id_src2             => sv_id_rsrc2,
            pov_id_fw_rsrc2         => sv_id_fw_rsrc2,
            pol_id_illegal_inst     => sl_id_illegal_inst,
            pil_gpr_access_req      => sl_id_gpr_access_req,
            piv_gpr_access_addr     => sv_id_gpr_access_addr,
            pil_gpr_access_wen      => sl_id_gpr_access_wen,
            piv_gpr_access_wdata    => sv_id_gpr_access_wdata,
            pov_gpr_access_rdata    => sv_id_gpr_access_rdata
        );

    str_idexe_pipe_status_in.l_ready             <= str_exema_pipe_status_out.l_ready;
    str_idexe_pipe_status_in.l_stb               <= str_ifid_pipe_status_out.l_stb;
    sl_id_halt                                   <= sl_ctrl_id_stall;
    str_idexe_stage_reg_in.t_inst                <= str_ifid_stage_reg_out.t_inst;
    str_idexe_stage_reg_in.v_compressed_inst     <= str_ifid_stage_reg_out.v_compressed_inst;
    str_idexe_stage_reg_in.v_addr                <= str_ifid_stage_reg_out.v_addr;
    str_idexe_stage_reg_in.v_src1                <= sv_id_rsrc1;
    str_idexe_stage_reg_in.v_src2                <= sv_id_rsrc2;
    str_idexe_stage_reg_in.v_fw_rsrc2            <= sv_id_fw_rsrc2;
    str_idexe_stage_reg_in.v_intalu_op           <= sv_id_intalu_op;
    str_idexe_stage_reg_in.v_md_op               <= sv_id_md_op;
    str_idexe_stage_reg_in.v_csr_op              <= sv_id_csr_op;
    str_idexe_stage_reg_in.t_exe_ctrl            <= str_id_cpu_ctrl.tr_exe_stage;
    str_idexe_stage_reg_in.t_ma_ctrl             <= str_id_cpu_ctrl.tr_ma_stage;
    str_idexe_stage_reg_in.t_wb_ctrl             <= str_id_cpu_ctrl.tr_wb_stage;
    str_idexe_stage_reg_in.t_rvfi                <= str_id_cpu_ctrl.tr_rvfi;
    str_idexe_stage_reg_in.l_rvfi_intr           <= str_ifid_stage_reg_out.l_rvfi_intr;
    str_idexe_stage_reg_in.l_irq_regfile_sel     <= str_ifid_stage_reg_out.l_irq_regfile_sel and not sl_ctrl_ignore_irq_regfile;
    str_idexe_stage_reg_in.l_is_compressed       <= str_ifid_stage_reg_out.l_is_compressed;
    str_idexe_stage_reg_in.l_is_branch_inst_copy <= str_id_cpu_ctrl.tr_ma_stage.l_is_branch_inst;
    str_idexe_stage_reg_in.l_is_mret_copy        <= str_id_cpu_ctrl.tr_ma_stage.l_is_mret;
    str_idexe_stage_reg_in.l_nop_inst            <= str_ifid_stage_reg_out.l_nop_inst;
    str_idexe_stage_reg_in.l_inst_tag            <= not str_ifid_stage_reg_out.l_nop_inst and not sl_ctrl_id_stall and sl_ctrl_illegal_inst_en_chk;
    str_idexe_stage_reg_in.l_illegal_inst        <= not str_ifid_stage_reg_out.l_nop_inst and ((str_ifid_stage_reg_out.l_illegal_compressed_inst or sl_id_illegal_inst) and not sl_ctrl_id_stall) and sl_ctrl_illegal_inst_en_chk;

    inst_idexe_reg : entity work.id_exe_reg
        generic map (
            gb_MULTI_CYCLE_FETCH => cb_MULTI_CYCLE_FETCH
        )
        port map(
            pil_clk              => pil_clk,
            pil_rst              => pil_rst,
            pitr_pipe_status     => str_idexe_pipe_status_in,
            pil_id_halt          => sl_id_halt,
            pitr_idexe_stage_reg => str_idexe_stage_reg_in,
            potr_idexe_stage_reg => str_idexe_stage_reg_out,
            potr_pipe_status     => str_idexe_pipe_status_out
        );

    -----------------------------------------------------------------------------------------------------
    -------------------------- EXE, EXE/MA STAGE : INSTRUCTION EXECUTE ----------------------------------
    -----------------------------------------------------------------------------------------------------

    str_exe_inst     <= str_idexe_stage_reg_out.t_inst;
    sv_exe_intalu_op <= str_idexe_stage_reg_out.v_intalu_op;
    sv_exe_md_op     <= str_idexe_stage_reg_out.v_md_op;
    sv_exe_csr_op    <= str_idexe_stage_reg_out.v_csr_op;
    sv_src_op1       <= str_idexe_stage_reg_out.v_src1;
    sv_src_op2       <= str_idexe_stage_reg_out.v_src2;
    str_exe_ctrl     <= str_idexe_stage_reg_out.t_exe_ctrl;

    sl_exe_mepc_wen     <= sl_ctrl_mepc_wen;
    sv_exe_mepc         <= sv_ctrl_mepc;
    sl_exe_mtval_wen    <= sl_ctrl_mtval_wen;
    sv_exe_mtval        <= sv_ctrl_mtval;
    sl_exe_minstret_wen <= sl_instret_wen;
    sv_exe_minstret     <= sv_instret(31 downto 0);
    sl_exe_mstatus_wen  <= sl_ctrl_mstatus_wen;
    sv_exe_mstatus      <= sv_ctrl_mstatus(7 downto 0);
    sl_exe_mcause_wen   <= sl_ctrl_mcause_wen;
    sv_exe_mcause       <= sv_ctrl_mcause;
    sv_exe_mip          <= sv_ctrl_mip(11 downto 0);
    sl_exe_dcsr_wen     <= sl_ctrl_dcsr_wen;
    sv_exe_dcsr         <= sv_ctrl_dcsr;
    sl_exe_dpc_wen      <= sl_ctrl_dpc_wen;
    sv_exe_dpc          <= sv_ctrl_dpc;

    sl_exe_csr_halt_bypass  <= sl_ctrl_csr_halt_bypass;
    sl_exe_csr_wen          <= str_exema_stage_reg_out.t_ma_ctrl.l_CSR_WEN;
    sv_exe_csr_waddr        <= str_exema_stage_reg_out.t_inst.v_funct7 & str_exema_stage_reg_out.t_inst.v_reg_rs2;
    sv_exe_csr_wdata        <= str_exema_stage_reg_out.v_csr_wdata;

    sl_exe_csr_access_req   <= sl_ctrl_access_req;
    sv_exe_csr_access_addr  <= sv_ctrl_access_regno;
    sl_exe_csr_access_wen   <= sl_ctrl_access_csr_wen;
    sv_exe_csr_access_wdata <= sv_ctrl_access_wdata;

    inst_exe_unit : entity work.exe_unit
        generic map(
            gb_EXT_M               => cb_EXT_M,
            gb_EXT_C               => cb_EXT_C,
            gv_reg_MVENDORID       => cv_reg_MVENDORID,
            gv_reg_MARCHID         => cv_reg_MARCHID,
            gv_reg_MIMPID          => cv_reg_MIMPID,
            gv_reg_MHARTID         => cv_reg_MHARTID,
            gb_RISCV_FORMAL_ALTOPS => cb_RISCV_FORMAL_ALTOPS
        )
        port map(
            pil_clk                   => pil_clk,
            pil_rst                   => pil_rst,
            pil_valid_inst            => str_idexe_stage_reg_out.l_inst_tag,
            pil_exe_halt              => sl_ctrl_id_stall, -- when controller issues an id_stall then halt all execution currently running
            pitr_exe_inst             => str_exe_inst,
            piv_exe_addr              => str_idexe_stage_reg_out.v_addr,
            piv_exe_intalu_op         => sv_exe_intalu_op,
            piv_exe_md_op             => sv_exe_md_op,
            piv_exe_csr_op            => sv_exe_csr_op,
            piv_src_op1               => sv_src_op1,
            piv_src_op2               => sv_src_op2,
            pitr_exe_ctrl             => str_exe_ctrl,
            pol_exe_branch_taken      => sl_exe_branch_taken,
            pol_exe_busy              => sl_exe_busy,
            pov_exe_intalu_result     => sv_exe_intalu_result,
            pov_exe_result            => sv_exe_result,
            pil_exe_ctrl_mepc_wen     => sl_exe_mepc_wen,
            piv_exe_ctrl_mepc         => sv_exe_mepc,
            pil_exe_ctrl_mtval_wen    => sl_exe_mtval_wen,
            piv_exe_ctrl_mtval        => sv_exe_mtval,
            pil_exe_ctrl_minstret_wen => sl_exe_minstret_wen,
            piv_exe_ctrl_minstret     => sv_exe_minstret,
            pil_exe_ctrl_mstatus_wen  => sl_exe_mstatus_wen,
            piv_exe_ctrl_mstatus      => sv_exe_mstatus,
            pil_exe_ctrl_mcause_wen   => sl_exe_mcause_wen,
            piv_exe_ctrl_mcause       => sv_exe_mcause,
            piv_exe_ctrl_mip          => sv_exe_mip,
            pil_csr_ctrl_dcsr_wen     => sl_exe_dcsr_wen,
            piv_csr_ctrl_dcsr         => sv_exe_dcsr,
            pil_csr_ctrl_dpc_wen      => sl_exe_dpc_wen,
            piv_csr_ctrl_dpc          => sv_exe_dpc,
            pil_csr_halt_bypass       => sl_exe_csr_halt_bypass,
            pil_csr_wen               => sl_exe_csr_wen,
            piv_csr_waddr             => sv_exe_csr_waddr,
            piv_csr_wdata             => sv_exe_csr_wdata,
            potr_csr                  => str_exe_csr,
            pov_csr_modify            => sv_exe_csr_modify,
            pol_exe_trigger_match     => sl_exe_trigger_match,
            pil_csr_access_req        => sl_exe_csr_access_req,
            piv_csr_access_addr       => sv_exe_csr_access_addr,
            pil_csr_access_wen        => sl_exe_csr_access_wen,
            piv_csr_access_wdata      => sv_exe_csr_access_wdata,
            pov_csr_access_rdata      => sv_exe_csr_access_rdata,
            pol_csr_access_err        => sl_exe_csr_access_err
        );

    str_exema_pipe_status_in.l_ready             <= str_mawb_pipe_status_out.l_ready;
    str_exema_pipe_status_in.l_stb               <= str_idexe_pipe_status_out.l_stb;
    sl_exe_halt                                  <= sl_ctrl_exe_stall;
    sl_exe_unit_valid                            <= not sl_exe_busy;
    str_exema_stage_reg_in.t_inst                <= str_idexe_stage_reg_out.t_inst;
    str_exema_stage_reg_in.v_compressed_inst     <= str_idexe_stage_reg_out.v_compressed_inst;
    str_exema_stage_reg_in.v_addr                <= str_idexe_stage_reg_out.v_addr;
    str_exema_stage_reg_in.l_branch_taken        <= sl_exe_branch_taken and not sl_ignore_branch_at_exe;
    str_exema_stage_reg_in.v_branch_addr         <= sv_ctrl_exema_baddr;
    str_exema_stage_reg_in.v_mai_addr            <= sv_exe_intalu_result;
    str_exema_stage_reg_in.v_exe_result          <= sv_exe_result;
    str_exema_stage_reg_in.v_csr_wdata           <= sv_exe_csr_modify;
    str_exema_stage_reg_in.v_dfu_fw_rsrc2        <= str_idexe_stage_reg_out.v_fw_rsrc2;
    str_exema_stage_reg_in.t_ma_ctrl             <= str_idexe_stage_reg_out.t_ma_ctrl;
    str_exema_stage_reg_in.t_wb_ctrl.l_rd_WEN    <= (str_idexe_stage_reg_out.t_wb_ctrl.l_rd_WEN and not sl_trap) and not sl_ignore_branch_at_exe; -- Only write If the instruction has not trapped
                                                                                                                                                  -- and the branch is not ignored due to interrupts
    str_exema_stage_reg_in.t_wb_ctrl.v_wb_mux    <= str_idexe_stage_reg_out.t_wb_ctrl.v_wb_mux;
    str_exema_stage_reg_in.t_rvfi                <= str_idexe_stage_reg_out.t_rvfi;
    str_exema_stage_reg_in.l_rvfi_intr           <= str_idexe_stage_reg_out.l_rvfi_intr;
    str_exema_stage_reg_in.l_irq_regfile_sel     <= str_idexe_stage_reg_out.l_irq_regfile_sel and not sl_ctrl_ignore_irq_regfile;
    str_exema_stage_reg_in.l_trap                <= sl_trap;
    str_exema_stage_reg_in.l_is_compressed       <= str_idexe_stage_reg_out.l_is_compressed;
    str_exema_stage_reg_in.l_is_branch_inst_copy <= str_idexe_stage_reg_out.l_is_branch_inst_copy;
    str_exema_stage_reg_in.l_is_mret_copy        <= str_idexe_stage_reg_out.l_is_mret_copy;
    str_exema_stage_reg_in.l_inst_tag            <= str_idexe_stage_reg_out.l_inst_tag and not sl_ignore_branch_at_exe;
    str_exema_stage_reg_in.l_illegal_inst        <= str_idexe_stage_reg_out.l_illegal_inst;
    str_exema_stage_reg_in.t_rvfi_csr            <= str_exe_csr;
    str_exema_stage_reg_in.v_rvfi_src1           <= str_idexe_stage_reg_out.v_src1;
    str_exema_stage_reg_in.v_rvfi_src2           <= str_idexe_stage_reg_out.v_src2;

    inst_exema_reg : entity work.exe_ma_reg
        port map(
            pil_clk              => pil_clk,
            pil_rst              => pil_rst,
            pitr_pipe_status     => str_exema_pipe_status_in,
            pil_exe_halt         => sl_exe_halt,
            pil_exe_unit_valid   => sl_exe_unit_valid,
            pitr_exema_stage_reg => str_exema_stage_reg_in,
            potr_exema_stage_reg => str_exema_stage_reg_out,
            potr_pipe_status     => str_exema_pipe_status_out
        );

    -----------------------------------------------------------------------------------------------------
    ---------------------------- MA, MA/WB STAGE : DATA MEMORY ACCESS -----------------------------------
    -----------------------------------------------------------------------------------------------------

    sv_ma_mai_addr  <= str_exema_stage_reg_out.v_mai_addr;
    sv_ma_mai_wdata <= str_exema_stage_reg_out.v_dfu_fw_rsrc2;
    str_ma_ctrl     <= str_exema_stage_reg_out.t_ma_ctrl;

    inst_ma_unit : entity work.ma_unit
        port map(
            pil_clk             => pil_clk,
            pil_rst             => pil_rst,
            piv_ma_mai_addr     => sv_ma_mai_addr,
            piv_ma_mai_wdata    => sv_ma_mai_wdata,
            pitr_ma_ctrl        => str_ma_ctrl,
            pil_ma_mem_valid    => pil_mem_valid,
            pil_ma_mem_ack      => pil_mem_ack,
            pol_ma_mem_req      => sl_ma_mem_req,
            pol_ma_mem_wen      => sl_ma_mem_wen,
            piv_ma_mem_rdata    => piv_mem_rdata,
            pov_ma_mem_wdata    => sv_ma_mem_wdata,
            pov_ma_mem_addr     => sv_ma_mem_addr,
            pov_ma_mem_byte_sel => sv_ma_mem_byte_sel,
            pov_ma_mai_rdata    => sv_ma_mai_rdata,
            pol_ma_ready        => sl_ma_ready
        );

    str_mawb_pipe_status_in.l_ready             <= cl_ENABLE;  -- last stage of the pipeline is always enabled
    str_mawb_pipe_status_in.l_stb               <= str_exema_pipe_status_out.l_stb;
    sl_ma_halt                                  <= cl_DISABLE; -- this is always disable since there is no need to halt this stage
    sl_ma_unit_valid                            <= sl_ma_ready;
    str_mawb_stage_reg_in.t_inst                <= str_exema_stage_reg_out.t_inst;
    str_mawb_stage_reg_in.v_compressed_inst     <= str_exema_stage_reg_out.v_compressed_inst;
    str_mawb_stage_reg_in.v_addr                <= str_exema_stage_reg_out.v_addr;
    str_mawb_stage_reg_in.v_mem_data            <= sv_ma_mai_rdata;
    str_mawb_stage_reg_in.v_result              <= str_exema_stage_reg_out.v_exe_result;
    str_mawb_stage_reg_in.v_csr_wdata           <= str_exema_stage_reg_out.v_csr_wdata;
    str_mawb_stage_reg_in.l_branch_taken        <= str_exema_stage_reg_out.l_branch_taken;
    str_mawb_stage_reg_in.t_wb_ctrl             <= str_exema_stage_reg_out.t_wb_ctrl;
    str_mawb_stage_reg_in.l_is_compressed       <= str_exema_stage_reg_out.l_is_compressed;
    str_mawb_stage_reg_in.l_is_branch_inst_copy <= str_exema_stage_reg_out.l_is_branch_inst_copy;
    str_mawb_stage_reg_in.l_inst_tag            <= str_exema_stage_reg_out.l_inst_tag;
    str_mawb_stage_reg_in.l_irq_regfile_sel     <= str_exema_stage_reg_out.l_irq_regfile_sel and not sl_ctrl_ignore_irq_regfile;
    str_mawb_stage_reg_in.l_illegal_inst        <= str_exema_stage_reg_out.l_illegal_inst;
    str_mawb_stage_reg_in.t_rvfi_csr            <= str_exema_stage_reg_out.t_rvfi_csr;

    inst_mawb_reg : entity work.ma_wb_reg
        port map(
            pil_clk             => pil_clk,
            pil_rst             => pil_rst,
            pitr_pipe_status    => str_mawb_pipe_status_in,
            pil_ma_halt         => sl_ma_halt,
            pil_ma_unit_valid   => sl_ma_unit_valid,
            pitr_mawb_stage_reg => str_mawb_stage_reg_in,
            potr_mawb_stage_reg => str_mawb_stage_reg_out,
            potr_pipe_status    => str_mawb_pipe_status_out
        );

    -----------------------------------------------------------------------------------------------------
    ------------------------------- WB STAGE : REGISTER WRITE BACK --------------------------------------
    -----------------------------------------------------------------------------------------------------

    proc_wb_prog_addr : process (str_mawb_stage_reg_out)
    begin
        if str_mawb_stage_reg_out.l_is_compressed = cl_ENABLE then
            sv_wb_prog_addr <= std_logic_vector(unsigned(str_mawb_stage_reg_out.v_addr) + 2);
        else
            sv_wb_prog_addr <= std_logic_vector(unsigned(str_mawb_stage_reg_out.v_addr) + 4);
        end if;
    end process proc_wb_prog_addr;

    sv_wb_reg_mux <= str_mawb_stage_reg_out.v_result when str_mawb_stage_reg_out.t_wb_ctrl.v_wb_mux = ctr_MUX_wb.alu_result else
        str_mawb_stage_reg_out.v_mem_data when str_mawb_stage_reg_out.t_wb_ctrl.v_wb_mux = ctr_MUX_wb.wb_memory else
        sv_wb_prog_addr;
    
    proc_inst_monitor : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sl_instret_wen <= cl_DISABLE;
            sv_instret     <= (others => '0');
            sv_pc_retired  <= (others => '0');
        elsif rising_edge(pil_clk) then
            sl_instret_wen <= cl_DISABLE;
            if str_mawb_stage_reg_out.l_inst_tag = cl_ENABLE then
                sl_instret_wen <= cl_ENABLE;
                sv_instret     <= fv_cnt_order64(sv_instret);
                sv_pc_retired  <= str_mawb_stage_reg_out.v_addr;
            end if;
        end if;
    end process proc_inst_monitor;

    -----------------------------------------------------------------------------------------------------
    -------------------------------------- MAIN CONTROLLER ----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    gen_exc_c_ext : if cb_EXT_C = true generate
        proc_exc : process (sl_ctrl_if_ben, sl_exe_branch_taken, sv_ctrl_exema_baddr, str_idexe_stage_reg_out)
        begin
            sl_IALIGN_exc0     <= cl_DISABLE;
            sl_ILLINSN_exc2    <= cl_DISABLE;
            sl_BREAK_exc3      <= cl_DISABLE;
            sl_ECALL_exc11     <= cl_DISABLE;
            sv_exc_epc         <= (others => '0');
            sv_exc_inst        <= (others => '0');

            --- If a branch was initiated in the ma stage then do not check for exceptions as the current instruction in the pipeline will be flushed ---
            if (sl_ctrl_if_ben = cl_DISABLE) then
                if str_idexe_stage_reg_out.t_ma_ctrl.l_is_ebreak = cl_ENABLE then
                    sl_BREAK_exc3      <= cl_ENABLE;
                    sv_exc_epc         <= str_idexe_stage_reg_out.v_addr;
                    sv_exc_inst        <= str_idexe_stage_reg_out.v_compressed_inst; -- v_compressed_inst always has the 16 LSB of the actual instruction
                elsif str_idexe_stage_reg_out.t_ma_ctrl.l_is_ecall = cl_ENABLE then
                    sl_ECALL_exc11     <= cl_ENABLE;
                    sv_exc_epc         <= str_idexe_stage_reg_out.v_addr;
                end if;

                --- Only check other exceptions if it is not an ebreak instruction ---
                if str_idexe_stage_reg_out.t_ma_ctrl.l_is_ebreak = cl_DISABLE then
                    if str_idexe_stage_reg_out.l_illegal_inst = cl_ENABLE then
                        sl_ILLINSN_exc2    <= cl_ENABLE;
                        sv_exc_epc         <= str_idexe_stage_reg_out.v_addr;
                    else
                        if (sl_exe_branch_taken = cl_ENABLE and str_idexe_stage_reg_out.t_ma_ctrl.l_is_branch_inst = cl_ENABLE) then
                            if sv_ctrl_exema_baddr(0) /= '0' then
                                sl_IALIGN_exc0     <= cl_ENABLE;
                                sv_exc_epc         <= str_idexe_stage_reg_out.v_addr;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end process proc_exc;
    else gen_exc : generate
        proc_exc : process (sl_ctrl_if_ben, sl_exe_branch_taken, sv_ctrl_exema_baddr, str_idexe_stage_reg_out)
        begin
            sl_IALIGN_exc0     <= cl_DISABLE;
            sl_ILLINSN_exc2    <= cl_DISABLE;
            sl_BREAK_exc3      <= cl_DISABLE;
            sl_ECALL_exc11     <= cl_DISABLE;
            sv_exc_epc         <= (others => '0');
            sv_exc_inst        <= (others => '0');

            --- If a branch was initiated in the ma stage then do not check for exceptions as the current instruction in the pipeline will be flushed ---
            if (sl_ctrl_if_ben = cl_DISABLE) then
                if str_idexe_stage_reg_out.t_ma_ctrl.l_is_ebreak = cl_ENABLE then
                    sl_BREAK_exc3      <= cl_ENABLE;
                    sv_exc_epc         <= str_idexe_stage_reg_out.v_addr;
                    sv_exc_inst        <= fv_inst_rec2slv(instruction => str_idexe_stage_reg_out.t_inst);
                elsif str_idexe_stage_reg_out.t_ma_ctrl.l_is_ecall = cl_ENABLE then
                    sl_ECALL_exc11     <= cl_ENABLE;
                    sv_exc_epc         <= str_idexe_stage_reg_out.v_addr;
                end if;

                --- Only check other exceptions if it is not an ebreak instruction ---
                if str_idexe_stage_reg_out.t_ma_ctrl.l_is_ebreak = cl_DISABLE then
                    if str_idexe_stage_reg_out.l_illegal_inst = cl_ENABLE then
                        sl_ILLINSN_exc2    <= cl_ENABLE;
                        sv_exc_epc         <= str_idexe_stage_reg_out.v_addr;
                    else
                        if (sl_exe_branch_taken = cl_ENABLE and str_idexe_stage_reg_out.t_ma_ctrl.l_is_branch_inst = cl_ENABLE) then
                            if sv_ctrl_exema_baddr(1 downto 0) /= "00" then
                                sl_IALIGN_exc0     <= cl_ENABLE;
                                sv_exc_epc         <= str_idexe_stage_reg_out.v_addr;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end process proc_exc;
    end generate;

    sl_trap <= sl_IALIGN_exc0 or sl_ILLINSN_exc2 or sl_BREAK_exc3 or sl_ECALL_exc11;

    sl_ctrl_en                     <= pil_run_prg;
    sv_ctrl_csr_MEPC               <= str_exe_csr.v_MEPC;
    str_ctrl_csr_MSTATUS           <= (l_MPIE => str_exe_csr.v_MSTATUS(7), l_MIE => str_exe_csr.v_MSTATUS(3));
    str_ctrl_csr_MIE               <= (l_MEIE => str_exe_csr.v_MIE(11), l_MTIE => str_exe_csr.v_MIE(7), l_MSIE => str_exe_csr.v_MIE(3));
    str_ctrl_csr_DCSR              <= (l_step => str_exe_csr.v_DCSR(2), v_cause => str_exe_csr.v_DCSR(8 downto 6), l_ebreakm => str_exe_csr.v_DCSR(15));
    sv_ctrl_csr_DPC                <= str_exe_csr.v_DPC;
    str_ctrl_csr_MTVEC.v_MODE      <= str_exe_csr.v_MTVEC(1 downto 0);
    str_ctrl_csr_MTVEC.v_BASE      <= str_exe_csr.v_MTVEC(31 downto 2);

    -- Only enable the trigger match if no branch was initiated in the ma stage and it is a valid instruction
    sl_ctrl_trigger_match          <= sl_exe_trigger_match when sl_ctrl_if_ben = cl_DISABLE and str_idexe_stage_reg_out.l_inst_tag = cl_ENABLE else
        cl_DISABLE;

    sv_ctrl_access_gpr_rdata        <= sv_id_gpr_access_rdata;
    sv_ctrl_access_csr_rdata        <= sv_exe_csr_access_rdata;
    sl_ctrl_access_csr_err          <= sl_exe_csr_access_err;
    stv_ctrl_ifid_rs1_addr          <= str_ifid_stage_reg_out.t_inst.v_reg_rs1;
    stv_ctrl_ifid_rs2_addr          <= str_ifid_stage_reg_out.t_inst.v_reg_rs2;
    stv_ctrl_idexe_rd_addr          <= str_idexe_stage_reg_out.t_inst.v_reg_rd;
    sl_ctrl_idexe_mem_req           <= str_idexe_stage_reg_out.t_ma_ctrl.l_is_mem_inst;
    sl_ctrl_idexe_mem_wen           <= str_idexe_stage_reg_out.t_ma_ctrl.l_RAM_WEN;
    sl_ctrl_prefetch_stall          <= sl_if_prefetch_stall;
    sl_ctrl_if_cen                  <= sl_if_cen;
    sl_ctrl_ifid_nop_inst_in        <= str_ifid_stage_reg_out.l_nop_inst;
    sl_ctrl_ifid_ready              <= str_ifid_pipe_status_out.l_ready;
    sl_ctrl_idexe_nop_inst          <= str_idexe_stage_reg_out.l_nop_inst;
    sv_ctrl_id_addr                 <= str_ifid_stage_reg_out.v_addr;
    sv_ctrl_exe_addr                <= str_idexe_stage_reg_out.v_addr;
    sv_ctrl_exe_inst                <= fv_inst_rec2slv(instruction => str_idexe_stage_reg_out.t_inst);
    sl_ctrl_exe_is_valid_inst       <= str_idexe_stage_reg_out.l_inst_tag;
    sv_ctrl_exe_result              <= sv_exe_result;
    sl_ctrl_exe_boff_mux            <= str_idexe_stage_reg_out.t_exe_ctrl.l_branch_offset_mux;
    sl_ctrl_exe_baddr_src_mux       <= str_idexe_stage_reg_out.t_exe_ctrl.l_branch_addr_src_mux;
    sl_ctrl_exe_is_csr_inst         <= str_idexe_stage_reg_out.t_exe_ctrl.l_csr_EN;
    sl_ctrl_is_mret                 <= str_exema_stage_reg_out.t_ma_ctrl.l_is_mret;
    sl_ctrl_is_mret_copy            <= str_exema_stage_reg_out.l_is_mret_copy;
    sl_ctrl_exe_is_branch_inst_copy <= str_idexe_stage_reg_out.l_is_branch_inst_copy;
    sl_ctrl_ma_is_branch_inst_copy  <= str_exema_stage_reg_out.l_is_branch_inst_copy;
    sl_ctrl_ma_is_valid_inst        <= str_exema_stage_reg_out.l_inst_tag;
    sv_ctrl_ma_addr                 <= str_exema_stage_reg_out.v_addr;
    sl_ctrl_inst_raised_trap        <= str_exema_stage_reg_out.l_trap;
    sl_ctrl_ma_branch_taken         <= str_exema_stage_reg_out.l_branch_taken;
    sl_ctrl_ma_is_branch_inst       <= str_exema_stage_reg_out.t_ma_ctrl.l_is_branch_inst;
    sv_ctrl_ma_baddr                <= str_exema_stage_reg_out.v_branch_addr;
    sl_wb_insn_retire               <= str_mawb_stage_reg_out.l_inst_tag;
    sl_ctrl_wb_is_branch_inst_copy  <= str_mawb_stage_reg_out.l_is_branch_inst_copy;
    sl_ctrl_wb_is_valid_inst        <= str_mawb_stage_reg_out.l_inst_tag;
    sl_ctrl_wb_branch_taken         <= str_mawb_stage_reg_out.l_branch_taken;
    sv_ctrl_wb_addr                 <= str_mawb_stage_reg_out.v_addr;

    inst_controller : entity work.controller
        generic map(
            gv_PC_ORIGIN         => cv_PC_ORIGIN,
            gb_RISCV_FORMAL      => cb_RISCV_FORMAL,
            gb_MULTI_CYCLE_FETCH => cb_MULTI_CYCLE_FETCH
        )
        port map(
            pil_clk                     => pil_clk,
            pil_rst                     => pil_rst,
            pil_ctrl_en                 => sl_ctrl_en,
            pil_soft_irq                => pil_soft_irq,
            pil_timer_irq               => pil_timer_irq,
            pil_ext_irq                 => pil_ext_irq,
            pil_fast_irq                => pil_fast_irq,
            piv_fast_irq_id             => piv_fast_irq_id,
            piv_fast_irq_vect           => piv_fast_irq_vect,
            pil_IALIGN_exc0             => sl_IALIGN_exc0,
            pil_ILLINSN_exc2            => sl_ILLINSN_exc2,
            pil_BREAK_exc3              => sl_BREAK_exc3,
            pil_ECALL_exc11             => sl_ECALL_exc11,
            piv_exc_epc                 => sv_exc_epc,
            piv_exc_inst                => sv_exc_inst,
            piv_csr_MEPC                => sv_ctrl_csr_MEPC,
            pitr_csr_MSTATUS            => str_ctrl_csr_MSTATUS,
            pitr_csr_MIE                => str_ctrl_csr_MIE,
            pitr_csr_MTVEC              => str_ctrl_csr_MTVEC,
            pitr_csr_DCSR               => str_ctrl_csr_DCSR,
            piv_csr_DPC                 => sv_ctrl_csr_DPC,
            pol_ctrl_mepc_wen           => sl_ctrl_mepc_wen,
            pov_ctrl_mepc               => sv_ctrl_mepc,
            pol_ctrl_mtval_wen          => sl_ctrl_mtval_wen,
            pov_ctrl_mtval              => sv_ctrl_mtval,
            pol_ctrl_mstatus_wen        => sl_ctrl_mstatus_wen,
            pov_ctrl_mstatus            => sv_ctrl_mstatus,
            pol_ctrl_mcause_wen         => sl_ctrl_mcause_wen,
            pov_ctrl_mcause             => sv_ctrl_mcause,
            pov_ctrl_mip                => sv_ctrl_mip,
            pol_ctrl_dcsr_wen           => sl_ctrl_dcsr_wen,
            pov_ctrl_dcsr               => sv_ctrl_dcsr,
            pol_ctrl_dpc_wen            => sl_ctrl_dpc_wen,
            pov_ctrl_dpc                => sv_ctrl_dpc,
            pol_rvfi_intr               => sl_ctrl_rvfi_intr,
            pol_exc_ben                 => sl_ctrl_exc_ben,
            pov_exc_baddr               => sv_ctrl_exc_baddr,
            pol_irq_pin_pending         => sl_ctrl_irq_pin_pending,
            pol_csr_halt_bypass         => sl_ctrl_csr_halt_bypass,
            pil_trigger_match           => sl_ctrl_trigger_match,
            pil_debug_haltreq           => pil_debug_haltreq,
            pil_debug_resumereq         => pil_debug_resumereq,
            pol_debug_mode              => sl_ctrl_debug_mode,
            pol_debug_havereset         => sl_ctrl_debug_havereset,
            pol_debug_running           => sl_ctrl_debug_running,
            pol_debug_halted            => sl_ctrl_debug_halted,
            pil_debug_regreq            => pil_debug_regreq,
            piv_debug_regno             => piv_debug_regno,
            pil_debug_write             => pil_debug_write,
            piv_debug_wdata             => piv_debug_wdata,
            pol_debug_ack               => sl_ctrl_debug_ack,
            pol_debug_err               => sl_ctrl_debug_err,
            pov_debug_rdata             => sv_ctrl_debug_rdata,
            pol_access_req              => sl_ctrl_access_req,
            pov_access_regno            => sv_ctrl_access_regno,
            piv_access_gpr_rdata        => sv_ctrl_access_gpr_rdata,
            piv_access_csr_rdata        => sv_ctrl_access_csr_rdata,
            pil_access_csr_err          => sl_ctrl_access_csr_err,
            pol_access_gpr_wen          => sl_ctrl_access_gpr_wen,
            pol_access_csr_wen          => sl_ctrl_access_csr_wen,
            pov_access_wdata            => sv_ctrl_access_wdata,
            pol_is_in_debug_mode        => sl_ctrl_is_in_debug_mode,
            pol_irq_regfile_sel         => sl_ctrl_irq_regfile_sel,
            pol_ignore_irq_regile       => sl_ctrl_ignore_irq_regfile,
            pol_pipe_start              => sl_ctrl_pipe_start,
            pol_illegal_inst_en_chk     => sl_ctrl_illegal_inst_en_chk,
            pol_rvfi_ld_hazard_end      => sl_ctrl_rvfi_ld_hazard_end,
            pitv_ifid_rs1_addr          => stv_ctrl_ifid_rs1_addr,
            pitv_ifid_rs2_addr          => stv_ctrl_ifid_rs2_addr,
            pitv_idexe_rd_addr          => stv_ctrl_idexe_rd_addr,
            pil_idexe_mem_req           => sl_ctrl_idexe_mem_req,
            pil_idexe_mem_wen           => sl_ctrl_idexe_mem_wen,
            pil_prefetch_stall          => sl_ctrl_prefetch_stall,
            pil_if_cen                  => sl_ctrl_if_cen,
            pil_ifid_nop_inst           => sl_ctrl_ifid_nop_inst_in,
            pol_if_stall                => sl_ctrl_if_stall,
            pol_if_ben                  => sl_ctrl_if_ben,
            pov_if_baddr                => sv_ctrl_if_baddr,
            pil_ifid_ready              => sl_ctrl_ifid_ready,
            pol_ifid_nop_inst           => sl_ctrl_ifid_nop_inst,
            pil_idexe_nop_inst          => sl_ctrl_idexe_nop_inst,
            pol_step                    => sl_ctrl_step,
            pol_first_fetch             => sl_ctrl_first_fetch,
            piv_id_addr                 => sv_ctrl_id_addr,
            pol_id_stall                => sl_ctrl_id_stall,
            pol_ignore_branch_exe       => sl_ignore_branch_at_exe,
            pol_exe_stall               => sl_ctrl_exe_stall,
            piv_exe_addr                => sv_ctrl_exe_addr,
            piv_exe_inst                => sv_ctrl_exe_inst,
            pil_exe_is_valid_inst       => sl_ctrl_exe_is_valid_inst,
            piv_exe_result              => sv_ctrl_exe_result,
            pil_exe_boff_mux            => sl_ctrl_exe_boff_mux,
            pil_exe_baddr_src_mux       => sl_ctrl_exe_baddr_src_mux,
            pil_exe_is_csr_inst         => sl_ctrl_exe_is_csr_inst,
            pil_is_mret                 => sl_ctrl_is_mret,
            pil_is_mret_copy            => sl_ctrl_is_mret_copy,
            pil_exe_is_branch_inst_copy => sl_ctrl_exe_is_branch_inst_copy,
            pov_exema_baddr             => sv_ctrl_exema_baddr,
            pil_ma_is_branch_inst_copy  => sl_ctrl_ma_is_branch_inst_copy,
            pil_ma_is_valid_inst        => sl_ctrl_ma_is_valid_inst,
            piv_ma_addr                 => sv_ctrl_ma_addr,
            pil_inst_raised_trap        => sl_ctrl_inst_raised_trap,
            pil_ma_branch_taken         => sl_ctrl_ma_branch_taken,
            pil_ma_is_branch_inst       => sl_ctrl_ma_is_branch_inst,
            piv_ma_baddr                => sv_ctrl_ma_baddr,
            pil_wb_insn_retire          => sl_wb_insn_retire,
            pil_wb_is_branch_inst_copy  => sl_ctrl_wb_is_branch_inst_copy,
            pil_wb_is_valid_inst        => sl_ctrl_wb_is_valid_inst,
            pil_wb_branch_taken         => sl_ctrl_wb_branch_taken,
            piv_wb_addr                 => sv_ctrl_wb_addr,
            piv_wb_next_addr            => sv_wb_prog_addr
        );

    -----------------------------------------------------------------------------------------------------
    --------------------------------------- RVF INTERFACE -----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    gen_rvfi_elements : if cb_RISCV_FORMAL = true generate
        assert false report "*** RISCV FORMAL INTERFACE ENABLED ***" severity warning;

        stal_pipe_done(0) <= sl_ctrl_pipe_start and str_ifid_pipe_status_out.l_ready;
        stal_pipe_done(1) <= str_idexe_stage_reg_out.l_inst_tag;
        stal_pipe_done(2) <= str_exema_stage_reg_out.l_inst_tag;
        stal_pipe_done(3) <= str_mawb_stage_reg_out.l_inst_tag;
        stal_pipe_done(4) <= cl_ENABLE; -- After the last stage it is always enable

        proc_rvfi_valid : process (pil_clk, pil_rst)
        begin
            if pil_rst = cl_RESET then
                sl_rvfi_valid <= cl_DISABLE;
            elsif rising_edge(pil_clk) then
                sl_rvfi_valid <= str_mawb_stage_reg_out.l_inst_tag;
            end if;
        end process proc_rvfi_valid;

        sv_rvfi_order <= fv_cnt_order64(stav_rvfi_order(3));
        sv_rvfi_insn  <= str_mawb_stage_reg_out.v_compressed_inst when str_mawb_stage_reg_out.l_is_compressed = cl_ENABLE else
            fv_inst_rec2slv(instruction => str_mawb_stage_reg_out.t_inst);

        sl_rvfi_halt <= cl_DISABLE;

        sl_rvfi_trap <= str_exema_stage_reg_out.l_trap;
        sl_rvfi_intr <= str_exema_stage_reg_out.l_rvfi_intr;
        sv_rvfi_mode <= "11";
        sv_rvfi_ixl  <= "01";

        sv_rvfi_rs1_addr <= str_exema_stage_reg_out.t_inst.v_reg_rs1 when str_exema_stage_reg_out.t_rvfi.l_rs1_ren = cl_ENABLE else
            (others => '0');

        sv_rvfi_rs2_addr <= str_exema_stage_reg_out.t_inst.v_reg_rs2 when str_exema_stage_reg_out.t_rvfi.l_rs2_ren = cl_ENABLE else
            (others => '0');

        sv_rvfi_rs1_rdata <= str_exema_stage_reg_out.v_rvfi_src1 when str_exema_stage_reg_out.t_rvfi.l_rs1_ren = cl_ENABLE else
            (others => '0');

        sv_rvfi_rs2_rdata <= str_exema_stage_reg_out.v_dfu_fw_rsrc2 when (str_exema_stage_reg_out.t_ma_ctrl.l_is_mem_inst = cl_ENABLE and str_exema_stage_reg_out.t_rvfi.l_rs2_ren = cl_ENABLE) else
            str_exema_stage_reg_out.v_rvfi_src2 when str_exema_stage_reg_out.t_rvfi.l_rs2_ren = cl_ENABLE else
            (others => '0');

        sv_rvfi_rd_addr <= str_mawb_stage_reg_out.t_inst.v_reg_rd when str_mawb_stage_reg_out.t_wb_ctrl.l_rd_wen = cl_ENABLE else
            (others => '0');

        sv_rvfi_rd_wdata <= sv_wb_reg_mux when sv_rvfi_rd_addr /= "00000" else
            (others => '0');

        sv_rvfi_pc_rdata <= str_exema_stage_reg_out.v_addr;

        gen_rvfi_pc_wdata_mc : if cb_MULTI_CYCLE_FETCH = true generate
            sv_rvfi_pc_wdata <= str_exema_stage_reg_out.v_branch_addr when (str_exema_stage_reg_out.l_branch_taken = cl_ENABLE and str_exema_stage_reg_out.t_ma_ctrl.l_is_branch_inst = cl_ENABLE) else
                str_ifid_stage_reg_out.v_addr when sl_ctrl_rvfi_ld_hazard_end = cl_ENABLE and str_ifid_stage_reg_out.l_nop_inst = cl_DISABLE and str_ifid_pipe_status_out.l_stb = cl_ENABLE else
                str_ifid_stage_reg_out.v_addr when str_exema_stage_reg_out.t_ma_ctrl.l_CSR_WEN = cl_ENABLE and str_ifid_stage_reg_out.l_nop_inst = cl_DISABLE and str_ifid_pipe_status_out.l_stb = cl_ENABLE else
                sv_ctrl_exc_baddr when str_exema_stage_reg_out.t_ma_ctrl.l_is_mret else
                str_exema_stage_reg_in.v_addr when str_exema_stage_reg_in.l_inst_tag = cl_ENABLE else
                std_logic_vector(unsigned(str_exema_stage_reg_out.v_addr) + 2) when str_exema_stage_reg_out.l_is_compressed = cl_ENABLE else
                std_logic_vector(unsigned(str_exema_stage_reg_out.v_addr) + 4);
        else gen_rvfi_pc_wdata : generate
            sv_rvfi_pc_wdata <= str_exema_stage_reg_out.v_branch_addr when (str_exema_stage_reg_out.l_branch_taken = cl_ENABLE and str_exema_stage_reg_out.t_ma_ctrl.l_is_branch_inst = cl_ENABLE) else
                str_ifid_stage_reg_out.v_addr when sl_ctrl_rvfi_ld_hazard_end = cl_ENABLE and str_ifid_stage_reg_out.l_nop_inst = cl_DISABLE else
                str_ifid_stage_reg_out.v_addr when str_exema_stage_reg_out.t_ma_ctrl.l_CSR_WEN = cl_ENABLE and str_ifid_stage_reg_out.l_nop_inst = cl_DISABLE else
                sv_ctrl_exc_baddr when str_exema_stage_reg_out.t_ma_ctrl.l_is_mret else
                str_exema_stage_reg_in.v_addr when str_exema_stage_reg_in.l_inst_tag = cl_ENABLE else
                std_logic_vector(unsigned(str_exema_stage_reg_out.v_addr) + 2) when str_exema_stage_reg_out.l_is_compressed = cl_ENABLE else
                std_logic_vector(unsigned(str_exema_stage_reg_out.v_addr) + 4);
        end generate;

        sv_rvfi_mem_addr <= str_exema_stage_reg_out.v_mai_addr when str_exema_stage_reg_out.t_ma_ctrl.l_is_mem_inst = cl_ENABLE else
            (others => '0');

        sv_rvfi_mem_rdata <= str_mawb_stage_reg_out.v_mem_data when str_mawb_stage_reg_out.t_wb_ctrl.v_wb_mux = ctr_MUX_wb.wb_memory else
            (others => '0');

        sv_rvfi_mem_wdata <= str_exema_stage_reg_out.v_dfu_fw_rsrc2 when str_exema_stage_reg_out.t_ma_ctrl.l_is_mem_inst = cl_ENABLE else
            (others => '0');

        sv_rvfi_mem_mask <= "1111" when (str_exema_stage_reg_out.t_ma_ctrl.v_data_width_mux = ctr_MUX_mem_data_width.word_sel and str_exema_stage_reg_out.t_ma_ctrl.l_is_mem_inst = cl_ENABLE) else
            "0011" when (str_exema_stage_reg_out.t_ma_ctrl.v_data_width_mux = ctr_MUX_mem_data_width.hword_sel and str_exema_stage_reg_out.t_ma_ctrl.l_is_mem_inst = cl_ENABLE) else
            "0001" when (str_exema_stage_reg_out.t_ma_ctrl.v_data_width_mux = ctr_MUX_mem_data_width.byte_sel and str_exema_stage_reg_out.t_ma_ctrl.l_is_mem_inst = cl_ENABLE) else
            "0000";
        
        proc_rvfi_csr_mask: process (sv_rvfi_rd_wdata, str_mawb_stage_reg_out)
            variable v_csr_addr : std_logic_vector(11 downto 0);
        begin
            sv_rvfi_csr_misa_rmask <= (others => '1'); -- Read all bits
            sv_rvfi_csr_misa_wmask <= (others => '0');
            sv_rvfi_csr_misa_rdata <= str_mawb_stage_reg_out.t_rvfi_csr.v_MISA; -- Current CSR data before csr write
            sv_rvfi_csr_misa_wdata <= (others => '0');

            sv_rvfi_csr_mvendorid_rmask <= (others => '0');
            sv_rvfi_csr_mvendorid_wmask <= (others => '0');
            sv_rvfi_csr_mvendorid_rdata <= (others => '0');
            sv_rvfi_csr_mvendorid_wdata <= (others => '0');

            sv_rvfi_csr_marchid_rmask <= (others => '0');
            sv_rvfi_csr_marchid_wmask <= (others => '0');
            sv_rvfi_csr_marchid_rdata <= (others => '0');
            sv_rvfi_csr_marchid_wdata <= (others => '0');

            sv_rvfi_csr_mimpid_rmask <= (others => '0');
            sv_rvfi_csr_mimpid_wmask <= (others => '0');
            sv_rvfi_csr_mimpid_rdata <= (others => '0');
            sv_rvfi_csr_mimpid_wdata <= (others => '0');

            sv_rvfi_csr_mstatus_rmask <= (others => '0');
            sv_rvfi_csr_mstatus_wmask <= (others => '0');
            sv_rvfi_csr_mstatus_rdata <= (others => '0');
            sv_rvfi_csr_mstatus_wdata <= (others => '0');

            if str_mawb_stage_reg_out.t_inst.v_opcode = cv_IC_SYS and str_mawb_stage_reg_out.t_inst.v_funct3 /= "000" then
                v_csr_addr := str_mawb_stage_reg_out.t_inst.v_funct7 & str_mawb_stage_reg_out.t_inst.v_reg_rs2;
                case v_csr_addr is
                    when cv_ADDR_MISA =>
                        sv_rvfi_csr_misa_rmask <= (others => '1'); -- All bits can be read
                        sv_rvfi_csr_misa_wmask <= (others => '1'); -- All bits are writable
                        sv_rvfi_csr_misa_rdata <= sv_rvfi_rd_wdata;
                        sv_rvfi_csr_misa_wdata <= str_mawb_stage_reg_out.v_csr_wdata;
                    when cv_ADDR_MVENDORID =>
                        sv_rvfi_csr_mvendorid_rmask <= (others => '1'); -- All bits can be read
                        sv_rvfi_csr_mvendorid_wmask <= (others => '0'); -- CSR is not writable
                        sv_rvfi_csr_mvendorid_rdata <= sv_rvfi_rd_wdata;
                        sv_rvfi_csr_mvendorid_wdata <= (others => '0');
                    when cv_ADDR_MARCHID =>
                        sv_rvfi_csr_marchid_rmask <= (others => '1'); -- All bits can be read
                        sv_rvfi_csr_marchid_wmask <= (others => '0'); -- CSR is not writable
                        sv_rvfi_csr_marchid_rdata <= sv_rvfi_rd_wdata;
                        sv_rvfi_csr_marchid_wdata <= (others => '0');
                    when cv_ADDR_MIMPID =>
                        sv_rvfi_csr_mimpid_rmask <= (others => '1'); -- All bits can be read
                        sv_rvfi_csr_mimpid_wmask <= (others => '0'); -- CSR is not writable
                        sv_rvfi_csr_mimpid_rdata <= sv_rvfi_rd_wdata;
                        sv_rvfi_csr_mimpid_wdata <= (others => '0');
                    when cv_ADDR_MSTATUS =>
                        sv_rvfi_csr_mstatus_rmask <= (others => '1'); -- All bits can be read
                        sv_rvfi_csr_mstatus_wmask <= (others => '1'); -- CSR is not writable
                        sv_rvfi_csr_mstatus_rdata <= sv_rvfi_rd_wdata;
                        sv_rvfi_csr_mstatus_wdata <= str_mawb_stage_reg_out.v_csr_wdata;
                    when others =>
                end case;
            end if;
        end process;

        gen_rvfi_pipe : for ii in 0 to 4 generate
            proc_rvfi_pipe : process (pil_clk, pil_rst)
            begin
                if pil_rst = cl_RESET then
                    stav_rvfi_order(ii)               <= (others => '0');
                    stav_rvfi_insn(ii)                <= (others => '0');
                    stal_rvfi_trap(ii)                <= cl_DISABLE;
                    stal_rvfi_halt(ii)                <= cl_DISABLE;
                    stal_rvfi_intr(ii)                <= cl_DISABLE;
                    stav_rvfi_rs1_addr(ii)            <= (others => '0');
                    stav_rvfi_rs2_addr(ii)            <= (others => '0');
                    stav_rvfi_rd_addr(ii)             <= (others => '0');
                    stav_rvfi_rs1_rdata(ii)           <= (others => '0');
                    stav_rvfi_rs2_rdata(ii)           <= (others => '0');
                    stav_rvfi_rd_wdata(ii)            <= (others => '0');
                    stav_rvfi_pc_rdata(ii)            <= (others => '0');
                    stav_rvfi_pc_wdata(ii)            <= (others => '0');
                    stav_rvfi_mem_addr(ii)            <= (others => '0');
                    stav_rvfi_mem_rdata(ii)           <= (others => '0');
                    stav_rvfi_mem_wdata(ii)           <= (others => '0');
                    stav_rvfi_mem_rmask(ii)           <= (others => '0');
                    stav_rvfi_mem_wmask(ii)           <= (others => '0');
                    stav_rvfi_csr_misa_rmask(ii)      <= (others => '0');
                    stav_rvfi_csr_misa_wmask(ii)      <= (others => '0');
                    stav_rvfi_csr_misa_rdata(ii)      <= (others => '0');
                    stav_rvfi_csr_misa_wdata(ii)      <= (others => '0');
                    stav_rvfi_csr_mvendorid_rmask(ii) <= (others => '0');
                    stav_rvfi_csr_mvendorid_wmask(ii) <= (others => '0');
                    stav_rvfi_csr_mvendorid_rdata(ii) <= (others => '0');
                    stav_rvfi_csr_mvendorid_wdata(ii) <= (others => '0');
                    stav_rvfi_csr_marchid_rmask(ii)   <= (others => '0');
                    stav_rvfi_csr_marchid_wmask(ii)   <= (others => '0');
                    stav_rvfi_csr_marchid_rdata(ii)   <= (others => '0');
                    stav_rvfi_csr_marchid_wdata(ii)   <= (others => '0');
                    stav_rvfi_csr_mimpid_rmask(ii)    <= (others => '0');
                    stav_rvfi_csr_mimpid_wmask(ii)    <= (others => '0');
                    stav_rvfi_csr_mimpid_rdata(ii)    <= (others => '0');
                    stav_rvfi_csr_mimpid_wdata(ii)    <= (others => '0');
                    stav_rvfi_csr_mstatus_rmask(ii)   <= (others => '0');
                    stav_rvfi_csr_mstatus_wmask(ii)   <= (others => '0');
                    stav_rvfi_csr_mstatus_rdata(ii)   <= (others => '0');
                    stav_rvfi_csr_mstatus_wdata(ii)   <= (others => '0');
                elsif rising_edge(pil_clk) then
                    if (ii = 0 or ii = 1) then -- ifid_out.ready or idexe_out.inst_tag
                        if stal_pipe_done(ii) = cl_ENABLE then
                            stav_rvfi_order(ii)               <= (others => '0');
                            stav_rvfi_insn(ii)                <= (others => '0');
                            stal_rvfi_trap(ii)                <= cl_DISABLE;
                            stal_rvfi_halt(ii)                <= cl_DISABLE;
                            stal_rvfi_intr(ii)                <= cl_DISABLE;
                            stav_rvfi_rs1_addr(ii)            <= (others => '0');
                            stav_rvfi_rs2_addr(ii)            <= (others => '0');
                            stav_rvfi_rd_addr(ii)             <= (others => '0');
                            stav_rvfi_rs1_rdata(ii)           <= (others => '0');
                            stav_rvfi_rs2_rdata(ii)           <= (others => '0');
                            stav_rvfi_rd_wdata(ii)            <= (others => '0');
                            stav_rvfi_pc_rdata(ii)            <= (others => '0');
                            stav_rvfi_pc_wdata(ii)            <= (others => '0');
                            stav_rvfi_mem_addr(ii)            <= (others => '0');
                            stav_rvfi_mem_rdata(ii)           <= (others => '0');
                            stav_rvfi_mem_wdata(ii)           <= (others => '0');
                            stav_rvfi_mem_rmask(ii)           <= (others => '0');
                            stav_rvfi_mem_wmask(ii)           <= (others => '0');
                            stav_rvfi_csr_misa_rmask(ii)      <= (others => '0');
                            stav_rvfi_csr_misa_wmask(ii)      <= (others => '0');
                            stav_rvfi_csr_misa_rdata(ii)      <= (others => '0');
                            stav_rvfi_csr_misa_wdata(ii)      <= (others => '0');
                            stav_rvfi_csr_mvendorid_rmask(ii) <= (others => '0');
                            stav_rvfi_csr_mvendorid_wmask(ii) <= (others => '0');
                            stav_rvfi_csr_mvendorid_rdata(ii) <= (others => '0');
                            stav_rvfi_csr_mvendorid_wdata(ii) <= (others => '0');
                            stav_rvfi_csr_marchid_rmask(ii)   <= (others => '0');
                            stav_rvfi_csr_marchid_wmask(ii)   <= (others => '0');
                            stav_rvfi_csr_marchid_rdata(ii)   <= (others => '0');
                            stav_rvfi_csr_marchid_wdata(ii)   <= (others => '0');
                            stav_rvfi_csr_mimpid_rmask(ii)    <= (others => '0');
                            stav_rvfi_csr_mimpid_wmask(ii)    <= (others => '0');
                            stav_rvfi_csr_mimpid_rdata(ii)    <= (others => '0');
                            stav_rvfi_csr_mimpid_wdata(ii)    <= (others => '0');
                            stav_rvfi_csr_mstatus_rmask(ii)   <= (others => '0');
                            stav_rvfi_csr_mstatus_wmask(ii)   <= (others => '0');
                            stav_rvfi_csr_mstatus_rdata(ii)   <= (others => '0');
                            stav_rvfi_csr_mstatus_wdata(ii)   <= (others => '0');
                        end if;
                    elsif ii = 2 then -- exema_out.inst_tag
                        if stal_pipe_done(ii) = cl_ENABLE then
                            stav_rvfi_order(ii)     <= (others => '0');
                            stav_rvfi_insn(ii)      <= (others => '0');
                            stal_rvfi_trap(ii)      <= sl_rvfi_trap;
                            stal_rvfi_halt(ii)      <= cl_DISABLE;
                            stal_rvfi_intr(ii)      <= sl_rvfi_intr;
                            stav_rvfi_rs1_addr(ii)  <= sv_rvfi_rs1_addr;
                            stav_rvfi_rs2_addr(ii)  <= sv_rvfi_rs2_addr;
                            stav_rvfi_rd_addr(ii)   <= (others => '0');
                            stav_rvfi_rs1_rdata(ii) <= sv_rvfi_rs1_rdata;
                            stav_rvfi_rs2_rdata(ii) <= sv_rvfi_rs2_rdata;
                            stav_rvfi_rd_wdata(ii)  <= (others => '0');
                            stav_rvfi_pc_rdata(ii)  <= sv_rvfi_pc_rdata;
                            stav_rvfi_pc_wdata(ii)  <= sv_rvfi_pc_wdata;
                            stav_rvfi_mem_addr(ii)  <= sv_rvfi_mem_addr;
                            stav_rvfi_mem_rdata(ii) <= (others => '0');
                            stav_rvfi_mem_wdata(ii) <= sv_rvfi_mem_wdata;
                            if sl_ma_mem_wen = cl_ENABLE then
                                stav_rvfi_mem_wmask(ii) <= sv_rvfi_mem_mask;
                                stav_rvfi_mem_rmask(ii) <= (others => '0');
                            else
                                stav_rvfi_mem_wmask(ii) <= (others => '0');
                                stav_rvfi_mem_rmask(ii) <= sv_rvfi_mem_mask;
                            end if;
                            stav_rvfi_csr_misa_rmask(ii)      <= (others => '0');
                            stav_rvfi_csr_misa_wmask(ii)      <= (others => '0');
                            stav_rvfi_csr_misa_rdata(ii)      <= (others => '0');
                            stav_rvfi_csr_misa_wdata(ii)      <= (others => '0');
                            stav_rvfi_csr_mvendorid_rmask(ii) <= (others => '0');
                            stav_rvfi_csr_mvendorid_wmask(ii) <= (others => '0');
                            stav_rvfi_csr_mvendorid_rdata(ii) <= (others => '0');
                            stav_rvfi_csr_mvendorid_wdata(ii) <= (others => '0');
                            stav_rvfi_csr_marchid_rmask(ii)   <= (others => '0');
                            stav_rvfi_csr_marchid_wmask(ii)   <= (others => '0');
                            stav_rvfi_csr_marchid_rdata(ii)   <= (others => '0');
                            stav_rvfi_csr_marchid_wdata(ii)   <= (others => '0');
                            stav_rvfi_csr_mimpid_rmask(ii)    <= (others => '0');
                            stav_rvfi_csr_mimpid_wmask(ii)    <= (others => '0');
                            stav_rvfi_csr_mimpid_rdata(ii)    <= (others => '0');
                            stav_rvfi_csr_mimpid_wdata(ii)    <= (others => '0');
                            stav_rvfi_csr_mstatus_rmask(ii)   <= (others => '0');
                            stav_rvfi_csr_mstatus_wmask(ii)   <= (others => '0');
                            stav_rvfi_csr_mstatus_rdata(ii)   <= (others => '0');
                            stav_rvfi_csr_mstatus_wdata(ii)   <= (others => '0');
                        end if;
                    elsif ii = 3 then -- mawb_out.inst_tag
                        if stal_pipe_done(ii) = cl_ENABLE then
                            stav_rvfi_order(ii)               <= sv_rvfi_order;
                            stav_rvfi_insn(ii)                <= sv_rvfi_insn;
                            stal_rvfi_trap(ii)                <= stal_rvfi_trap(ii - 1);
                            stal_rvfi_halt(ii)                <= sl_rvfi_halt; -- currently halt is set when a trap occurs
                            stal_rvfi_intr(ii)                <= stal_rvfi_intr(ii - 1);
                            stav_rvfi_rs1_addr(ii)            <= stav_rvfi_rs1_addr(ii - 1);
                            stav_rvfi_rs2_addr(ii)            <= stav_rvfi_rs2_addr(ii - 1);
                            stav_rvfi_rd_addr(ii)             <= sv_rvfi_rd_addr;
                            stav_rvfi_rs1_rdata(ii)           <= stav_rvfi_rs1_rdata(ii - 1);
                            stav_rvfi_rs2_rdata(ii)           <= stav_rvfi_rs2_rdata(ii - 1);
                            stav_rvfi_rd_wdata(ii)            <= sv_rvfi_rd_wdata;
                            stav_rvfi_pc_rdata(ii)            <= stav_rvfi_pc_rdata(ii - 1);
                            stav_rvfi_pc_wdata(ii)            <= stav_rvfi_pc_wdata(ii - 1);
                            stav_rvfi_mem_addr(ii)            <= stav_rvfi_mem_addr(ii - 1);
                            stav_rvfi_mem_rdata(ii)           <= sv_rvfi_mem_rdata;
                            stav_rvfi_mem_wdata(ii)           <= stav_rvfi_mem_wdata(ii - 1);
                            stav_rvfi_mem_rmask(ii)           <= stav_rvfi_mem_rmask(ii - 1);
                            stav_rvfi_mem_wmask(ii)           <= stav_rvfi_mem_wmask(ii - 1);
                            stav_rvfi_csr_misa_rmask(ii)      <= sv_rvfi_csr_misa_rmask;
                            stav_rvfi_csr_misa_wmask(ii)      <= sv_rvfi_csr_misa_wmask;
                            stav_rvfi_csr_misa_rdata(ii)      <= sv_rvfi_csr_misa_rdata;
                            stav_rvfi_csr_misa_wdata(ii)      <= sv_rvfi_csr_misa_wdata;
                            stav_rvfi_csr_mvendorid_rmask(ii) <= sv_rvfi_csr_mvendorid_rmask;
                            stav_rvfi_csr_mvendorid_wmask(ii) <= sv_rvfi_csr_mvendorid_wmask;
                            stav_rvfi_csr_mvendorid_rdata(ii) <= sv_rvfi_csr_mvendorid_rdata;
                            stav_rvfi_csr_mvendorid_wdata(ii) <= sv_rvfi_csr_mvendorid_wdata;
                            stav_rvfi_csr_marchid_rmask(ii)   <= sv_rvfi_csr_marchid_rmask;
                            stav_rvfi_csr_marchid_wmask(ii)   <= sv_rvfi_csr_marchid_wmask;
                            stav_rvfi_csr_marchid_rdata(ii)   <= sv_rvfi_csr_marchid_rdata;
                            stav_rvfi_csr_marchid_wdata(ii)   <= sv_rvfi_csr_marchid_wdata;
                            stav_rvfi_csr_mimpid_rmask(ii)    <= sv_rvfi_csr_mimpid_rmask;
                            stav_rvfi_csr_mimpid_wmask(ii)    <= sv_rvfi_csr_mimpid_wmask;
                            stav_rvfi_csr_mimpid_rdata(ii)    <= sv_rvfi_csr_mimpid_rdata;
                            stav_rvfi_csr_mimpid_wdata(ii)    <= sv_rvfi_csr_mimpid_wdata;
                            stav_rvfi_csr_mstatus_rmask(ii)   <= sv_rvfi_csr_mstatus_rmask;
                            stav_rvfi_csr_mstatus_wmask(ii)   <= sv_rvfi_csr_mstatus_wmask;
                            stav_rvfi_csr_mstatus_rdata(ii)   <= sv_rvfi_csr_mstatus_rdata;
                            stav_rvfi_csr_mstatus_wdata(ii)   <= sv_rvfi_csr_mstatus_wdata;
                        end if;
                    else
                        if stal_pipe_done(ii) = cl_ENABLE then
                            stav_rvfi_order(ii)               <= stav_rvfi_order(ii - 1);
                            stav_rvfi_insn(ii)                <= stav_rvfi_insn(ii - 1);
                            stal_rvfi_trap(ii)                <= stal_rvfi_trap(ii - 1);
                            stal_rvfi_halt(ii)                <= stal_rvfi_halt(ii - 1);
                            stal_rvfi_intr(ii)                <= stal_rvfi_intr(ii - 1);
                            stav_rvfi_rs1_addr(ii)            <= stav_rvfi_rs1_addr(ii - 1);
                            stav_rvfi_rs2_addr(ii)            <= stav_rvfi_rs2_addr(ii - 1);
                            stav_rvfi_rd_addr(ii)             <= stav_rvfi_rd_addr(ii - 1);
                            stav_rvfi_rs1_rdata(ii)           <= stav_rvfi_rs1_rdata(ii - 1);
                            stav_rvfi_rs2_rdata(ii)           <= stav_rvfi_rs2_rdata(ii - 1);
                            stav_rvfi_rd_wdata(ii)            <= stav_rvfi_rd_wdata(ii - 1);
                            stav_rvfi_pc_rdata(ii)            <= stav_rvfi_pc_rdata(ii - 1);
                            stav_rvfi_pc_wdata(ii)            <= stav_rvfi_pc_wdata(ii - 1);
                            stav_rvfi_mem_addr(ii)            <= stav_rvfi_mem_addr(ii - 1);
                            stav_rvfi_mem_rdata(ii)           <= stav_rvfi_mem_rdata(ii - 1);
                            stav_rvfi_mem_wdata(ii)           <= stav_rvfi_mem_wdata(ii - 1);
                            stav_rvfi_mem_rmask(ii)           <= stav_rvfi_mem_rmask(ii - 1);
                            stav_rvfi_mem_wmask(ii)           <= stav_rvfi_mem_wmask(ii - 1);
                            stav_rvfi_csr_misa_rmask(ii)      <= stav_rvfi_csr_misa_rmask(ii - 1);
                            stav_rvfi_csr_misa_wmask(ii)      <= stav_rvfi_csr_misa_wmask(ii - 1);
                            stav_rvfi_csr_misa_rdata(ii)      <= stav_rvfi_csr_misa_rdata(ii - 1);
                            stav_rvfi_csr_misa_wdata(ii)      <= stav_rvfi_csr_misa_wdata(ii - 1);
                            stav_rvfi_csr_mvendorid_rmask(ii) <= stav_rvfi_csr_mvendorid_rmask(ii - 1);
                            stav_rvfi_csr_mvendorid_wmask(ii) <= stav_rvfi_csr_mvendorid_wmask(ii - 1);
                            stav_rvfi_csr_mvendorid_rdata(ii) <= stav_rvfi_csr_mvendorid_rdata(ii - 1);
                            stav_rvfi_csr_mvendorid_wdata(ii) <= stav_rvfi_csr_mvendorid_wdata(ii - 1);
                            stav_rvfi_csr_marchid_rmask(ii)   <= stav_rvfi_csr_marchid_rmask(ii - 1);
                            stav_rvfi_csr_marchid_wmask(ii)   <= stav_rvfi_csr_marchid_wmask(ii - 1);
                            stav_rvfi_csr_marchid_rdata(ii)   <= stav_rvfi_csr_marchid_rdata(ii - 1);
                            stav_rvfi_csr_marchid_wdata(ii)   <= stav_rvfi_csr_marchid_wdata(ii - 1);
                            stav_rvfi_csr_mimpid_rmask(ii)    <= stav_rvfi_csr_mimpid_rmask(ii - 1);
                            stav_rvfi_csr_mimpid_wmask(ii)    <= stav_rvfi_csr_mimpid_wmask(ii - 1);
                            stav_rvfi_csr_mimpid_rdata(ii)    <= stav_rvfi_csr_mimpid_rdata(ii - 1);
                            stav_rvfi_csr_mimpid_wdata(ii)    <= stav_rvfi_csr_mimpid_wdata(ii - 1);
                            stav_rvfi_csr_mstatus_rmask(ii)   <= stav_rvfi_csr_mstatus_rmask(ii - 1);
                            stav_rvfi_csr_mstatus_wmask(ii)   <= stav_rvfi_csr_mstatus_wmask(ii - 1);
                            stav_rvfi_csr_mstatus_rdata(ii)   <= stav_rvfi_csr_mstatus_rdata(ii - 1);
                            stav_rvfi_csr_mstatus_wdata(ii)   <= stav_rvfi_csr_mstatus_wdata(ii - 1);
                        end if;
                    end if;
                end if;
            end process proc_rvfi_pipe;
        end generate;

        rvfi_valid    <= sl_rvfi_valid;
        rvfi_order    <= stav_rvfi_order(4);
        rvfi_insn     <= stav_rvfi_insn(3);
        rvfi_trap     <= stal_rvfi_trap(3);
        rvfi_pc_rdata <= stav_rvfi_pc_rdata(3);
        rvfi_pc_wdata <= stav_rvfi_pc_wdata(3);

        rvfi_halt      <= stal_rvfi_halt(3);
        rvfi_intr      <= stal_rvfi_intr(3);
        rvfi_mode      <= sv_rvfi_mode;
        rvfi_ixl       <= sv_rvfi_ixl;
        rvfi_rs1_addr  <= stav_rvfi_rs1_addr(3);
        rvfi_rs2_addr  <= stav_rvfi_rs2_addr(3);
        rvfi_rs1_rdata <= stav_rvfi_rs1_rdata(3);
        rvfi_rs2_rdata <= stav_rvfi_rs2_rdata(3);
        rvfi_rd_addr   <= stav_rvfi_rd_addr(3);
        rvfi_rd_wdata  <= stav_rvfi_rd_wdata(3);

        rvfi_mem_addr  <= stav_rvfi_mem_addr(3);
        rvfi_mem_rmask <= stav_rvfi_mem_rmask(3);
        rvfi_mem_wmask <= stav_rvfi_mem_wmask(3);
        rvfi_mem_rdata <= stav_rvfi_mem_rdata(3);
        rvfi_mem_wdata <= stav_rvfi_mem_wdata(3);

        rvfi_csr_misa_rmask <= stav_rvfi_csr_misa_rmask(3);
        rvfi_csr_misa_wmask <= stav_rvfi_csr_misa_wmask(3);
        rvfi_csr_misa_rdata <= stav_rvfi_csr_misa_rdata(3);
        rvfi_csr_misa_wdata <= stav_rvfi_csr_misa_wdata(3);

        rvfi_csr_mvendorid_rmask <= stav_rvfi_csr_mvendorid_rmask(3);
        rvfi_csr_mvendorid_wmask <= stav_rvfi_csr_mvendorid_wmask(3);
        rvfi_csr_mvendorid_rdata <= stav_rvfi_csr_mvendorid_rdata(3);
        rvfi_csr_mvendorid_wdata <= stav_rvfi_csr_mvendorid_wdata(3);

        rvfi_csr_marchid_rmask <= stav_rvfi_csr_marchid_rmask(3);
        rvfi_csr_marchid_wmask <= stav_rvfi_csr_marchid_wmask(3);
        rvfi_csr_marchid_rdata <= stav_rvfi_csr_marchid_rdata(3);
        rvfi_csr_marchid_wdata <= stav_rvfi_csr_marchid_wdata(3);

        rvfi_csr_mimpid_rmask <= stav_rvfi_csr_mimpid_rmask(3);
        rvfi_csr_mimpid_wmask <= stav_rvfi_csr_mimpid_wmask(3);
        rvfi_csr_mimpid_rdata <= stav_rvfi_csr_mimpid_rdata(3);
        rvfi_csr_mimpid_wdata <= stav_rvfi_csr_mimpid_wdata(3);

        rvfi_csr_mstatus_rmask <= stav_rvfi_csr_mstatus_rmask(3);
        rvfi_csr_mstatus_wmask <= stav_rvfi_csr_mstatus_wmask(3);
        rvfi_csr_mstatus_rdata <= stav_rvfi_csr_mstatus_rdata(3);
        rvfi_csr_mstatus_wdata <= stav_rvfi_csr_mstatus_wdata(3);
    end generate;

    -----------------------------------------------------------------------------------------------------
    --------------------------------------- MEM INTERFACE -----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    pol_next_inst <= sl_if_cen;
    pol_ben       <= sl_if_ben;

    pov_mem_addr     <= sv_ma_mem_addr;
    pov_mem_wdata    <= sv_ma_mem_wdata;
    pol_mem_req      <= sl_ma_mem_req;
    pol_mem_wen      <= sl_ma_mem_wen;
    pov_mem_byte_sel <= sv_ma_mem_byte_sel;

    -----------------------------------------------------------------------------------------------------
    --------------------------------------- IRQ INTERFACE -----------------------------------------------
    -----------------------------------------------------------------------------------------------------
    
    pol_irq_pending <= sl_ctrl_irq_pin_pending;

    -----------------------------------------------------------------------------------------------------
    -------------------------------------- DEBUG INTERFACE ----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    pol_debug_havereset  <= sl_ctrl_debug_havereset;
    pol_debug_running    <= sl_ctrl_debug_running;
    pol_debug_halted     <= sl_ctrl_debug_halted;

    pol_debug_ack        <= sl_ctrl_debug_ack;
    pol_debug_err        <= sl_ctrl_debug_err;
    pov_debug_rdata      <= sv_ctrl_debug_rdata;
    pov_debug_pc_retired <= sv_pc_retired;

end architecture;
