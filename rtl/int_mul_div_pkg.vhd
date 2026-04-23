library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package int_mul_div_pkg is

    -----------------------------------------------------------------------------------------------------
    -----------------------------------------MULDIV OPERATIONS----------------------------------------------
    -----------------------------------------------------------------------------------------------------

    constant cl_mul_operation : std_logic := '0';
    constant cl_div_operation : std_logic := '1';

    constant cl_pos : std_logic := '0';
    constant cl_neg : std_logic := '1';

    --- Multiply Operations ---
    constant cv_MD_MUL    : std_logic_vector(2 downto 0) := "000";
    constant cv_MD_MULH   : std_logic_vector(2 downto 0) := "001";
    constant cv_MD_MULHSU : std_logic_vector(2 downto 0) := "010";
    constant cv_MD_MULHU  : std_logic_vector(2 downto 0) := "011";

    --- Divide / Remainder Operations ---
    constant cv_MD_DIV  : std_logic_vector(2 downto 0) := "100";
    constant cv_MD_DIVU : std_logic_vector(2 downto 0) := "101";
    constant cv_MD_REM  : std_logic_vector(2 downto 0) := "110";
    constant cv_MD_REMU : std_logic_vector(2 downto 0) := "111";

    function fv_2s_complement(
        v_number : std_logic_vector
    ) return std_logic_vector;

end package;

package body int_mul_div_pkg is

    function fv_2s_complement(
        v_number            : std_logic_vector) return std_logic_vector is
        variable vv_2s_comp : std_logic_vector(v_number'length - 1 downto 0);
    begin
        vv_2s_comp := std_logic_vector(unsigned(not v_number) + 1);
        return vv_2s_comp;
    end function;

end package body;