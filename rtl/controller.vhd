library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.csr_op_unit_pkg.all;

entity controller is
    generic (
        gv_PC_ORIGIN         : std_logic_vector(31 downto 0) := X"0000_0000";
        gb_RISCV_FORMAL      : boolean                       := true;
        gb_MULTI_CYCLE_FETCH : boolean                       := false
    );
    port (
        pil_clk                     : in std_logic;
        pil_rst                     : in std_logic;
        pil_ctrl_en                 : in std_logic;

        -------------------------------------------
        --- Exception, Interrupt input / output ---
        -------------------------------------------

        pil_soft_irq                : in std_logic;
        pil_timer_irq               : in std_logic;
        pil_ext_irq                 : in std_logic;

        pil_fast_irq                : in std_logic;
        piv_fast_irq_id             : in std_logic_vector(3 downto 0);
        piv_fast_irq_vect           : in std_logic_vector(31 downto 0);

        pil_IALIGN_exc0             : in std_logic;
        pil_ILLINSN_exc2            : in std_logic;
        pil_BREAK_exc3              : in std_logic;
        pil_ECALL_exc11             : in std_logic;
        piv_exc_epc                 : in std_logic_vector(31 downto 0);
        piv_exc_inst                : in std_logic_vector(31 downto 0);

        piv_csr_MEPC                : in std_logic_vector(31 downto 0);
        pitr_csr_MSTATUS            : in tr_csr_MSTATUS;
        pitr_csr_MIE                : in tr_csr_MIE;
        pitr_csr_MTVEC              : in tr_csr_MTVEC;
        pitr_csr_DCSR               : in tr_csr_DCSR;
        piv_csr_DPC                 : in std_logic_vector(31 downto 0);

        pol_ctrl_mepc_wen           : out std_logic;
        pov_ctrl_mepc               : out std_logic_vector(31 downto 0);
        pol_ctrl_mtval_wen          : out std_logic;
        pov_ctrl_mtval              : out std_logic_vector(31 downto 0);
        pol_ctrl_mstatus_wen        : out std_logic;
        pov_ctrl_mstatus            : out std_logic_vector(31 downto 0);
        pol_ctrl_mcause_wen         : out std_logic;
        pov_ctrl_mcause             : out std_logic_vector(31 downto 0);
        pov_ctrl_mip                : out std_logic_vector(31 downto 0);
        pol_ctrl_dcsr_wen           : out std_logic;
        pov_ctrl_dcsr               : out std_logic_vector(31 downto 0);
        pol_ctrl_dpc_wen            : out std_logic;
        pov_ctrl_dpc                : out std_logic_vector(31 downto 0);

        pol_rvfi_intr               : out std_logic;
        pol_exc_ben                 : out std_logic;
        pov_exc_baddr               : out std_logic_vector(31 downto 0);

        pol_irq_pin_pending         : out std_logic;
        pol_csr_halt_bypass         : out std_logic;

        --------------------------------------
        --- Debug Interface input / output ---
        --------------------------------------

        pil_trigger_match           : in std_logic;

        pil_debug_haltreq           : in std_logic;
        pil_debug_resumereq         : in std_logic;
        pol_debug_mode              : out std_logic;
        pol_debug_havereset         : out std_logic;
        pol_debug_running           : out std_logic;
        pol_debug_halted            : out std_logic;

        --- Debug abstract reg/CSR access interface ---
        pil_debug_regreq            : in std_logic;
        piv_debug_regno             : in std_logic_vector(11 downto 0);
        pil_debug_write             : in std_logic;
        piv_debug_wdata             : in std_logic_vector(31 downto 0);
        pol_debug_ack               : out std_logic;
        pol_debug_err               : out std_logic;
        pov_debug_rdata             : out std_logic_vector(31 downto 0);

        --- Controller and core reg/CSR interface ---
        pol_access_req              : out std_logic;
        pov_access_regno            : out std_logic_vector(11 downto 0);
        piv_access_gpr_rdata        : in std_logic_vector(31 downto 0);
        piv_access_csr_rdata        : in std_logic_vector(31 downto 0);
        pil_access_csr_err          : in std_logic;
        pol_access_gpr_wen          : out std_logic;
        pol_access_csr_wen          : out std_logic;
        pov_access_wdata            : out std_logic_vector(31 downto 0);

        pol_is_in_debug_mode        : out std_logic;

        --------------------------------------
        --- Pipeline stages input / output ---
        --------------------------------------

        pol_irq_regfile_sel         : out std_logic;
        pol_ignore_irq_regile       : out std_logic;

        pol_pipe_start              : out std_logic;
        pol_illegal_inst_en_chk     : out std_logic; -- illegal_inst_en_chk is actually a delayed core en signal by 1 clock

        pol_rvfi_ld_hazard_end      : out std_logic;

        --- load-use Hazard ditection ---
        pitv_ifid_rs1_addr          : in tv_reg_size;
        pitv_ifid_rs2_addr          : in tv_reg_size;

        pitv_idexe_rd_addr          : in tv_reg_size;
        pil_idexe_mem_req           : in std_logic;
        pil_idexe_mem_wen           : in std_logic;

        --- IF, IF/ID stage ---
        pil_prefetch_stall          : in std_logic;
        pil_if_cen                  : in std_logic;
        pil_ifid_nop_inst           : in std_logic;

        pol_if_stall                : out std_logic;
        pol_if_ben                  : out std_logic;
        pov_if_baddr                : out std_logic_vector(31 downto 0);

        pil_ifid_ready              : in std_logic;
        pol_ifid_nop_inst           : out std_logic;

        pol_step                    : out std_logic;
        pol_first_fetch             : out std_logic;

        --- ID, ID/EXE stage ---
        pil_idexe_nop_inst          : in std_logic;
        piv_id_addr                 : in std_logic_vector(31 downto 0);
        pol_id_stall                : out std_logic;
        pol_ignore_branch_exe       : out std_logic;

        --- EXE, EXE/MA stage ---
        pol_exe_stall               : out std_logic;
        piv_exe_addr                : in std_logic_vector(31 downto 0);
        pil_exe_is_valid_inst       : in std_logic;
        piv_exe_inst                : in std_logic_vector(31 downto 0);
        piv_exe_result              : in std_logic_vector(31 downto 0);
        pil_exe_boff_mux            : in std_logic;
        pil_exe_baddr_src_mux       : in std_logic;
        pil_exe_is_csr_inst         : in std_logic;

        pil_is_mret                 : in std_logic;
        pil_is_mret_copy            : in std_logic;
        pil_exe_is_branch_inst_copy : in std_logic;

        pov_exema_baddr             : out std_logic_vector(31 downto 0);

        --- MA, MA/WB stage ---
        pil_ma_is_branch_inst_copy  : in std_logic;
        pil_ma_is_valid_inst        : in std_logic;
        piv_ma_addr                 : in std_logic_vector(31 downto 0);

        pil_inst_raised_trap        : in std_logic;
        pil_ma_branch_taken         : in std_logic;
        pil_ma_is_branch_inst       : in std_logic;
        piv_ma_baddr                : in std_logic_vector(31 downto 0);

        --- WB stage ---
        pil_ebreak_debug_req        : in std_logic; -- ebreak isnt at wb during dcsr.ebreakm = 1
        pil_wb_insn_retire          : in std_logic;
        pil_wb_is_branch_inst_copy  : in std_logic;
        pil_wb_is_valid_inst        : in std_logic;
        pil_wb_branch_taken         : in std_logic;
        piv_wb_addr                 : in std_logic_vector(31 downto 0);
        piv_wb_next_addr            : in std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of controller is

    signal sl_pipe_start                : std_logic;

    signal sl_ld_hazard                 : std_logic;
    signal sl_illegal_inst_en_chk       : std_logic;

    signal sl_rvfi_ld_hazard_last_state : std_logic;
    signal sl_rvfi_ld_hazard_frame      : std_logic;

    signal sl_if_stall                  : std_logic;
    signal sl_if_ben                    : std_logic;
    signal sl_id_stall                  : std_logic;
    signal sl_exe_stall                 : std_logic;

    signal sl_ifid_nop_inst             : std_logic;

    signal sv_ma_baddr                  : std_logic_vector(31 downto 0);

    signal sl_is_csr_inst_hold          : std_logic; --- holds the value of pil_exe_is_csr_inst for 1 cc.
    signal sl_csr_halt_bypass           : std_logic; --- when '1', the the exe halt will have no effect in
                                                     --  csr writes. This is important when an interrupt
                                                     --  occurs while exe is executing a csr instruction.

    --- signals declared for branch address generation unit ---
    signal su_baddr                     : unsigned(31 downto 0);

    --- signals declared for exception / interrupt control ---
    signal sl_rvfi_intr                 : std_logic;
    signal sl_trapped_inst              : std_logic;

    signal sl_soft_irq                  : std_logic;
    signal sl_timer_irq                 : std_logic;
    signal sl_ext_irq                   : std_logic;
    signal sl_fast_irq                  : std_logic;

    signal sl_exc_detect                : std_logic;

    type t_irq_sync_fsm is (irq_detec_st, soft_irq_process_st, timer_irq_process_st, ext_irq_process_st, fast_irq_process_st, irq_wait_st);
    signal st_irq_sync_fsm              : t_irq_sync_fsm;

    type t_exc_fsm is (exc_detect_st, set_mepc_st, fetch_ready_st, handle_exc_st, irq_pending_st);
    signal st_exc_fsm                   : t_exc_fsm;

    signal sl_irq_regfile_sel           : std_logic;
    signal sl_ignore_irq_regfile        : std_logic;
    signal sl_ignore_branch_at_exe      : std_logic; --- If interrupt is triggered and the current instruction at exe
                                                     --  is a branch/jump instruction then branch_taken signal will be
                                                     --  forced cleared. This is necessary or else the branch address
                                                     --  will overwrite the interrupt vector address.
    signal sl_exc_pipe_flush            : std_logic;

    signal sl_mepc_wen                  : std_logic;
    signal sv_mepc                      : std_logic_vector(31 downto 0);

    signal sl_mtval_wen                 : std_logic;
    signal sv_mtval                     : std_logic_vector(31 downto 0);

    signal sl_mcause_wen                : std_logic;
    signal str_exc_cause                : tr_csr_MCAUSE;

    signal sl_mstatus_wen               : std_logic;
    signal str_mstatus                  : tr_csr_MSTATUS;

    signal sl_dcsr_wen                  : std_logic;
    signal slv_dcsr_cause               : std_logic_vector(2 downto 0);

    signal sl_dpc_wen                   : std_logic;
    signal sv_dpc                       : std_logic_vector(31 downto 0);

    signal sv_mret_addr                 : std_logic_vector(31 downto 0);
    signal sv_exc_handler_addr          : std_logic_vector(31 downto 0);

    signal sl_irq_pending               : std_logic;
    signal sl_exc_pending               : std_logic;
    signal sl_exc_mret                  : std_logic;

    signal sl_exc_ben                   : std_logic;
    signal sv_exc_baddr                 : std_logic_vector(31 downto 0);

    --- controller internal modes ---
    type t_ctrl_fsm is (reset_idle_st, normal_st, debug_baddr_st, pipe_flush_st, debug_st, step_st, wait_sc_step_st, reg_access_st, wait_ack_st);
    signal st_ctrl_fsm                  : t_ctrl_fsm;
    signal sl_step                      : std_logic;
    signal sl_first_fetch               : std_logic;
    signal sl_exc_irq_critical_phase    : std_logic; -- Will be active b/w exc_detect until end of fetch_ready when exc/irq occurs.
                                                     -- At this stage the core will not enter debug mode.
    signal sl_intr_critical_phase       : std_logic; -- During exc/irq critical stage the rvfi intr value will be stored here so that
                                                     -- the debug module can set to back while stepping.
    signal sl_ignore_irq_after_debug    : std_logic; -- When the core just exited the debug mode and if an irq request was under process,
                                                     -- the core in some cases - where there are back to back branch instruction at exe and ma
                                                     -- but the one in ma has to be taken, the core will instead take the branch at exe stage.
                                                     -- To solve this, the core will always ignore any irq right after it exited debug mode.

    signal sl_debug_mode                : std_logic; -- '1' indicates the core is in debug mode. This is to indicate the DM module.
    signal sl_debug_havereset           : std_logic;
    signal sl_debug_mode_req            : std_logic; -- '1' indicates a request to enter debug mode is made
    signal sl_debug_req_pending         : std_logic; -- '1' indicates pending debug req
    signal sl_debug_trigger_match       : std_logic; -- '1' indicates trigger match
    signal sl_ebreak_debug_req          : std_logic; -- '1' indiaces a debug request due to ebreak instruction when dcsr.ebreakm = 1
    signal sv_debug_baddr               : std_logic_vector(31 downto 0);
    signal sv_ebreak_debug_baddr        : std_logic_vector(31 downto 0);

    signal sl_access_req                : std_logic;
    signal sv_access_regno              : std_logic_vector(11 downto 0);
    signal sl_access_csrwen             : std_logic;
    signal sl_access_gprwen             : std_logic;
    signal sv_access_wdata              : std_logic_vector(31 downto 0);
    signal sv_debug_rdata               : std_logic_vector(31 downto 0);
    signal sl_debug_ack                 : std_logic;
    signal sl_debug_err                 : std_logic;

    signal sl_is_in_debug_mode          : std_logic; -- when set the core executes all instruction in debug mode
    signal sl_debug_step_branch_taken   : std_logic;
    signal sl_is_debug_trap             : std_logic;

    type t_debug_req_sync_fsm is (detect_req_st, enter_debug_st, process_debug_st);
    signal st_debug_req_sync_fsm        : t_debug_req_sync_fsm;

begin

    -----------------------------------------------------------------------------------------------------
    ------------------------------ LOAD USE HAZARD DETECT : EXE STAGE -----------------------------------
    -----------------------------------------------------------------------------------------------------

    proc_ld_hazard : process (pil_idexe_mem_req, pil_idexe_mem_wen, pitv_idexe_rd_addr, pitv_ifid_rs1_addr, pitv_ifid_rs2_addr)
    begin
        sl_ld_hazard <= cl_DISABLE;

        if pil_idexe_mem_req = cl_ENABLE and pil_idexe_mem_wen = cl_DISABLE and (pitv_idexe_rd_addr = pitv_ifid_rs1_addr or pitv_idexe_rd_addr = pitv_ifid_rs2_addr) then
            sl_ld_hazard <= cl_ENABLE;
        end if;
    end process proc_ld_hazard;

    gen_rvfi_ld_hazard_end : if gb_RISCV_FORMAL = true generate
        -- The ld_hazard_frame signal is set once the falling edge of ld_hazard signal is detected.
        -- The signal is disabled once ifid_ready is set. During this frame, the if and id stages are
        -- stalled and the next instruction waits in the ifid stage, i.e. the correct PC is in the
        -- ifid stage till the ifid_ready is set.
        proc_clock_hazard_last_state : process (pil_clk, pil_rst)
        begin
            if pil_rst = cl_RESET then
                sl_rvfi_ld_hazard_last_state <= cl_DISABLE;
                sl_rvfi_ld_hazard_frame      <= cl_DISABLE;
            elsif rising_edge(pil_clk) then
                sl_rvfi_ld_hazard_last_state <= sl_ld_hazard;
                if sl_rvfi_ld_hazard_last_state = cl_ENABLE and sl_ld_hazard = cl_DISABLE then
                    sl_rvfi_ld_hazard_frame <= cl_ENABLE; elsif pil_ifid_ready = cl_ENABLE then
                    sl_rvfi_ld_hazard_frame <= cl_DISABLE;
                end if;
            end if;
        end process proc_clock_hazard_last_state;

        pol_rvfi_ld_hazard_end <= sl_rvfi_ld_hazard_frame;
    end generate;

    -----------------------------------------------------------------------------------------------------
    ----------------------------- BRANCH ADDRESS GEN UNIT : EXE STAGE -----------------------------------
    -----------------------------------------------------------------------------------------------------

    proc_baddr_gen : process (pil_exe_boff_mux, piv_exe_addr, piv_exe_inst)
    begin
        if pil_exe_boff_mux = ctr_MUX_branch_offset.UJ_type then
            su_baddr <= unsigned(piv_exe_addr) + unsigned(fv_gen_UJ_offset(instruction => piv_exe_inst));
        else
            su_baddr <= unsigned(piv_exe_addr) + unsigned(fv_gen_SB_offset(instruction => piv_exe_inst));
        end if;
    end process proc_baddr_gen;

    --- The indirect jump instruction JALR (jump and link register) uses the I-type encoding. The target
    --- address is obtained by adding the sign-extended 12-bit I-immediate to the register rs1, then setting
    --- the least-significant bit of the result to zero.
    pov_exema_baddr <= piv_exe_result(31 downto 1) & '0' when pil_exe_baddr_src_mux = ctr_MUX_branch_src_addr.I_type_addr else
        std_logic_vector(su_baddr);

    -----------------------------------------------------------------------------------------------------
    --------------------------------- BRANCH DECISION : MA STAGE ----------------------------------------
    -----------------------------------------------------------------------------------------------------

    proc_illegal_inst : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sl_illegal_inst_en_chk <= cl_DISABLE;
        elsif rising_edge(pil_clk) then
            sl_illegal_inst_en_chk <= sl_pipe_start;
        end if;
    end process proc_illegal_inst;

    sl_trapped_inst <= pil_inst_raised_trap;

    --- Any trapped instruction even if it is a branch instruction, should not actually branch rather will only raise trap.
    --- In case the current instruction is a branch instruction and it raises a trap (due to Misaligend address),
    --- the instruction should not branch. This is made sure by disabling branch when sl_trapped_inst is set.

    sl_if_stall  <= (pil_ma_branch_taken and pil_ma_is_branch_inst and not sl_trapped_inst) or sl_ld_hazard or pil_exe_is_csr_inst or sl_exc_pipe_flush or pil_is_mret or pil_prefetch_stall;
    sl_if_ben    <= pil_ma_branch_taken and pil_ma_is_branch_inst and not sl_trapped_inst;
    sl_id_stall  <= (pil_ma_branch_taken and pil_ma_is_branch_inst and not sl_trapped_inst) or sl_ld_hazard or pil_exe_is_csr_inst or sl_exc_pipe_flush or pil_is_mret or pil_prefetch_stall;
    sl_exe_stall <= (pil_ma_branch_taken and pil_ma_is_branch_inst and not sl_trapped_inst) or sl_exc_pipe_flush or pil_is_mret or pil_prefetch_stall;

    -- Insert a bubble (nop) in ifid stage when a branch is taken.
    -- Also Insert a bubble when the core/pipeline is not enabled. So that no Illegal instruction is encountered initially.
    sl_ifid_nop_inst <= (pil_ma_branch_taken and pil_ma_is_branch_inst and not sl_trapped_inst) or sl_exc_pipe_flush or pil_is_mret or not sl_pipe_start or pil_prefetch_stall;

    sv_ma_baddr <= piv_ma_baddr;

    -----------------------------------------------------------------------------------------------------
    --------------------------------- EXCEPTION / INTERRUPT CTRL ----------------------------------------
    -----------------------------------------------------------------------------------------------------

    ---- Synchronize all IRQ inputs ---
    proc_clocked_irq : process(pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sl_soft_irq     <= cl_DISABLE;
            sl_timer_irq    <= cl_DISABLE;
            sl_ext_irq      <= cl_DISABLE;
            sl_fast_irq     <= cl_DISABLE;
            st_irq_sync_fsm <= irq_detec_st;
        elsif rising_edge(pil_clk) then
            case st_irq_sync_fsm is
                when irq_detec_st =>
                    if pitr_csr_MSTATUS.l_MIE = cl_ENABLE then
                        if pitr_csr_MIE.l_MSIE = cl_ENABLE and pil_soft_irq = cl_ENABLE then
                            sl_soft_irq     <= cl_ENABLE;
                            st_irq_sync_fsm <= soft_irq_process_st;
                        end if;

                        if pitr_csr_MIE.l_MTIE = cl_ENABLE and pil_timer_irq = cl_ENABLE then
                            sl_timer_irq    <= cl_ENABLE;
                            st_irq_sync_fsm <= timer_irq_process_st;
                        end if;

                        if pitr_csr_MIE.l_MEIE = cl_ENABLE and pil_ext_irq = cl_ENABLE then
                            sl_ext_irq      <= cl_ENABLE;
                            st_irq_sync_fsm <= ext_irq_process_st;
                        end if;

                        if pil_fast_irq = cl_ENABLE then
                            sl_fast_irq     <= cl_ENABLE;
                            st_irq_sync_fsm <= fast_irq_process_st;
                        end if;
                    end if;
                when soft_irq_process_st =>
                    if sl_irq_pending = cl_ENABLE and pil_soft_irq = cl_DISABLE then
                        sl_soft_irq     <= pil_soft_irq;
                        st_irq_sync_fsm <= irq_wait_st;
                    end if;
                when timer_irq_process_st =>
                    if sl_irq_pending = cl_ENABLE and pil_timer_irq = cl_DISABLE then
                        sl_timer_irq    <= pil_timer_irq;
                        st_irq_sync_fsm <= irq_wait_st;
                    end if;
                when ext_irq_process_st =>
                    if sl_irq_pending = cl_ENABLE and pil_ext_irq = cl_DISABLE then
                        sl_ext_irq      <= pil_ext_irq;
                        st_irq_sync_fsm <= irq_wait_st;
                    end if;
                when fast_irq_process_st =>
                    if sl_irq_pending = cl_ENABLE and pil_fast_irq = cl_DISABLE then
                        sl_fast_irq     <= pil_fast_irq;
                        st_irq_sync_fsm <= irq_wait_st;
                    end if;
                when irq_wait_st =>
                    st_irq_sync_fsm <= irq_detec_st;
            end case;
        end if;
    end process proc_clocked_irq;

    sl_debug_mode_req <= pil_debug_haltreq or pil_trigger_match or sl_ebreak_debug_req;

    proc_debug_req_sync : process(pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sl_debug_req_pending   <= cl_DISABLE;
            sl_debug_trigger_match <= cl_DISABLE;
            st_debug_req_sync_fsm  <= detect_req_st;
        elsif rising_edge(pil_clk) then
            case st_debug_req_sync_fsm is
                when detect_req_st    =>
                    sl_debug_req_pending       <= cl_DISABLE;
                    sl_debug_trigger_match     <= cl_DISABLE;

                    if sl_debug_mode_req = cl_ENABLE then
                        sl_debug_req_pending   <= cl_ENABLE;
                        sl_debug_trigger_match <= pil_trigger_match;
                        st_debug_req_sync_fsm  <= enter_debug_st;
                    end if;
                when enter_debug_st   =>
                    if sl_is_in_debug_mode = cl_ENABLE then
                        sl_debug_req_pending  <= cl_DISABLE; -- Since the core has already entered the debug mode, pending could deasserted
                        st_debug_req_sync_fsm <= process_debug_st;
                    end if;
                when process_debug_st =>
                    if sl_is_in_debug_mode = cl_DISABLE then
                        st_debug_req_sync_fsm <= detect_req_st;
                    end if;
            end case;
        end if;
    end process proc_debug_req_sync;

    sl_exc_detect     <= pil_IALIGN_exc0 or pil_ILLINSN_exc2 or pil_BREAK_exc3 or pil_ECALL_exc11;

    proc_exc_fsm : process(pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sl_rvfi_intr               <= cl_DISABLE;
            sl_pipe_start              <= cl_DISABLE;
            sl_is_csr_inst_hold        <= cl_DISABLE;
            sl_csr_halt_bypass         <= cl_DISABLE;
            sl_mepc_wen                <= cl_DISABLE;
            sv_mepc                    <= (others => '0');
            sl_mtval_wen               <= cl_DISABLE;
            sv_mtval                   <= (others => '0');
            sl_mcause_wen              <= cl_DISABLE;
            str_exc_cause              <= (l_INT => cl_DISABLE, v_EXC_CODE => (others => '0'));
            sl_mstatus_wen             <= cl_DISABLE;
            str_mstatus                <= (l_MPIE => cl_DISABLE, l_MIE => cl_DISABLE);
            sl_dcsr_wen                <= cl_DISABLE;
            slv_dcsr_cause             <= (others => '0');
            sl_dpc_wen                 <= cl_DISABLE;
            sv_dpc                     <= (others => '0');
            sl_debug_mode              <= cl_DISABLE;
            sl_debug_havereset         <= cl_ENABLE;
            sl_ebreak_debug_req        <= cl_DISABLE;
            sv_ebreak_debug_baddr      <= (others => '0');
            sv_debug_baddr             <= gv_PC_ORIGIN;
            sl_access_req              <= cl_DISABLE;
            sv_access_regno            <= (others => '0');
            sl_access_csrwen           <= cl_DISABLE;
            sl_access_gprwen           <= cl_DISABLE;
            sv_access_wdata            <= (others => '0');
            sv_debug_rdata             <= (others => '0');
            sl_debug_ack               <= cl_DISABLE;
            sl_debug_err               <= cl_DISABLE;
            sl_is_in_debug_mode        <= cl_DISABLE;
            sl_debug_step_branch_taken <= cl_DISABLE;
            sl_is_debug_trap           <= cl_DISABLE;
            sl_step                    <= cl_DISABLE;
            sl_first_fetch             <= cl_DISABLE;
            sl_exc_irq_critical_phase  <= cl_DISABLE;
            sl_intr_critical_phase     <= cl_DISABLE;
            sl_ignore_irq_after_debug  <= cl_DISABLE;
            sl_irq_pending             <= cl_DISABLE;
            sl_exc_pending             <= cl_DISABLE;
            sl_exc_mret                <= cl_DISABLE;
            sl_irq_regfile_sel         <= cl_DISABLE;
            sl_ignore_irq_regfile      <= cl_DISABLE;
            sl_ignore_branch_at_exe    <= cl_DISABLE;
            sl_exc_pipe_flush          <= cl_DISABLE;
            st_exc_fsm                 <= exc_detect_st;
            st_ctrl_fsm                <= reset_idle_st;
        elsif rising_edge(pil_clk) then
            sl_mepc_wen       <= cl_DISABLE;
            sl_mtval_wen      <= cl_DISABLE;
            sl_mcause_wen     <= cl_DISABLE;
            sl_mstatus_wen    <= cl_DISABLE;
            sl_dcsr_wen       <= cl_DISABLE;
            sl_dpc_wen        <= cl_DISABLE;
            sl_access_csrwen  <= cl_DISABLE;
            sl_access_gprwen  <= cl_DISABLE;
            sl_debug_ack      <= cl_DISABLE;
            sl_debug_err      <= cl_DISABLE;
            sl_step           <= cl_DISABLE;
            sl_first_fetch    <= cl_DISABLE;
            sl_irq_pending    <= cl_DISABLE;
            sl_exc_pipe_flush <= cl_DISABLE;

            case st_ctrl_fsm is
                when reset_idle_st  =>
                    sl_debug_step_branch_taken <= cl_DISABLE;
                    sl_debug_havereset         <= cl_ENABLE;
                    sl_debug_mode              <= cl_DISABLE;

                    if sl_debug_req_pending = cl_ENABLE then
                        sl_debug_mode       <= cl_ENABLE;
                        sl_pipe_start       <= cl_ENABLE;
                        sl_is_in_debug_mode <= cl_ENABLE;
                        sv_debug_baddr      <= gv_PC_ORIGIN;

                        sl_dpc_wen          <= cl_ENABLE;
                        sv_dpc              <= gv_PC_ORIGIN; -- BOOT_ADDR: Currently core boots from 0x0

                        sl_dcsr_wen         <= cl_ENABLE;

                        if pil_debug_haltreq = cl_ENABLE then
                            slv_dcsr_cause <= ctr_DEBUG_cause.v_haltreq;
                        elsif sl_debug_trigger_match = cl_ENABLE then
                            slv_dcsr_cause <= ctr_DEBUG_cause.v_trig;
                        else
                            slv_dcsr_cause <= ctr_DEBUG_cause.v_ebreak;
                        end if;

                        sl_exc_pipe_flush      <= cl_ENABLE;
                        st_ctrl_fsm            <= debug_st;
                    elsif pil_ctrl_en = cl_ENABLE then
                        sl_debug_havereset  <= cl_DISABLE;
                        sl_is_in_debug_mode <= cl_DISABLE;
                        sl_pipe_start       <= cl_ENABLE;
                        sl_first_fetch      <= cl_ENABLE;
                        st_ctrl_fsm         <= normal_st;
                    end if;
                when normal_st      =>
                    sl_step                    <= cl_DISABLE;
                    sl_debug_mode              <= cl_DISABLE;
                    sl_is_in_debug_mode        <= cl_DISABLE;
                    sl_access_req              <= cl_DISABLE;
                    sl_ignore_irq_after_debug  <= cl_DISABLE;

                    sl_is_csr_inst_hold <= pil_exe_is_csr_inst;

                    if sl_rvfi_intr = cl_ENABLE and pil_if_cen = cl_ENABLE then
                        sl_rvfi_intr    <= cl_DISABLE;
                    end if;

                    --- Only enter debug mode when the pipeline is ready and core is not in critical phase
                    if sl_debug_req_pending = cl_ENABLE and pil_ifid_ready = cl_ENABLE and sl_exc_irq_critical_phase = cl_DISABLE then
                        sl_is_in_debug_mode <= cl_ENABLE;

                        sl_dcsr_wen         <= cl_ENABLE;

                        --- If the current instruction is a csr instruction, then let it finish by bypassing
                        --- any halt opperation on the csr unit. This is important since the csr operation
                        --- cannot be stopped once it is launched.
                        if pil_exe_is_csr_inst = cl_ENABLE then
                            sl_csr_halt_bypass <= cl_ENABLE;
                        end if;

                        if pil_debug_haltreq = cl_ENABLE then
                            slv_dcsr_cause <= ctr_DEBUG_cause.v_haltreq;
                        elsif sl_debug_trigger_match = cl_ENABLE then
                            slv_dcsr_cause <= ctr_DEBUG_cause.v_trig;
                        else
                            slv_dcsr_cause <= ctr_DEBUG_cause.v_ebreak;
                        end if;

                        sl_exc_pipe_flush   <= cl_ENABLE;
                        st_ctrl_fsm         <= debug_baddr_st;
                    else
                        case st_exc_fsm is
                            when exc_detect_st =>
                                sl_ignore_irq_regfile        <= cl_DISABLE;
                                sl_ignore_branch_at_exe      <= cl_DISABLE;
                                sl_ebreak_debug_req          <= cl_DISABLE;

                                if sl_exc_detect = cl_ENABLE then
                                    if (pil_BREAK_exc3 and pitr_csr_DCSR.l_ebreakm) = cl_ENABLE then
                                        --- Debug request due to ebreak and dcsr.ebreakm = 1 ---
                                        sl_exc_pending            <= cl_ENABLE;
                                        sl_exc_pipe_flush         <= cl_ENABLE;
                                        sl_exc_irq_critical_phase <= cl_ENABLE;
                                        sl_ebreak_debug_req       <= cl_ENABLE;
                                        sv_ebreak_debug_baddr     <= piv_exc_epc;

                                        st_exc_fsm                <= set_mepc_st;
                                    else
                                        --- Exceptions ---
                                        sl_exc_pending            <= cl_ENABLE;
                                        sl_mepc_wen               <= cl_ENABLE;
                                        sv_mepc                   <= piv_exc_epc; -- Save the current PC
                                        sl_mtval_wen              <= cl_ENABLE;
                                        sv_mtval                  <= piv_exc_inst; -- Save the Zero extended lower 16 LSB of ebreak inst

                                        sl_mcause_wen             <= cl_ENABLE;
                                        str_exc_cause.l_INT       <= cl_DISABLE;
                                        sl_mstatus_wen            <= cl_ENABLE;
                                        str_mstatus.l_MPIE        <= pitr_csr_MSTATUS.l_MIE; -- Save MIE state
                                        str_mstatus.l_MIE         <= cl_DISABLE;

                                        st_exc_fsm                <= set_mepc_st;
                                        sl_exc_pipe_flush         <= cl_ENABLE;
                                        sl_exc_irq_critical_phase <= cl_ENABLE;

                                        if pil_ECALL_exc11 = cl_ENABLE then
                                            str_exc_cause.v_EXC_CODE <= ctr_EXC_cause.v_ecall_insn; -- ECALL Instruction
                                        end if;

                                        if pil_IALIGN_exc0 = cl_ENABLE then
                                            str_exc_cause.v_EXC_CODE <= ctr_EXC_cause.v_insn_addr_misaligned; -- Instruction-address misaligned
                                        end if;

                                        if pil_ILLINSN_exc2 = cl_ENABLE then
                                            str_exc_cause.v_EXC_CODE <= ctr_EXC_cause.v_illegal_insn; -- Illegal Instruction
                                        end if;

                                        if pil_BREAK_exc3 = cl_ENABLE then
                                            str_exc_cause.v_EXC_CODE <= ctr_EXC_cause.v_ebreak_insn; -- EBREAK Instruction
                                        end if;
                                    end if;
                                else
                                    --- Machine Interrupts ---
                                    if pitr_csr_MSTATUS.l_MIE = cl_ENABLE and pil_ifid_ready = cl_ENABLE and sl_ignore_irq_after_debug = cl_DISABLE then
                                        if pitr_csr_MIE.l_MSIE = cl_ENABLE then
                                            if sl_soft_irq = cl_ENABLE then
                                                sl_mcause_wen            <= cl_ENABLE;
                                                str_exc_cause.l_INT      <= cl_ENABLE;
                                                str_exc_cause.v_EXC_CODE <= ctr_INT_cause.v_MSI; -- Machine Software Interrupt
                                                sl_mstatus_wen           <= cl_ENABLE;
                                                str_mstatus.l_MPIE       <= pitr_csr_MSTATUS.l_MIE; -- Save MIE state
                                                str_mstatus.l_MIE        <= cl_DISABLE;
                                                st_exc_fsm               <= set_mepc_st;

                                                --- If the current instruction is a csr instruction, then let it finish by bypassing
                                                --- any halt opperation on the csr unit. This is important since the csr operation
                                                --- cannot be stopped once it is launched.
                                                if pil_exe_is_csr_inst = cl_ENABLE then
                                                    sl_csr_halt_bypass <= cl_ENABLE;
                                                end if;

                                                sl_exc_pipe_flush         <= cl_ENABLE;
                                                sl_exc_irq_critical_phase <= cl_ENABLE;
                                            end if;
                                        end if;

                                        if pitr_csr_MIE.l_MTIE = cl_ENABLE then
                                            if sl_timer_irq = cl_ENABLE then
                                                sl_mcause_wen            <= cl_ENABLE;
                                                str_exc_cause.l_INT      <= cl_ENABLE;
                                                str_exc_cause.v_EXC_CODE <= ctr_INT_cause.v_MTI; -- Machine Timer Interrupt
                                                sl_mstatus_wen           <= cl_ENABLE;
                                                str_mstatus.l_MPIE       <= pitr_csr_MSTATUS.l_MIE; -- Save MIE state
                                                str_mstatus.l_MIE        <= cl_DISABLE;
                                                st_exc_fsm               <= set_mepc_st;

                                                --- If the current instruction is a csr instruction, then let it finish by bypassing
                                                --- any halt opperation on the csr unit. This is important since the csr operation
                                                --- cannot be stopped once it is launched.
                                                if pil_exe_is_csr_inst = cl_ENABLE then
                                                    sl_csr_halt_bypass <= cl_ENABLE;
                                                end if;

                                                sl_exc_pipe_flush         <= cl_ENABLE;
                                                sl_exc_irq_critical_phase <= cl_ENABLE;
                                            end if;
                                        end if;

                                        if pitr_csr_MIE.l_MEIE = cl_ENABLE then
                                            if sl_ext_irq = cl_ENABLE then
                                                sl_mcause_wen            <= cl_ENABLE;
                                                str_exc_cause.l_INT      <= cl_ENABLE;
                                                str_exc_cause.v_EXC_CODE <= ctr_INT_cause.v_MEI; -- Machine External Interrupt
                                                sl_mstatus_wen           <= cl_ENABLE;
                                                str_mstatus.l_MPIE       <= pitr_csr_MSTATUS.l_MIE; -- Save MIE state
                                                str_mstatus.l_MIE        <= cl_DISABLE;
                                                st_exc_fsm               <= set_mepc_st;

                                                --- If the current instruction is a csr instruction, then let it finish by bypassing
                                                --- any halt opperation on the csr unit. This is important since the csr operation
                                                --- cannot be stopped once it is launched.
                                                if pil_exe_is_csr_inst = cl_ENABLE then
                                                    sl_csr_halt_bypass <= cl_ENABLE;
                                                end if;

                                                sl_exc_pipe_flush         <= cl_ENABLE;
                                                sl_exc_irq_critical_phase <= cl_ENABLE;
                                            end if;
                                        end if;

                                        if sl_fast_irq = cl_ENABLE then
                                            sl_mcause_wen            <= cl_ENABLE;
                                            str_exc_cause.l_INT      <= cl_ENABLE;
                                            str_exc_cause.v_EXC_CODE <= (30 downto 5 => '0') & '1' & piv_fast_irq_id(3 downto 0); -- Fast Interrupt ID always >= 16 and <32
                                            sl_mstatus_wen           <= cl_ENABLE;
                                            str_mstatus.l_MPIE       <= pitr_csr_MSTATUS.l_MIE; -- Save MIE state
                                            str_mstatus.l_MIE        <= cl_DISABLE;
                                            st_exc_fsm               <= set_mepc_st;

                                            --- If the current instruction is a csr instruction, then let it finish by bypassing
                                            --- any halt opperation on the csr unit. This is important since the csr operation
                                            --- cannot be stopped once it is launched.
                                            if pil_exe_is_csr_inst = cl_ENABLE then
                                                sl_csr_halt_bypass <= cl_ENABLE;
                                            end if;

                                            sl_exc_pipe_flush         <= cl_ENABLE;
                                            sl_exc_irq_critical_phase <= cl_ENABLE;
                                        end if;
                                    end if;
                                end if;

                                if pil_is_mret = cl_ENABLE then
                                    str_mstatus.l_MIE  <= pitr_csr_MSTATUS.l_MPIE;
                                    str_mstatus.l_MPIE <= cl_ENABLE;
                                    sl_mstatus_wen     <= cl_ENABLE;
                                    sl_irq_pending     <= cl_ENABLE;
                                    sl_exc_pipe_flush  <= cl_ENABLE;
                                    st_exc_fsm         <= irq_pending_st;
                                end if;
                            when set_mepc_st   =>
                                sl_exc_pipe_flush <= cl_ENABLE;

                                if sl_exc_pending = cl_DISABLE then
                                    --- i.e. Machine Interrupts ---
                                    -- If current instruction (at exe_stage) is a bubble (initiated by the controller) then it is not a
                                    -- valid instruction to return to. i.e. do not save bubble/nop addr to mepc. UNLESS the last instruction
                                    -- (at ma_stage or at wb_stage) was a branch instruction.
                                    if (pil_ma_is_branch_inst_copy = cl_ENABLE or pil_wb_is_branch_inst_copy = cl_ENABLE) then
                                        sl_mepc_wen <= cl_ENABLE;
                                    else
                                        sl_mepc_wen <= not pil_idexe_nop_inst;
                                    end if;

                                    if pil_ma_is_branch_inst_copy = cl_ENABLE and pil_ma_branch_taken = cl_ENABLE and pil_ma_is_valid_inst = cl_ENABLE then
                                        -- If a branch was taken in the last instruction (i.e. the instruction is ma stage) then
                                        -- the current instruction in exe stage is invalid. So we save the ma branch address in the mepc.
                                        sv_mepc <= piv_ma_addr;
                                        report "BRANCH INSTRUCTION AT MA" severity note;
                                    elsif pil_wb_is_branch_inst_copy = cl_ENABLE and pil_wb_branch_taken = cl_ENABLE and pil_wb_is_valid_inst = cl_ENABLE then
                                        -- If a branch was taken in the 2nd last instruction (i.e. the instruction is already in wb stage) then
                                        -- the current instruction in exe stage is invalid. So we save the wb branch address in the mepc.
                                        sv_mepc <= piv_wb_addr;
                                        report "BRANCH INSTRUCTION AT WB" severity note;
                                    elsif pil_exe_is_branch_inst_copy = cl_ENABLE or pil_is_mret = cl_ENABLE then
                                        -- If the current instruction is a branch instruction, save the current exe_addr as mepc.
                                        -- If the current instruction is MRET, it has not yet updated any CSRs, so it is safe to execute again.
                                        sv_mepc                 <= piv_exe_addr;
                                        sl_ignore_branch_at_exe <= cl_ENABLE; --- If interrupt is triggered and the current instruction at exe
                                                                              --  is a branch/jump instruction then branch_taken signal will be
                                                                              --  forced cleared. This is necessary or else the branch address
                                                                              --  will overwrite the interrupt vector address.
                                        report "BRANCH INSTRUCTION AT EXE" severity note;
                                    elsif sl_is_csr_inst_hold = cl_ENABLE then
                                        -- If the current instruction at exe stage is a csr instruction, it cannot be flushed since it would update
                                        -- the GPR and CSRs. In that case set the return address to the next instruction i.e. piv_id_addr.
                                        sv_mepc <= piv_id_addr;
                                    else
                                        -- When ifid_ready is ENABLE then exc_pipe_flush will insert a bubble in the next clock cycle. This means
                                        -- the instruction in the exe_addr must be executed again after returning from the interrupt handler.
                                        if pil_ifid_ready = cl_ENABLE and pil_idexe_nop_inst = cl_DISABLE then
                                            sv_mepc <= piv_exe_addr;
                                            report "INSTRUCTION AT EXE" severity note;
                                        else
                                            if pil_ifid_nop_inst = cl_DISABLE then
                                                --- mepc will only be updated if the insruction at id stage is not a nop
                                                sl_mepc_wen <= cl_ENABLE;
                                            end if;

                                            sv_mepc <= piv_id_addr;
                                            report "INSTRUCTION AT ID" severity note;
                                        end if;
                                    end if;
                                end if;

                                st_exc_fsm        <= fetch_ready_st;
                            when fetch_ready_st =>
                                sl_is_csr_inst_hold           <= cl_DISABLE;
                                sl_csr_halt_bypass            <= cl_DISABLE;
                                sl_rvfi_intr                  <= cl_ENABLE;
                                sl_intr_critical_phase        <= cl_ENABLE;

                                if sl_fast_irq = cl_ENABLE and sl_exc_pending = cl_DISABLE then
                                    -- Only enable the irq register file if no Exception occurred after fast irq was triggered
                                    sl_irq_regfile_sel    <= cl_ENABLE;
                                end if;

                                if pil_if_cen = cl_ENABLE then
                                    sl_rvfi_intr              <= cl_DISABLE;
                                    sl_ignore_branch_at_exe   <= cl_DISABLE;
                                    sl_exc_irq_critical_phase <= cl_DISABLE;
                                    st_exc_fsm                <= handle_exc_st;
                                end if;
                            when handle_exc_st =>
                                if sl_ebreak_debug_req = cl_ENABLE then
                                    --- This is a special case when ebreak instruction is encountered during dcsr.ebreakm = 1
                                    --- the core never enters the exception_handler. So, once a resume request is received, the
                                    --- debugger would set the st_exc_fsm back to exc_detect_st.
                                    sl_irq_regfile_sel     <= cl_DISABLE;
                                    sl_ignore_irq_regfile  <= cl_ENABLE;
                                    sl_intr_critical_phase <= cl_DISABLE;

                                    sl_exc_pending     <= cl_DISABLE;
                                    -- st_exc_fsm         <= exc_detect_st;
                                elsif pil_is_mret = cl_ENABLE then
                                    sl_exc_pipe_flush  <= cl_ENABLE;
                                    str_mstatus.l_MIE  <= pitr_csr_mstatus.l_MPIE;
                                    str_mstatus.l_MPIE <= cl_ENABLE;
                                    sl_mstatus_wen     <= cl_ENABLE;
                                    st_exc_fsm         <= irq_pending_st;

                                    if sl_exc_pending = cl_ENABLE then
                                        sl_exc_mret <= cl_ENABLE;
                                    else
                                        sl_irq_pending     <= cl_ENABLE;
                                    end if;
                                elsif sl_exc_detect = cl_ENABLE then
                                    --- If exception occurs inside the exception handler, start over again ---
                                    sl_exc_pending           <= cl_ENABLE;
                                    sl_mepc_wen              <= cl_ENABLE;
                                    sv_mepc                  <= piv_exc_epc; -- Save the current PC
                                    sl_mtval_wen             <= cl_ENABLE;
                                    sv_mtval                 <= piv_exc_inst; -- Save the Zero extended lower 16 LSB of ebreak inst

                                    sl_mcause_wen            <= cl_ENABLE;
                                    str_exc_cause.l_INT      <= cl_DISABLE;
                                    sl_mstatus_wen           <= cl_ENABLE;
                                    str_mstatus.l_MPIE       <= pitr_csr_MSTATUS.l_MIE; -- Save MIE state
                                    str_mstatus.l_MIE        <= cl_DISABLE;

                                    st_exc_fsm                <= set_mepc_st;
                                    sl_exc_pipe_flush         <= cl_ENABLE;
                                    sl_exc_irq_critical_phase <= cl_ENABLE;

                                    if pil_ECALL_exc11 = cl_ENABLE then
                                        str_exc_cause.v_EXC_CODE <= ctr_EXC_cause.v_ecall_insn; -- ECALL Instruction
                                    end if;

                                    if pil_IALIGN_exc0 = cl_ENABLE then
                                        str_exc_cause.v_EXC_CODE <= ctr_EXC_cause.v_insn_addr_misaligned; -- Instruction-address misaligned
                                    end if;

                                    if pil_ILLINSN_exc2 = cl_ENABLE then
                                        str_exc_cause.v_EXC_CODE <= ctr_EXC_cause.v_illegal_insn; -- Illegal Instruction
                                    end if;

                                    if pil_BREAK_exc3 = cl_ENABLE then
                                        str_exc_cause.v_EXC_CODE <= ctr_EXC_cause.v_ebreak_insn; -- EBREAK Instruction
                                    end if;
                                end if;
                            when irq_pending_st =>
                                sl_irq_regfile_sel     <= cl_DISABLE;
                                sl_ignore_irq_regfile  <= cl_ENABLE;
                                sl_intr_critical_phase <= cl_DISABLE;

                                if sl_exc_pending = cl_ENABLE then
                                    sl_exc_pending     <= cl_DISABLE;
                                    sl_exc_mret        <= cl_DISABLE;
                                    sl_exc_pipe_flush  <= cl_DISABLE;
                                    st_exc_fsm         <= exc_detect_st;
                                else
                                    --- Make sure the source of Interrupt is cleared before returning to normal state.
                                    sl_irq_pending     <= cl_ENABLE;
                                    sl_exc_pipe_flush  <= cl_ENABLE;
                                    if sl_soft_irq = cl_DISABLE and sl_timer_irq = cl_DISABLE and sl_ext_irq = cl_DISABLE and sl_fast_irq = cl_DISABLE then
                                        sl_irq_pending     <= cl_DISABLE;
                                        sl_exc_pipe_flush  <= cl_DISABLE;
                                        st_exc_fsm         <= exc_detect_st;
                                    end if;
                                end if;
                        end case;
                    end if;
                when debug_baddr_st =>
                    sl_exc_pipe_flush <= cl_ENABLE;
                    sl_rvfi_intr      <= cl_ENABLE;

                    -- In single cycle fetch the controller delays asserting the debug mode cycle till the exe
                    -- instruction has finished executing. In other words, debug mode will be only asserted when no
                    -- instruction exists in the pipeline i.e. the pipeline has been flushed completely.
                    if gb_MULTI_CYCLE_FETCH = false then 
                        sl_debug_mode     <= cl_DISABLE;
                        st_ctrl_fsm       <= pipe_flush_st;
                    else
                        sl_debug_mode     <= cl_ENABLE;
                        st_ctrl_fsm       <= debug_st;
                    end if;

                    if sl_ebreak_debug_req = cl_ENABLE then
                        sl_dpc_wen     <= cl_ENABLE;
                        sv_dpc         <= sv_ebreak_debug_baddr;
                        sv_debug_baddr <= sv_ebreak_debug_baddr;
                        report "DEBUG: ebreak INSTRUCTION AT " & to_hstring(sv_ebreak_debug_baddr) severity note;
                    else
                        -- Since the debug req is an async signal, the logic to store the correct DPC and debug_baddr is
                        -- similar to the Machine Interrupts.
                        if (pil_ma_is_branch_inst_copy = cl_ENABLE or pil_wb_is_branch_inst_copy = cl_ENABLE) then
                            sl_dpc_wen <= cl_ENABLE;
                        else
                            sl_dpc_wen <= not pil_idexe_nop_inst;
                        end if;

                        if pil_ma_is_branch_inst_copy = cl_ENABLE and pil_ma_branch_taken = cl_ENABLE and pil_ma_is_valid_inst = cl_ENABLE then
                            -- If a branch was taken in the last instruction (i.e. the instruction is ma stage) then
                            -- the current instruction in exe stage is invalid. So we save the ma branch address in the dpc.
                            sv_dpc         <= piv_ma_addr;
                            sv_debug_baddr <= piv_ma_addr;
                            report "BRANCH INSTRUCTION AT MA" & to_hstring(piv_ma_addr) severity note;
                        elsif pil_wb_is_branch_inst_copy = cl_ENABLE and pil_wb_branch_taken = cl_ENABLE and pil_wb_is_valid_inst = cl_ENABLE then
                            -- If a branch was taken in the 2nd last instruction (i.e. the instruction is already in wb stage) then
                            -- the current instruction in exe stage is invalid. So we save the wb branch address in the dpc.
                            sv_dpc         <= piv_wb_addr;
                            sv_debug_baddr <= piv_wb_addr;
                            report "BRANCH INSTRUCTION AT WB" & to_hstring(piv_wb_addr) severity note;
                        elsif pil_is_mret_copy = cl_ENABLE then
                            -- If there is an mret instruction at MA stage, it has not updated the mstatus register yet.
                            sv_dpc         <= piv_ma_addr;
                            sv_debug_baddr <= piv_ma_addr;
                            report "MRET AT MA" & to_hstring(piv_ma_addr) severity note;
                        elsif pil_exe_is_branch_inst_copy = cl_ENABLE then
                            -- If the current instruction is a branch instruction, save the current exe_addr as dpc.
                            sv_dpc                  <= piv_exe_addr;
                            sv_debug_baddr          <= piv_exe_addr;
                            sl_ignore_branch_at_exe <= cl_ENABLE; --- If interrupt is triggered and the current instruction at exe
                                                                    --  is a branch/jump instruction then branch_taken signal will be
                                                                    --  forced cleared. This is necessary or else the branch address
                                                                    --  will overwrite the interrupt vector address.
                            report "BRANCH INSTRUCTION AT EXE" & to_hstring(piv_exe_addr) severity note;
                        elsif sl_is_csr_inst_hold = cl_ENABLE then
                            -- If the current instruction at exe stage is a csr instruction, it cannot be flushed since it would update
                            -- the GPR and CSRs. In that case set the return address to the next instruction i.e. piv_id_addr.
                            sv_dpc         <= piv_id_addr;
                            sv_debug_baddr <= piv_id_addr;

                            -- If DPC is not a branch instruction, then the core will execute the next instruction in pipeline.
                            -- Thus the rvfi_intr signal must be disabled.
                            sl_rvfi_intr      <= cl_DISABLE;
                        else
                            -- When ifid_ready is ENABLE then exc_pipe_flush will insert a bubble in the next clock cycle. This means
                            -- the instruction in the exe_addr must be executed again after returning from the interrupt handler.
                            if pil_exe_is_valid_inst = cl_ENABLE and pil_idexe_nop_inst = cl_DISABLE then
                                sv_dpc         <= piv_exe_addr;
                                sv_debug_baddr <= piv_exe_addr;
                                report "INSTRUCTION AT EXE" severity note;
                            else
                                if pil_ifid_nop_inst = cl_DISABLE then
                                    --- dpc will only be updated if the insruction at id stage is not a nop
                                    sl_dpc_wen <= cl_ENABLE;
                                end if;

                                sv_dpc         <= piv_id_addr;
                                sv_debug_baddr <= piv_id_addr;
                                report "INSTRUCTION AT ID" severity note;
                            end if;

                            if st_exc_fsm = irq_pending_st then
                                --- If a debug request has occurred while the core was in exc/irq_pending state, then DPC = MEPC ---
                                sv_dpc         <= piv_csr_MEPC;
                                sv_debug_baddr <= piv_csr_MEPC;
                                -- Make sure that the irq_regile_sel is disabled. This is necessary if the user wants to "step" in
                                -- debug mode. Since the core cannot restore these signals until the controller reaches the normal_st,
                                -- it is necessary to set these signals correctly. 
                                sl_irq_regfile_sel     <= cl_DISABLE;
                                sl_ignore_irq_regfile  <= cl_ENABLE;
                                report "Debug during irq_pending, setting dpc = mepc" severity note;
                            end if;

                            -- If DPC is not a branch instruction, then the core will execute the next instruction in pipeline.
                            -- Thus the rvfi_intr signal must be disabled.
                            sl_rvfi_intr      <= cl_DISABLE;
                        end if;

                        if sl_intr_critical_phase = cl_ENABLE then
                            sl_intr_critical_phase <= cl_DISABLE;
                            sl_rvfi_intr           <= cl_ENABLE; -- Keep the rvfi_intr enabled when entering debug mode from exc/irq critical phase
                        end if;
                    end if;
                when pipe_flush_st  =>
                    sl_is_csr_inst_hold <= cl_DISABLE;
                    sl_csr_halt_bypass  <= cl_DISABLE;
                    sl_exc_pipe_flush   <= cl_ENABLE;

                    if pil_ifid_ready = cl_ENABLE then
                        sl_ignore_branch_at_exe <= cl_DISABLE;
                        st_ctrl_fsm             <= debug_st;
                    end if;
                when debug_st       =>
                    sl_is_csr_inst_hold     <= cl_DISABLE;
                    sl_csr_halt_bypass      <= cl_DISABLE;
                    sl_ignore_branch_at_exe <= cl_DISABLE;
                    sl_exc_pipe_flush       <= cl_ENABLE;
                    sl_debug_mode           <= cl_ENABLE;

                    if pil_debug_regreq = cl_ENABLE then
                        sl_access_req   <= cl_ENABLE;
                        sv_access_wdata <= piv_debug_wdata;
                        sv_access_regno <= piv_debug_regno;

                        if piv_debug_regno(11 downto 9) = "000" then
                            --- debugger wants to access GPR ---
                            sl_access_gprwen <= pil_debug_write;
                        else
                            --- debugger wants to access CSR ---
                            sl_access_csrwen <= pil_debug_write;
                        end if;

                        st_ctrl_fsm     <= reg_access_st;
                    elsif pil_debug_resumereq = cl_ENABLE then
                        sl_debug_havereset <= cl_DISABLE;
                        sl_debug_mode      <= cl_DISABLE;

                        if sl_ebreak_debug_req = cl_ENABLE then
                            sl_ebreak_debug_req <= cl_DISABLE;
                            st_exc_fsm          <= exc_detect_st;
                        end if;

                        if pitr_csr_DCSR.l_step = cl_ENABLE then
                            sl_dcsr_wen       <= cl_ENABLE;
                            slv_dcsr_cause    <= ctr_DEBUG_cause.v_step;
                            sv_debug_baddr    <= piv_csr_DPC;
                            st_ctrl_fsm       <= wait_sc_step_st;
                        else
                            --- In multicycle fetch, the step signal must be set regardless
                            --  whether the DCSR.step is Enabled or Disabled since the step
                            --  signal will enable the fetch interface module to fetch a
                            --  new instruction.
                            --- In signle cycle this is not needed here.
                            if gb_MULTI_CYCLE_FETCH = true then
                                sl_step        <= cl_ENABLE;
                            end if;

                            sl_ignore_irq_after_debug  <= cl_ENABLE;
                            sv_debug_baddr             <= piv_csr_DPC;
                            st_ctrl_fsm                <= normal_st;
                        end if;
                    end if;
                when wait_sc_step_st  =>
                    sl_exc_pipe_flush <= cl_ENABLE;
                    sl_step           <= cl_ENABLE;
                    st_ctrl_fsm       <= step_st;
                when step_st        =>
                    if pil_inst_raised_trap = cl_ENABLE then
                        sl_debug_step_branch_taken <= cl_ENABLE;
                        sl_dpc_wen                 <= cl_ENABLE;
                        sl_is_debug_trap           <= cl_ENABLE;
                        sv_dpc                     <= sv_exc_handler_addr;
                        sv_debug_baddr             <= sv_exc_handler_addr;
                    elsif pil_is_mret = cl_ENABLE then
                        sl_debug_step_branch_taken <= cl_ENABLE;
                        sl_dpc_wen                 <= cl_ENABLE;
                        sv_dpc                     <= sv_mret_addr;
                        sv_debug_baddr             <= sv_mret_addr;

                        str_mstatus.l_MIE          <= pitr_csr_mstatus.l_MPIE;
                        str_mstatus.l_MPIE         <= cl_ENABLE;
                        sl_mstatus_wen             <= cl_ENABLE;

                        --- Important housekeeping of signals when exiting handler in debug mode
                        if sl_exc_pending = cl_DISABLE then
                            --- i.e. Entered handler because of Interrupt
                            sl_irq_pending         <= cl_ENABLE;
                        end if;

                        sl_irq_regfile_sel         <= cl_DISABLE;
                        sl_ignore_irq_regfile      <= cl_ENABLE;
                        sl_exc_pending             <= cl_DISABLE;
                        sl_exc_mret                <= cl_DISABLE;
                        st_exc_fsm                 <= exc_detect_st;
                        ---
                    elsif sl_if_ben = cl_ENABLE then
                        sl_debug_step_branch_taken <= cl_ENABLE;
                        sl_dpc_wen                 <= cl_ENABLE;
                        sv_dpc                     <= piv_ma_baddr;
                        sv_debug_baddr             <= piv_ma_baddr;
                    end if;

                    if pil_wb_insn_retire = cl_ENABLE then
                        -- Only use the branched address when the branch (or mret)
                        -- is taken after execution else load the next_addr
                        if sl_debug_step_branch_taken = cl_DISABLE then
                            sl_dpc_wen     <= cl_ENABLE;
                            sv_dpc         <= piv_wb_next_addr;
                            sv_debug_baddr <= piv_wb_next_addr;
                        end if;

                        -- Stay in the same address as the current instruction is ebreak
                        -- and dcsr.ebreakm = 1.
                        if pil_ebreak_debug_req = cl_ENABLE then
                            sl_dpc_wen     <= cl_ENABLE;
                            sv_dpc         <= piv_wb_addr;
                            sv_debug_baddr <= piv_wb_addr;
                        end if;

                        -- Once the instruction has been executed, it is safe to disable the
                        -- rvfi_intr signal. However if a trap including ebreak/ecall occurred
                        -- then Enable the rvfi_intr for the next instruction as well.
                        if sl_is_debug_trap = cl_ENABLE then
                            sl_is_debug_trap           <= cl_DISABLE;
                            sl_rvfi_intr               <= cl_ENABLE;
                        else
                            sl_rvfi_intr               <= cl_DISABLE;
                        end if;

                        sl_debug_step_branch_taken <= cl_DISABLE;
                        sl_exc_pipe_flush          <= cl_ENABLE;
                        sl_debug_mode              <= cl_ENABLE;
                        st_ctrl_fsm                <= debug_st;
                    end if;
                when reg_access_st =>
                    sl_exc_pipe_flush  <= cl_ENABLE;
                    sl_debug_ack       <= cl_ENABLE;
                    sl_access_req      <= cl_DISABLE;

                    if sv_access_regno(11 downto 9) = "000" then
                        --- debugger wants to access GPR ---
                        sv_debug_rdata <= piv_access_gpr_rdata;
                        sl_debug_err   <= cl_DISABLE;
                    else
                        --- debugger wants to access CSR ---
                        sv_debug_rdata <= piv_access_csr_rdata;
                        sl_debug_err   <= pil_access_csr_err;
                    end if;

                    st_ctrl_fsm        <= wait_ack_st;
                when wait_ack_st =>
                    sl_exc_pipe_flush  <= cl_ENABLE;
                    st_ctrl_fsm        <= debug_st;
            end case;
        end if;
    end process proc_exc_fsm;

    sv_mret_addr        <= piv_csr_MEPC;
    sv_exc_handler_addr <= fv_exc_addr(mtvec => pitr_csr_MTVEC, mcause => str_exc_cause, firq_addr => piv_fast_irq_vect);

    sl_exc_ben   <= sl_exc_pipe_flush;

    --- The exc_baddr will be mret_addr when it is either a mret instruction or the exc_fsm state is still in the pending state.
    --- During this state, the sl_exc_pipe_flush is held high i.e. the core is kept stalled till the IRQ is held low by the source.
    --- This will prevent false interrupt signals due to interrupt source not getting cleared.
    ---
    --- In Debug mode exc_baddr will always be the value in debug_baddr except when mret is detected inside debug mode.
    --- In that case the exc_baddr is sv_mret_addr. This is Only needed since rvfi_pc_wdata is updated immediately in exema stage
    --- where the mret instruction is first detected.
    sv_exc_baddr <= sv_mret_addr when sl_is_in_debug_mode = cl_ENABLE and pil_is_mret = cl_ENABLE else
        sv_debug_baddr when sl_is_in_debug_mode = cl_ENABLE else
        sv_mret_addr when (pil_is_mret = cl_ENABLE or sl_irq_pending = cl_ENABLE or sl_exc_mret = cl_ENABLE) else
        sv_exc_handler_addr;

    --------------------------------------------------------------------------------------------
    -------------------------------------- OUTPUT ----------------------------------------------
    --------------------------------------------------------------------------------------------

    --- Pipeline outputs ---
    pol_pipe_start          <= sl_pipe_start;
    pol_irq_regfile_sel     <= sl_irq_regfile_sel;
    pol_ignore_irq_regile   <= sl_ignore_irq_regfile;

    pol_if_stall            <= sl_if_stall;
    --- During debug mode the regular ben signal will be ignored by the core since branches
    --- will be handled by the exc_ben and exc_baddr signals instead.
    pol_if_ben              <= sl_if_ben when sl_is_in_debug_mode = cl_DISABLE else
        cl_DISABLE;
    pol_id_stall            <= sl_id_stall;
    pol_exe_stall           <= sl_exe_stall;

    pol_ifid_nop_inst       <= sl_ifid_nop_inst;

    pov_if_baddr            <= sv_ma_baddr;

    pol_step                <= sl_step;
    pol_first_fetch         <= sl_first_fetch;

    pol_illegal_inst_en_chk <= sl_illegal_inst_en_chk;

    --- Exception / Interrupts outputs ---
    pol_rvfi_intr           <= sl_rvfi_intr;
    pol_exc_ben             <= sl_exc_ben;
    pov_exc_baddr           <= sv_exc_baddr;

    pol_irq_pin_pending     <= sl_irq_pending;
    pol_csr_halt_bypass     <= sl_csr_halt_bypass;
    pol_ignore_branch_exe   <= sl_ignore_branch_at_exe;

    --- Debug outputs ---
    pol_debug_mode          <= sl_debug_mode;
    pol_debug_havereset     <= sl_debug_havereset;
    pol_debug_running       <= not sl_debug_mode;
    pol_debug_halted        <= sl_debug_mode;

    pol_debug_ack           <= sl_debug_ack;
    pol_debug_err           <= sl_debug_err;
    pov_debug_rdata         <= sv_debug_rdata;

    pol_access_req          <= sl_access_req;
    pov_access_regno        <= sv_access_regno;
    pol_access_gpr_wen      <= sl_access_gprwen;
    pol_access_csr_wen      <= sl_access_csrwen;
    pov_access_wdata        <= sv_access_wdata;

    pol_is_in_debug_mode    <= sl_is_in_debug_mode;

    --- Controller to CSR outputs ---
    pol_ctrl_mepc_wen       <= sl_mepc_wen;
    pov_ctrl_mepc           <= sv_mepc;
    pol_ctrl_mtval_wen      <= sl_mtval_wen;
    pov_ctrl_mtval          <= sv_mtval;
    pol_ctrl_mstatus_wen    <= sl_mstatus_wen;
    pov_ctrl_mstatus        <= (7 => str_mstatus.l_MPIE, 3 => str_mstatus.l_MIE, others => '0');
    pol_ctrl_mcause_wen     <= sl_mcause_wen;
    pov_ctrl_mcause         <= str_exc_cause.l_INT & str_exc_cause.v_EXC_CODE;
    pov_ctrl_mip            <= (11 => sl_ext_irq, 7 => sl_timer_irq, 3 => sl_soft_irq, others => '0');
    pol_ctrl_dcsr_wen       <= sl_dcsr_wen;
    pov_ctrl_dcsr           <= X"4000" & pitr_csr_DCSR.l_ebreakm & "000000" & slv_dcsr_cause & "000" & pitr_csr_DCSR.l_step & "11";
    pol_ctrl_dpc_wen        <= sl_dpc_wen;
    pov_ctrl_dpc            <= sv_dpc;

end architecture;
