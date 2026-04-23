library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

package csr_op_unit_pkg is

    -----------------------------------------------------------------------------------------------------
    -----------------------------------------CSR OPERATIONS----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    constant cv_csr_W : std_logic_vector(1 downto 0) := "01";
    constant cv_csr_S : std_logic_vector(1 downto 0) := "10";
    constant cv_csr_C : std_logic_vector(1 downto 0) := "11";

    -----------------------------------------------------------------------------------------------------
    ---------------------------------CS-Register Field Definition----------------------------------------
    -----------------------------------------------------------------------------------------------------

    type tr_csr_MSTATUS is record
        l_MIE  : std_logic;
        l_MPIE : std_logic;
    end record tr_csr_MSTATUS;

    type tr_csr_MIE is record
        l_MSIE : std_logic;
        l_MTIE : std_logic;
        l_MEIE : std_logic;
    end record tr_csr_MIE;

    type tr_csr_MTVEC is record
        v_MODE : std_logic_vector(1 downto 0);
        v_BASE : std_logic_vector(29 downto 0);
    end record tr_csr_MTVEC;

    type tr_csr_MIP is record
        l_MSIP : std_logic;
        l_MTIP : std_logic;
        l_MEIP : std_logic;
    end record tr_csr_MIP;

    type tr_csr_MCAUSE is record
        v_EXC_CODE : std_logic_vector(30 downto 0);
        l_INT      : std_logic;
    end record tr_csr_MCAUSE;

    type tr_trig_module is record
        v_tdata1 : std_logic_vector(31 downto 0);
        v_tdata2 : std_logic_vector(31 downto 0);
    end record;

    -----------------------------------------------------------------------------------------------------
    ------------------------------Debug CS-Register Field Definition-------------------------------------
    -----------------------------------------------------------------------------------------------------

    type tr_csr_DCSR is record
        l_step    : std_logic;
        v_cause   : std_logic_vector(2 downto 0);
        l_ebreakm : std_logic;
    end record tr_csr_DCSR;

    -----------------------------------------------------------------------------------------------------
    -----------------------------General Constants / Types / Functions-----------------------------------
    -----------------------------------------------------------------------------------------------------

    constant cv_ADDR_MISA      : std_logic_vector(11 downto 0) := X"301";
    constant cv_ADDR_MVENDORID : std_logic_vector(11 downto 0) := X"F11";
    constant cv_ADDR_MARCHID   : std_logic_vector(11 downto 0) := X"F12";
    constant cv_ADDR_MIMPID    : std_logic_vector(11 downto 0) := X"F13";
    constant cv_ADDR_MHARTID   : std_logic_vector(11 downto 0) := X"F14";
    constant cv_ADDR_MINSTRET  : std_logic_vector(11 downto 0) := X"B02";
    constant cv_ADDR_MSTATUS   : std_logic_vector(11 downto 0) := X"300";
    constant cv_ADDR_MIE       : std_logic_vector(11 downto 0) := X"304";
    constant cv_ADDR_MTVEC     : std_logic_vector(11 downto 0) := X"305";
    constant cv_ADDR_MIP       : std_logic_vector(11 downto 0) := X"344";
    constant cv_ADDR_MCAUSE    : std_logic_vector(11 downto 0) := X"342";
    constant cv_ADDR_MEPC      : std_logic_vector(11 downto 0) := X"341";
    constant cv_ADDR_MSCRATCH  : std_logic_vector(11 downto 0) := X"340";
    constant cv_ADDR_MTVAL     : std_logic_vector(11 downto 0) := X"343";

    constant cv_ADDR_TSELECT   : std_logic_vector(11 downto 0) := X"7A0";
    constant cv_ADDR_TDATA1    : std_logic_vector(11 downto 0) := X"7A1";
    constant cv_ADDR_TDATA2    : std_logic_vector(11 downto 0) := X"7A2";
    constant cv_ADDR_TDATA3    : std_logic_vector(11 downto 0) := X"7A3";

    constant cv_ADDR_DCSR      : std_logic_vector(11 downto 0) := X"7B0";
    constant cv_ADDR_DPC       : std_logic_vector(11 downto 0) := X"7B1";
    constant cv_ADDR_DSCRATCH0 : std_logic_vector(11 downto 0) := X"7B2";
    constant cv_ADDR_DSCRATCH1 : std_logic_vector(11 downto 0) := X"7B3";
    
    constant cv_MISA_warl : std_logic_vector(31 downto 0) := (
        31 downto 26 => cl_DISABLE,
        12           => cl_DISABLE,
        8            => cl_DISABLE,
        2            => cl_DISABLE,
        others       => cl_ENABLE
    ); -- Modifications of XLEN, M, I, C are off
    
    constant cv_MTVEC_warl : std_logic_vector(31 downto 0) := (
        31 downto 6 => cl_ENABLE,
        5 downto 2  => cl_DISABLE,
        others      => cl_ENABLE
    ); -- Mask = 0xffff_ffC3 = Base is 64 byte aligned

    constant cv_MSTATUS_warl : std_logic_vector(7 downto 0) := (
        7      => cl_ENABLE,
        3      => cl_ENABLE,
        others => cl_DISABLE
    ); -- Only MIE (bit 3) and MPIE (bit 7) bits can be modified
    
    constant cv_MIE_warl : std_logic_vector(11 downto 0) := (
        11     => cl_ENABLE,
        7      => cl_ENABLE,
        3      => cl_ENABLE,
        others => cl_DISABLE
    ); -- Only MSIE (bit 3), MTIE (bit 7) and MEIE (bit 11) bits can be modified

    constant cv_MIP_warl : std_logic_vector(11 downto 0) := (
        11     => cl_ENABLE,
        7      => cl_ENABLE,
        3      => cl_ENABLE,
        others => cl_DISABLE
    ); -- Only MSIP (bit 3), MTIP (bit 7) and MEIP (bit 11) bits can be modified

    constant cv_DCSR_warl : std_logic_vector(31 downto 0) := (
        15         => cl_ENABLE, -- ebreakm
        8 downto 6 => cl_ENABLE, -- cause 
        2          => cl_ENABLE, -- step
        others     => cl_DISABLE
    );

    constant cv_TDATA1_warl : std_logic_vector(31 downto 0) := (
        2      => cl_ENABLE,  -- execute : enable matching on instruction address
        others => cl_DISABLE
    );

    type tr_INT_cause is record
        v_MSI : std_logic_vector(30 downto 0);
        v_MTI : std_logic_vector(30 downto 0);
        v_MEI : std_logic_vector(30 downto 0);
    end record tr_INT_cause;

    constant ctr_INT_cause : tr_INT_cause := (
        v_MSI => "000" & X"0000003",
        v_MTI => "000" & X"0000007",
        v_MEI => "000" & X"000000B"
    );

    type tr_EXC_cause is record
        v_insn_addr_misaligned : std_logic_vector(30 downto 0);
        v_illegal_insn         : std_logic_vector(30 downto 0);
        v_ebreak_insn          : std_logic_vector(30 downto 0);
        v_ecall_insn           : std_logic_vector(30 downto 0);
    end record tr_EXC_cause;

    constant ctr_EXC_cause : tr_EXC_cause := (
        v_insn_addr_misaligned => "000" & X"0000000",
        v_illegal_insn         => "000" & X"0000002",
        v_ebreak_insn          => "000" & X"0000003",
        v_ecall_insn           => "000" & X"000000B"
    );

	type tr_DEBUG_cause is record
		v_ebreak       : std_logic_vector(2 downto 0);
		v_trig         : std_logic_vector(2 downto 0);
		v_haltreq      : std_logic_vector(2 downto 0);
		v_step         : std_logic_vector(2 downto 0);
	end record tr_debug_cause;

    constant ctr_DEBUG_cause : tr_DEBUG_cause := (
		v_ebreak       => "001",
		v_trig         => "010",
		v_haltreq      => "011",
		v_step         => "100"
    );

    function fv_gen_misa(
        c_ext : boolean;
        m_ext : boolean
    ) return std_logic_vector;

    function fv_exc_addr(
        mtvec                : tr_csr_MTVEC; 
        mcause               : tr_csr_MCAUSE;
        firq_addr            : std_logic_vector(31 downto 0)
    ) return std_logic_vector;

end package csr_op_unit_pkg;

package body csr_op_unit_pkg is

    function fv_gen_misa(
        c_ext            : boolean;
        m_ext            : boolean
    ) return std_logic_vector is
        variable vv_misa : std_logic_vector(31 downto 0);
    begin
        vv_misa := X"4000_0100"; -- XLEN = 32, base ISA = RV32I

        if c_ext = true then
            vv_misa(2) := cl_ENABLE;
        end if;

        if m_ext = true then
            vv_misa(12) := cl_ENABLE;
        end if;

        return vv_misa;
    end function;

    function fv_exc_addr(
        mtvec                : tr_csr_MTVEC; 
        mcause               : tr_csr_MCAUSE;
        firq_addr            : std_logic_vector(31 downto 0)
    ) return std_logic_vector is
        variable vv_exc_addr : std_logic_vector(31 downto 0);
    begin
        case mtvec.v_MODE is
            when "00"   => -- direct mode
                vv_exc_addr := mtvec.v_BASE & "00";                                  -- 64 bytes aligned
            when "01"   =>                                                           -- vector mode (only for Interrupts) : addr = BASE + MCAUSE << 2
                if mcause.l_INT = cl_ENABLE then
                    vv_exc_addr := std_logic_vector(unsigned(mtvec.v_BASE & "00") + unsigned(mcause.v_EXC_CODE(29 downto 0) & "00"));
                else
                    vv_exc_addr := mtvec.v_BASE & "00";
                end if;
            when "10"   =>                                                           -- fast IRQ vector (only for interrupts) : Maximum 16 fast IRQ is possible
                if mcause.l_INT = cl_ENABLE then
                    if mcause.v_EXC_CODE(4) = cl_ENABLE then
                        vv_exc_addr := firq_addr(31 downto 6) & (5 downto 0 => '0'); -- 64 bytes aligned
                    else
                        vv_exc_addr := mtvec.v_BASE & "00";
                    end if;
                else
                    vv_exc_addr := mtvec.v_BASE & "00";
                end if;
            when others =>
                vv_exc_addr := mtvec.v_BASE & "00";                                  -- 64 bytes aligned
        end case;
        return vv_exc_addr;
    end function;

end package body csr_op_unit_pkg;