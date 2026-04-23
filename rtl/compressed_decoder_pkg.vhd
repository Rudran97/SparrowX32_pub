library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

package compressed_decoder_pkg is

    -----------------------------------------------------------------------------------------------------
    -----------------------------COMPRESSED INSTRUCTION FORMAT (CIF)-------------------------------------
    -----------------------------------------------------------------------------------------------------

    --- Base format ---

    constant ci_CIF_opcode_l : integer := 0;
    constant ci_CIF_opcode_u : integer := 1;

    constant ci_CIF_rs2_l : integer := 2;
    constant ci_CIF_rs2_u : integer := 6;

    constant ci_CIF_rs1_l : integer := 7;
    constant ci_CIF_rs1_u : integer := 11;

    constant ci_CIF_rd_l : integer := ci_CIF_rs1_l;
    constant ci_CIF_rd_u : integer := ci_CIF_rs1_u;

    constant ci_CIF_funct4_l : integer := 12;
    constant ci_CIF_funct4_u : integer := 15;

    constant ci_CIF_funct3_l : integer := ci_CIF_funct4_l + 1;
    constant ci_CIF_funct3_u : integer := ci_CIF_funct4_u;

    -----------------------------------------------------------------------------------------------------
    ---------------------------------COMPRESSED OPCODE CODE (COC)----------------------------------------
    -----------------------------------------------------------------------------------------------------

    constant cv_COC_C0 : std_logic_vector(1 downto 0) := "00";
    constant cv_COC_C1 : std_logic_vector(1 downto 0) := "01";
    constant cv_COC_C2 : std_logic_vector(1 downto 0) := "10";

    -----------------------------------------------------------------------------------------------------
    -----------------------------General Constants / Types / Functions-----------------------------------
    -----------------------------------------------------------------------------------------------------

    type tr_C0_funct3 is record
        v_LW       : std_logic_vector(2 downto 0);
        v_SW       : std_logic_vector(2 downto 0);
        v_ADDI4SPN : std_logic_vector(2 downto 0);
    end record tr_C0_funct3;

    type tr_C1_funct3 is record
        v_J            : std_logic_vector(2 downto 0);
        v_JAL          : std_logic_vector(2 downto 0);
        v_BEQZ         : std_logic_vector(2 downto 0);
        v_BNEZ         : std_logic_vector(2 downto 0);
        v_LI           : std_logic_vector(2 downto 0);
        v_LUI_ADDI16SP : std_logic_vector(2 downto 0);
        v_ADDI_NOP     : std_logic_vector(2 downto 0);
        v_CA_type      : std_logic_vector(2 downto 0);
    end record tr_C1_funct3;

    type tr_C2_funct3 is record
        v_LWSP  : std_logic_vector(2 downto 0);
        v_SWSP  : std_logic_vector(2 downto 0);
        v_RR_OP : std_logic_vector(2 downto 0);
        v_SLLI  : std_logic_vector(2 downto 0);
    end record tr_C2_funct3;

    constant ctr_C0_funct3 : tr_C0_funct3 := (
        v_ADDI4SPN => "000",
        v_LW       => "010",
        v_SW       => "110"
    );

    constant ctr_C1_funct3 : tr_C1_funct3 := (
        v_ADDI_NOP     => "000",
        v_JAL          => "001",
        v_LI           => "010",
        v_LUI_ADDI16SP => "011",
        v_CA_type      => "100",
        v_J            => "101",
        v_BEQZ         => "110",
        v_BNEZ         => "111"
    );

    constant ctr_C2_funct3 : tr_C2_funct3 := (
        v_SLLI  => "000",
        v_LWSP  => "010",
        v_RR_OP => "100",
        v_SWSP  => "110"
    );

    function fv_inst_32to16(
        instruction : tr_IF_base_format
    ) return std_logic_vector;

end package;

package body compressed_decoder_pkg is

    function fv_inst_32to16(
        instruction : tr_IF_base_format
    ) return std_logic_vector is
        variable vv_inst31 : std_logic_vector(31 downto 0);
    begin
        vv_inst31 := fv_inst_rec2slv(instruction => instruction);

        return vv_inst31(15 downto 0);
    end function;

end package body;