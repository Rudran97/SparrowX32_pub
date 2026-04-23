library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.id_exe_pkg.all;

entity id_exe_reg is
	generic (
		gb_MULTI_CYCLE_FETCH : boolean := true
	);
	port (
		pil_clk              : in std_logic;
		pil_rst              : in std_logic;
		pitr_pipe_status     : in tr_pipe_status; -- Ready from n + 1 stage, strobe from n - 1 stage (This is not being used in the current stage)
		pil_id_halt          : in std_logic;
		pitr_idexe_stage_reg : in tr_idexe_stage_reg;
		potr_idexe_stage_reg : out tr_idexe_stage_reg;
		potr_pipe_status     : out tr_pipe_status -- Ready sent to n - 1 stage, strobe sent to n + 1 stage (This goes to the controller)
	);
end entity;

architecture rtl of id_exe_reg is

	constant cl_NOTDONE  : std_logic := '0';
	constant cl_DONE     : std_logic := '1';

	constant cl_NOTREADY : std_logic := '0';
	constant cl_READY    : std_logic := '1';

	signal str_pipe_status : tr_pipe_status;

	signal str_idexe_stage_reg : tr_idexe_stage_reg;

begin

	gen_id_exe_stage : if gb_MULTI_CYCLE_FETCH = false generate
		proc_id_exe_stage : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				str_idexe_stage_reg <= ctr_idexe_stage_reg_FLUSH;
			elsif rising_edge(pil_clk) then
				if str_pipe_status.l_stb = cl_DONE then -- Current stage is done
					str_idexe_stage_reg <= pitr_idexe_stage_reg;
				elsif pitr_pipe_status.l_ready = cl_READY then -- Next stage is ready for new data
					--- Since Current stage is not done yet but the next stage is ready, a pipeline stall/bubble will be entered.
					str_idexe_stage_reg.t_exe_ctrl      <= ctr_CS_EXE_DISABLE;
					str_idexe_stage_reg.t_ma_ctrl       <= ctr_CS_MA_DISABLE;
					str_idexe_stage_reg.t_wb_ctrl       <= ctr_CS_WB_DISABLE;
					str_idexe_stage_reg.t_rvfi          <= ctr_CS_RVFI_RESET;
					str_idexe_stage_reg.l_inst_tag      <= cl_DISABLE;
					str_idexe_stage_reg.l_illegal_inst  <= cl_DISABLE;
				end if;
			end if;
		end process proc_id_exe_stage;

	else gen_id_exe_stage_mc : generate
		proc_id_exe_stage : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				str_idexe_stage_reg <= ctr_idexe_stage_reg_FLUSH;
			elsif rising_edge(pil_clk) then
				if str_pipe_status.l_stb = cl_DONE then -- Current stage is done
					if pitr_pipe_status.l_stb = cl_DONE then
						str_idexe_stage_reg                 <= pitr_idexe_stage_reg;
					else
						str_idexe_stage_reg.t_exe_ctrl      <= ctr_CS_EXE_DISABLE;
						str_idexe_stage_reg.t_ma_ctrl       <= ctr_CS_MA_DISABLE;
						str_idexe_stage_reg.t_wb_ctrl       <= ctr_CS_WB_DISABLE;
						str_idexe_stage_reg.t_rvfi          <= ctr_CS_RVFI_RESET;
						str_idexe_stage_reg.l_inst_tag      <= cl_DISABLE;
						str_idexe_stage_reg.l_illegal_inst  <= cl_DISABLE;
					end if;
				elsif pitr_pipe_status.l_ready = cl_READY then -- Next stage is ready for new data
					--- Since Current stage is not done yet but the next stage is ready, a pipeline stall/bubble will be entered.
					str_idexe_stage_reg.t_exe_ctrl      <= ctr_CS_EXE_DISABLE;
					str_idexe_stage_reg.t_ma_ctrl       <= ctr_CS_MA_DISABLE;
					str_idexe_stage_reg.t_wb_ctrl       <= ctr_CS_WB_DISABLE;
					str_idexe_stage_reg.t_rvfi          <= ctr_CS_RVFI_RESET;
					str_idexe_stage_reg.l_inst_tag      <= cl_DISABLE;
					str_idexe_stage_reg.l_illegal_inst  <= cl_DISABLE;
				end if;
			end if;
		end process proc_id_exe_stage;
	end generate;

	str_pipe_status.l_ready <= pitr_pipe_status.l_ready;
	str_pipe_status.l_stb   <= not pil_id_halt and str_pipe_status.l_ready;

	potr_pipe_status.l_stb   <= str_pipe_status.l_stb;
	potr_pipe_status.l_ready <= str_pipe_status.l_ready;

	potr_idexe_stage_reg <= str_idexe_stage_reg;

end architecture;