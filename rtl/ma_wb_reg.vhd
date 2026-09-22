library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.ma_wb_pkg.all;

entity ma_wb_reg is
    port (
        pil_clk             : in std_logic;
        pil_rst             : in std_logic;
        pitr_pipe_status    : in tr_pipe_status; -- Ready from n + 1 stage, strobe from n - 1 stage (This is not being used in the current stage)
        pil_ma_halt         : in std_logic;
        pil_ma_unit_valid   : in std_logic; -- Valid signal from mem and csr unit
        pitr_mawb_stage_reg : in tr_mawb_stage_reg;
        potr_mawb_stage_reg : out tr_mawb_stage_reg;
        potr_pipe_status    : out tr_pipe_status -- Ready sent to n - 1 stage, strobe sent to n + 1 stage (This goes to the controller)
    );
end entity;

architecture rtl of ma_wb_reg is

    constant cl_NOTDONE  : std_logic := '0';
    constant cl_DONE     : std_logic := '1';

    constant cl_NOTREADY : std_logic := '0';
    constant cl_READY    : std_logic := '1';

    signal str_pipe_status : tr_pipe_status;

    signal str_mawb_stage_reg : tr_mawb_stage_reg;

begin

    proc_ma_wb_stage : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            str_mawb_stage_reg <= ctr_mawb_stage_reg_FLUSH;
        elsif rising_edge(pil_clk) then
            if str_pipe_status.l_stb = cl_DONE then -- Current stage is done
                str_mawb_stage_reg <= pitr_mawb_stage_reg;
            elsif pitr_pipe_status.l_ready = cl_READY then -- Next stage is ready for new data
                --- Since Current stage is not done yet but the next stage is ready, a pipeline stall/bubble will be entered.
                str_mawb_stage_reg.l_branch_taken  <= cl_DISABLE;
                str_mawb_stage_reg.t_wb_ctrl       <= ctr_CS_WB_DISABLE;
                str_mawb_stage_reg.l_is_ebreak     <= cl_DISABLE;
                str_mawb_stage_reg.l_inst_tag      <= cl_DISABLE;
                str_mawb_stage_reg.l_illegal_inst  <= cl_DISABLE;
            end if;
        end if;
    end process proc_ma_wb_stage;

    str_pipe_status.l_ready <= pitr_pipe_status.l_ready and pil_ma_unit_valid;
    str_pipe_status.l_stb   <= not pil_ma_halt and str_pipe_status.l_ready;

    potr_pipe_status.l_stb   <= str_pipe_status.l_stb;
    potr_pipe_status.l_ready <= str_pipe_status.l_ready;

    potr_mawb_stage_reg <= str_mawb_stage_reg;

end architecture;
