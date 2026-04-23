library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.exe_ma_pkg.all;

entity exe_ma_reg is
	port (
		pil_clk              : in std_logic;
		pil_rst              : in std_logic;
		pitr_pipe_status     : in tr_pipe_status; -- Ready from n + 1 stage, strobe from n - 1 stage (This is not being used in the current stage)
		pil_exe_halt         : in std_logic;
		pil_exe_unit_valid   : in std_logic; -- Exe unit valid signal after the instruction has been executed
		pitr_exema_stage_reg : in tr_exema_stage_reg;
		potr_exema_stage_reg : out tr_exema_stage_reg;
		potr_pipe_status     : out tr_pipe_status -- Ready sent to n - 1 stage, strobe sent to n + 1 stage (This goes to the controller)
	);
end entity;

architecture rtl of exe_ma_reg is

	constant cl_NOTDONE  : std_logic := '0';
	constant cl_DONE     : std_logic := '1';

	constant cl_NOTREADY : std_logic := '0';
	constant cl_READY    : std_logic := '1';

	signal str_pipe_status : tr_pipe_status;

	signal str_exema_stage_reg : tr_exema_stage_reg;

begin

	proc_exe_ma_stage : process (pil_clk, pil_rst)
	begin
		if pil_rst = cl_RESET then
			str_exema_stage_reg <= ctr_exema_stage_reg_FLUSH;
		elsif rising_edge(pil_clk) then
			if str_pipe_status.l_stb = cl_DONE then -- Current stage is done
				str_exema_stage_reg <= pitr_exema_stage_reg;
			elsif pitr_pipe_status.l_ready = cl_READY then -- Next stage is ready for new data
				--- Since Current stage is not done yet but the next stage is ready, a pipeline stall/bubble will be entered.
				str_exema_stage_reg.l_branch_taken  <= cl_DISABLE;
				str_exema_stage_reg.t_ma_ctrl       <= ctr_CS_MA_DISABLE;
				str_exema_stage_reg.t_wb_ctrl       <= ctr_CS_WB_DISABLE;
				str_exema_stage_reg.t_rvfi          <= ctr_CS_RVFI_RESET;
				str_exema_stage_reg.l_inst_tag      <= cl_DISABLE;
				str_exema_stage_reg.l_illegal_inst  <= cl_DISABLE;
			end if;
		end if;
	end process proc_exe_ma_stage;

	str_pipe_status.l_ready <= pitr_pipe_status.l_ready and pil_exe_unit_valid;
	str_pipe_status.l_stb   <= not pil_exe_halt and str_pipe_status.l_ready;

	potr_pipe_status.l_stb   <= str_pipe_status.l_stb;
	potr_pipe_status.l_ready <= str_pipe_status.l_ready;

	potr_exema_stage_reg <= str_exema_stage_reg;

end architecture;