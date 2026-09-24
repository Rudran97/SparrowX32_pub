library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package options_pkg is

    --- Core settings ---
    constant cv_PC_ORIGIN         : std_logic_vector(31 downto 0) := X"8000_0000";
    constant cb_MULTI_CYCLE_FETCH : boolean := false;
    constant cb_GPR_HW_BACKUP     : boolean := true;

    --- Extension options ---
    constant cb_EXT_M  : boolean := true;
    constant cb_EXT_C  : boolean := true;
    constant cb_RV32_E : boolean := false;

    --- Default CSR settings ---
    constant cv_reg_MVENDORID : std_logic_vector(31 downto 0) := X"0000_0000";
    constant cv_reg_MARCHID   : std_logic_vector(31 downto 0) := X"0600_A033";
    constant cv_reg_MIMPID    : std_logic_vector(31 downto 0) := X"0002_0040";
    constant cv_reg_MHARTID   : std_logic_vector(31 downto 0) := X"0000_0000";

    --- RISCV FORMAL OPTIONS ---
    constant cb_RISCV_FORMAL        : boolean := false;
    constant cb_RISCV_FORMAL_ALTOPS : boolean := false;

end package;
