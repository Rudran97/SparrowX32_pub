library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.csr_op_unit_pkg.all;

entity csr_op_unit is
    generic (
        gb_EXT_M         : boolean          := true;
        gb_EXT_C         : boolean          := true;
        gv_reg_MVENDORID : std_logic_vector := X"0000_0000";
        gv_reg_MARCHID   : std_logic_vector := X"0600_A033";
        gv_reg_MIMPID    : std_logic_vector := X"0001_0001";
        gv_reg_MHARTID   : std_logic_vector := X"0000_0001"
    );
    port (
        pil_clk                   : in std_logic;
        pil_rst                   : in std_logic;
        piv_exe_addr              : in std_logic_vector(31 downto 0);
        piv_csr_op                : in std_logic_vector(1 downto 0);
        piv_csr_src_data          : in std_logic_vector(31 downto 0);
        piv_csr_raddr             : in std_logic_vector(11 downto 0);
        pov_csr_rdata             : out std_logic_vector(31 downto 0);
        pil_csr_wen               : in std_logic;
        piv_csr_waddr             : in std_logic_vector(11 downto 0);
        piv_csr_wdata             : in std_logic_vector(31 downto 0);
        pov_csr_modify            : out std_logic_vector(31 downto 0); -- Data to be written into the current CSR register
        pol_csr_illegal_access    : out std_logic;
        pol_trigger_match         : out std_logic;

        --- Automatic CPU writes ---
        pil_csr_ctrl_mepc_wen     : in std_logic;
        piv_csr_ctrl_mepc         : in std_logic_vector(31 downto 0);
        pil_csr_ctrl_mtval_wen    : in std_logic;
        piv_csr_ctrl_mtval        : in std_logic_vector(31 downto 0);
        pil_csr_ctrl_minstret_wen : in std_logic;
        piv_csr_ctrl_minstret     : in std_logic_vector(31 downto 0);
        pil_csr_ctrl_mstatus_wen  : in std_logic;
        piv_csr_ctrl_mstatus      : in std_logic_vector(7 downto 0);
        pil_csr_ctrl_mcause_wen   : in std_logic;
        piv_csr_ctrl_mcause       : in std_logic_vector(31 downto 0);
        piv_csr_ctrl_mip          : in std_logic_vector(11 downto 0);
        pil_csr_ctrl_dcsr_wen     : in std_logic;
        piv_csr_ctrl_dcsr         : in std_logic_vector(31 downto 0);
        pil_csr_ctrl_dpc_wen      : in std_logic;
        piv_csr_ctrl_dpc          : in std_logic_vector(31 downto 0);

        --- Exposed CSR ---
        potr_csr : out tr_CSR
    );
end entity;

architecture rtl of csr_op_unit is

    constant cv_MISA        : std_logic_vector(31 downto 0) := fv_gen_misa(c_ext => gb_EXT_C, m_ext => gb_EXT_M);
    constant cv_DCSR        : std_logic_vector(31 downto 0) := (
        30     => cl_ENABLE, -- debugver   : 4          -> Preset
        1      => cl_ENABLE, -- [1..0] prv : 3 (M mode) -> Preset
        0      => cl_ENABLE,
        others => cl_DISABLE
    );

    constant cv_TDATA1      : std_logic_vector(31 downto 0) := (
        29     => cl_ENABLE, -- [31..28] type       : 2 -> Address/Data trigger match 
        27     => cl_ENABLE, -- dmode               : 1 -> Only debug mode writes tdata
        12     => cl_ENABLE, -- data[15..12] action : 1 -> Enter debug mode on trigger 
        6      => cl_ENABLE, -- data[6]           m : 1 -> Only M-mode match is supported
        others => cl_DISABLE
    );
    
    signal sv_reg_MSTATUS   : std_logic_vector(7 downto 0);
    signal sv_val_MSTATUS   : std_logic_vector(7 downto 0);

    signal sv_reg_MISA      : std_logic_vector(31 downto 0);
    signal sv_val_MISA      : std_logic_vector(31 downto 0);

    signal sv_reg_MIE       : std_logic_vector(11 downto 0);
    signal sv_val_MIE       : std_logic_vector(11 downto 0);

    signal sv_reg_MTVEC     : std_logic_vector(31 downto 0);
    signal sv_val_MTVEC     : std_logic_vector(31 downto 0);

    signal sv_reg_MIP       : std_logic_vector(11 downto 0);
    signal sv_val_MIP       : std_logic_vector(11 downto 0);

    signal sv_reg_MCAUSE    : std_logic_vector(31 downto 0);
    signal sv_val_MCAUSE    : std_logic_vector(31 downto 0);

    signal sv_reg_MEPC      : std_logic_vector(31 downto 0);
    signal sv_val_MEPC      : std_logic_vector(31 downto 0);

    signal sv_reg_MSCRATCH  : std_logic_vector(31 downto 0);
    signal sv_val_MSCRATCH  : std_logic_vector(31 downto 0);

    signal sv_reg_MTVAL     : std_logic_vector(31 downto 0);
    signal sv_val_MTVAL     : std_logic_vector(31 downto 0);

    signal sv_reg_MINSTRET  : std_logic_vector(31 downto 0);
    signal sv_val_MINSTRET  : std_logic_vector(31 downto 0);

    signal su_reg_TSELECT   : unsigned(2 downto 0); -- Only supports 8 trigger modules
    signal su_val_TSELECT   : unsigned(2 downto 0);

    type tar_TRIG is array (0 to 7) of tr_trig_module; -- 8 trigger modules
    signal star_reg_TRIG    : tar_TRIG;
    signal star_val_TRIG    : tar_TRIG;

    type tal_trigger_match is array (0 to 7) of std_logic;
    signal stal_trigger_match : tal_trigger_match;

    signal sv_reg_DCSR      : std_logic_vector(31 downto 0);
    signal sv_val_DCSR      : std_logic_vector(31 downto 0);

    signal sv_reg_DPC       : std_logic_vector(31 downto 0);
    signal sv_val_DPC       : std_logic_vector(31 downto 0);

    signal sv_reg_DSCRATCH0 : std_logic_vector(31 downto 0);
    signal sv_val_DSCRATCH0 : std_logic_vector(31 downto 0);

    signal sv_reg_DSCRATCH1 : std_logic_vector(31 downto 0);
    signal sv_val_DSCRATCH1 : std_logic_vector(31 downto 0);

    signal sv_csr_modify    : std_logic_vector(31 downto 0);
    signal sv_csr_rdata     : std_logic_vector(31 downto 0);

    signal sl_illegal_read  : std_logic;
    signal sl_illegal_write : std_logic;

begin

    proc_csr_read : process (piv_csr_raddr, sv_reg_MSTATUS, sv_reg_MISA, sv_reg_MIE, sv_reg_MTVEC, sv_reg_MIP, sv_reg_MCAUSE, sv_reg_MEPC, sv_reg_MSCRATCH, sv_reg_MTVAL, sv_reg_MINSTRET,
        su_reg_TSELECT, star_reg_TRIG,
        sv_reg_DCSR, sv_reg_DPC, sv_reg_DSCRATCH0, sv_reg_DSCRATCH1)
    begin
        sv_csr_rdata    <= (others => '0');
        sl_illegal_read <= cl_DISABLE;

        case piv_csr_raddr is
            when cv_ADDR_MISA =>
                sv_csr_rdata <= sv_reg_MISA;
            when cv_ADDR_MVENDORID =>
                sv_csr_rdata <= gv_reg_MVENDORID;
            when cv_ADDR_MARCHID =>
                sv_csr_rdata <= gv_reg_MARCHID;
            when cv_ADDR_MIMPID =>
                sv_csr_rdata <= gv_reg_MIMPID;
            when cv_ADDR_MHARTID =>
                sv_csr_rdata <= gv_reg_MHARTID;
            when cv_ADDR_MINSTRET =>
                sv_csr_rdata <= sv_reg_MINSTRET;
            when cv_ADDR_MSTATUS =>
                sv_csr_rdata <= (31 downto 8 => '0') & sv_reg_MSTATUS;
            when cv_ADDR_MIE =>
                sv_csr_rdata <= (31 downto 12 => '0') & sv_reg_MIE;
            when cv_ADDR_MTVEC =>
                sv_csr_rdata <= sv_reg_MTVEC;
            when cv_ADDR_MIP =>
                sv_csr_rdata <= (31 downto 12 => '0') & sv_reg_MIP;
            when cv_ADDR_MCAUSE =>
                sv_csr_rdata <= sv_reg_MCAUSE;
            when cv_ADDR_MEPC =>
                sv_csr_rdata <= sv_reg_MEPC;
            when cv_ADDR_MSCRATCH =>
                sv_csr_rdata <= sv_reg_MSCRATCH;
            when cv_ADDR_MTVAL =>
                sv_csr_rdata <= sv_reg_MTVAL;
            when cv_ADDR_TSELECT =>
                sv_csr_rdata <= (31 downto 3 => '0') & std_logic_vector(su_reg_TSELECT);
            when cv_ADDR_TDATA1 =>
                sv_csr_rdata <= star_reg_TRIG(to_integer(su_reg_TSELECT)).v_tdata1;
            when cv_ADDR_TDATA2 =>
                sv_csr_rdata <= star_reg_TRIG(to_integer(su_reg_TSELECT)).v_tdata2;
            when cv_ADDR_TDATA3 =>
                sv_csr_rdata <= (others => '0');
            when cv_ADDR_DCSR =>
                sv_csr_rdata <= sv_reg_DCSR;
            when cv_ADDR_DPC =>
                sv_csr_rdata <= sv_reg_DPC;
            when cv_ADDR_DSCRATCH0 =>
                sv_csr_rdata <= sv_reg_DSCRATCH0;
            when cv_ADDR_DSCRATCH1 =>
                sv_csr_rdata <= sv_reg_DSCRATCH1;
            when others =>
                sv_csr_rdata    <= (others => '0');
                sl_illegal_read <= cl_ENABLE;
        end case;
    end process proc_csr_read;

    proc_csr_write : process (piv_csr_waddr, piv_csr_wdata, pil_csr_wen, pil_csr_ctrl_mstatus_wen, pil_csr_ctrl_mcause_wen, pil_csr_ctrl_mepc_wen, pil_csr_ctrl_mtval_wen, pil_csr_ctrl_minstret_wen,
        piv_csr_ctrl_mstatus, piv_csr_ctrl_mcause, piv_csr_ctrl_mip, piv_csr_ctrl_mepc, piv_csr_ctrl_mtval, piv_csr_ctrl_minstret, sv_reg_MSTATUS, sv_reg_MISA, sv_reg_MIE, sv_reg_MTVEC, sv_reg_MIP, sv_reg_MCAUSE,
        sv_reg_MEPC, sv_reg_MSCRATCH, sv_reg_MTVAL, sv_reg_MINSTRET,
        su_reg_TSELECT, star_reg_TRIG,
        pil_csr_ctrl_dcsr_wen, pil_csr_ctrl_dpc_wen, piv_csr_ctrl_dcsr, piv_csr_ctrl_dpc, sv_reg_DCSR, sv_reg_DPC, sv_reg_DSCRATCH0, sv_reg_DSCRATCH1)
    begin
        sv_val_MINSTRET           <= sv_reg_MINSTRET;
        sv_val_MSTATUS            <= sv_reg_MSTATUS;
        sv_val_MISA               <= sv_reg_MISA;
        sv_val_MIE                <= sv_reg_MIE;
        sv_val_MTVEC              <= sv_reg_MTVEC;
        sv_val_MIP                <= sv_reg_MIP;
        sv_val_MCAUSE             <= sv_reg_MCAUSE;
        sv_val_MEPC               <= sv_reg_MEPC;
        sv_val_MSCRATCH           <= sv_reg_MSCRATCH;
        sv_val_MTVAL              <= sv_reg_MTVAL;
        su_val_TSELECT            <= su_reg_TSELECT;
        for ii in 0 to 7 loop
            star_val_TRIG(ii).v_tdata1 <= star_reg_TRIG(ii).v_tdata1;
            star_val_TRIG(ii).v_tdata2 <= star_reg_TRIG(ii).v_tdata2;
        end loop;
        sv_val_DCSR               <= sv_reg_DCSR;
        sv_val_DPC                <= sv_reg_DPC;
        sv_val_DSCRATCH0          <= sv_reg_DSCRATCH0;
        sv_val_DSCRATCH1          <= sv_reg_DSCRATCH1;

        sl_illegal_write          <= cl_DISABLE;

        case piv_csr_waddr is
            when cv_ADDR_MINSTRET =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_MINSTRET <= piv_csr_wdata;
                end if;
            when cv_ADDR_MSTATUS =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_MSTATUS <= piv_csr_wdata(7 downto 0) and cv_MSTATUS_warl;
                end if;
            when cv_ADDR_MISA =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_MISA <= cv_MISA or (piv_csr_wdata and cv_MISA_warl); -- Mask XLEN, M, I, C
                end if;
            when cv_ADDR_MIE =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_MIE <= piv_csr_wdata(11 downto 0) and cv_MIE_warl;
                end if;
            when cv_ADDR_MTVEC =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_MTVEC <= piv_csr_wdata and cv_MTVEC_warl; -- Bits 6..2 will always be 0
                end if;
            when cv_ADDR_MIP =>
                --- mip bits [MEIP, MTIP and MSIP] are read-only ---
            when cv_ADDR_MCAUSE =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_MCAUSE <= piv_csr_wdata;
                end if;
            when cv_ADDR_MEPC =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_MEPC <= piv_csr_wdata(31 downto 1) & '0'; -- mepc[0] is always 0
                end if;
            when cv_ADDR_MSCRATCH =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_MSCRATCH <= piv_csr_wdata;
                end if;
            when cv_ADDR_MTVAL =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_MTVAL <= piv_csr_wdata;
                end if;
            when cv_ADDR_TSELECT =>
                if pil_csr_wen = cl_ENABLE then
                    su_val_TSELECT <= unsigned(piv_csr_wdata(2 downto 0));
                end if;
            when cv_ADDR_TDATA1  =>
                if pil_csr_wen = cl_ENABLE then
                    star_val_TRIG(to_integer(su_reg_TSELECT)).v_tdata1 <= cv_TDATA1 or (piv_csr_wdata and cv_TDATA1_warl);
                end if;
            when cv_ADDR_TDATA2  =>
                if pil_csr_wen = cl_ENABLE then
                    star_val_TRIG(to_integer(su_reg_TSELECT)).v_tdata2 <= piv_csr_wdata;
                end if;
            when cv_ADDR_TDATA3  =>
                --- TODO: This register is currently not in use ---
            when cv_ADDR_DCSR =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_DCSR <= cv_DCSR or (piv_csr_wdata and cv_DCSR_warl);
                end if;
            when cv_ADDR_DPC =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_DPC <= piv_csr_wdata;
                end if;
            when cv_ADDR_DSCRATCH0 =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_DSCRATCH0 <= piv_csr_wdata;
                end if;
            when cv_ADDR_DSCRATCH1 =>
                if pil_csr_wen = cl_ENABLE then
                    sv_val_DSCRATCH1 <= piv_csr_wdata;
                end if;
            when others =>
                sl_illegal_write <= cl_DISABLE;
        end case;

        if pil_csr_ctrl_minstret_wen = cl_ENABLE then
            sv_val_MINSTRET <= piv_csr_ctrl_minstret;
        end if;

        if pil_csr_ctrl_mstatus_wen = cl_ENABLE then
            sv_val_MSTATUS <= piv_csr_ctrl_mstatus;
        end if;

        if pil_csr_ctrl_mcause_wen = cl_ENABLE then
            sv_val_MCAUSE <= piv_csr_ctrl_mcause;
        end if;

        sv_val_MIP <= piv_csr_ctrl_mip;

        if pil_csr_ctrl_mepc_wen = cl_ENABLE then
            sv_val_MEPC <= piv_csr_ctrl_mepc;
        end if;

        if pil_csr_ctrl_mtval_wen = cl_ENABLE then
            sv_val_MTVAL <= piv_csr_ctrl_mtval;
        end if;

        if pil_csr_ctrl_dcsr_wen = cl_ENABLE then
            sv_val_DCSR <= piv_csr_ctrl_dcsr;
        end if;

        if pil_csr_ctrl_dpc_wen = cl_ENABLE then
            sv_val_DPC <= piv_csr_ctrl_dpc;
        end if;
    end process proc_csr_write;

    proc_csr_reg : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sv_reg_MINSTRET           <= (others => '0');
            sv_reg_MSTATUS            <= (others => '0');
            sv_reg_MISA               <= cv_MISA; 
            sv_reg_MIE                <= (others => '0');
            sv_reg_MTVEC              <= (others => '0');
            sv_reg_MIP                <= (others => '0');
            sv_reg_MCAUSE             <= (others => '0');
            sv_reg_MEPC               <= (others => '0');
            sv_reg_MSCRATCH           <= (others => '0');
            sv_reg_MTVAL              <= (others => '0');
            su_reg_TSELECT            <= (others => '0');
            for ii in 0 to 7 loop
                star_reg_TRIG(ii).v_tdata1 <= cv_TDATA1;
                star_reg_TRIG(ii).v_tdata2 <= (others => '0');
            end loop;
            sv_reg_DCSR               <= cv_DCSR;
            sv_reg_DPC                <= (others => '0');
            sv_reg_DSCRATCH0          <= (others => '0');
            sv_reg_DSCRATCH1          <= (others => '0');
        elsif rising_edge(pil_clk) then
            sv_reg_MINSTRET           <= sv_val_MINSTRET;
            sv_reg_MSTATUS            <= sv_val_MSTATUS;
            sv_reg_MISA               <= sv_val_MISA;
            sv_reg_MIE                <= sv_val_MIE;
            sv_reg_MTVEC              <= sv_val_MTVEC;
            sv_reg_MIP                <= sv_val_MIP;
            sv_reg_MCAUSE             <= sv_val_MCAUSE;
            sv_reg_MEPC               <= sv_val_MEPC;
            sv_reg_MSCRATCH           <= sv_val_MSCRATCH;
            sv_reg_MTVAL              <= sv_val_MTVAL;
            su_reg_TSELECT            <= su_val_TSELECT;
            for ii in 0 to 7 loop
                star_reg_TRIG(ii).v_tdata1 <= star_val_TRIG(ii).v_tdata1;
                star_reg_TRIG(ii).v_tdata2 <= star_val_TRIG(ii).v_tdata2;
            end loop;
            sv_reg_DCSR               <= sv_val_DCSR;
            sv_reg_DPC                <= sv_val_DPC;
            sv_reg_DSCRATCH0          <= sv_val_DSCRATCH0;
            sv_reg_DSCRATCH1          <= sv_val_DSCRATCH1;
        end if;
    end process proc_csr_reg;

    proc_csr_op : process (piv_csr_op, sv_csr_rdata, piv_csr_src_data)
    begin
        case piv_csr_op is
            when cv_csr_W =>
                sv_csr_modify <= piv_csr_src_data;
            when cv_csr_S =>
                sv_csr_modify <= sv_csr_rdata or piv_csr_src_data;
            when cv_csr_C =>
                sv_csr_modify <= sv_csr_rdata and not piv_csr_src_data;
            when others             =>
                sv_csr_modify <= (others => '0');
        end case;
    end process proc_csr_op;

    gen_trigger_match : for ii in 0 to 7 generate -- 2 trigger match
        stal_trigger_match(ii) <= cl_ENABLE when (star_reg_TRIG(ii).v_tdata1(2) = cl_ENABLE and (piv_exe_addr = star_reg_TRIG(ii).v_tdata2)) else
            cl_DISABLE;
    end generate;

    pov_csr_rdata          <= sv_csr_rdata;
    pov_csr_modify         <= sv_csr_modify;
    pol_csr_illegal_access <= sl_illegal_write when pil_csr_wen = cl_ENABLE else
        sl_illegal_read;
    pol_trigger_match      <= stal_trigger_match(7) or
        stal_trigger_match(6) or
        stal_trigger_match(5) or
        stal_trigger_match(4) or
        stal_trigger_match(3) or
        stal_trigger_match(2) or
        stal_trigger_match(1) or
        stal_trigger_match(0);

    potr_csr.v_MISA      <= sv_reg_MISA;
    potr_csr.v_MVENDORID <= gv_reg_MVENDORID;
    potr_csr.v_MARCHID   <= gv_reg_MARCHID;
    potr_csr.v_MIMPID    <= gv_reg_MIMPID;
    potr_csr.v_MHARTID   <= gv_reg_MHARTID;
    potr_csr.v_MINSTRET  <= sv_reg_MINSTRET;
    potr_csr.v_MSTATUS   <= X"000000" & sv_reg_MSTATUS;
    potr_csr.v_MIE       <= X"00000" & sv_reg_MIE;
    potr_csr.v_MTVEC     <= sv_reg_MTVEC;
    potr_csr.v_MIP       <= X"00000" & sv_reg_MIP;
    potr_csr.v_MCAUSE    <= sv_reg_MCAUSE;

    -- From riscv_priv_isa:
    -- If an implementation allows IALIGN to be either 16 or 32 (by changing CSR misa, for example), then,
    -- whenever IALIGN=32, bit mepc[1] is masked on reads so that it appears to be 0. This masking occurs
    -- also for the implicit read by the MRET instruction. Though masked, mepc[1] remains writable when
    -- IALIGN=32.
    gen_mepc_IALIGN16 : if gb_EXT_C = true generate
        potr_csr.v_MEPC     <= sv_reg_MEPC;
    else gen_mepc_IALIGN32 : generate
        potr_csr.v_MEPC     <= sv_reg_MEPC(31 downto 2) & "00";
    end generate;
    
    potr_csr.v_MSCRATCH  <= sv_reg_MSCRATCH;
    potr_csr.v_MTVAL     <= sv_reg_MTVAL;
    potr_csr.v_TSELECT   <= (31 downto 3 => '0') & std_logic_vector(su_reg_TSELECT);
    potr_csr.v_TDATA1    <= star_reg_TRIG(to_integer(su_reg_TSELECT)).v_tdata1;
    potr_csr.v_TDATA2    <= star_reg_TRIG(to_integer(su_reg_TSELECT)).v_tdata2;
    potr_csr.v_DCSR      <= sv_reg_DCSR;
    potr_csr.v_DPC       <= sv_reg_DPC;
    potr_csr.v_DSCRATCH0 <= sv_reg_DSCRATCH0;
    potr_csr.v_DSCRATCH1 <= sv_reg_DSCRATCH1;

end architecture;
