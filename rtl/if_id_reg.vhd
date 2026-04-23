library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.if_id_pkg.all;

entity if_id_reg is
	generic (
		gb_MULTI_CYCLE_FETCH : boolean := true
	);
	port (
		pil_clk             : in std_logic;
		pil_rst             : in std_logic;
		pitr_pipe_status    : in tr_pipe_status; -- Ready from n + 1 stage, strobe from n - 1 stage (This is not being used in the current stage)
		pil_if_halt         : in std_logic;
		pil_if_mem_valid    : in std_logic; -- Mem valid signal from memory module once the request is serviced
		pil_ifid_nop_inst   : in std_logic; -- Add a bubble when the pipe becomes ready
		pitr_ifid_stage_reg : in tr_ifid_stage_reg;
		potr_ifid_stage_reg : out tr_ifid_stage_reg;
		potr_pipe_status    : out tr_pipe_status -- Ready sent to n - 1 stage, strobe sent to n + 1 stage (This goes to the controller)
	);
end entity;

architecture rtl of if_id_reg is

	constant cl_NOTDONE  : std_logic := '0';
	constant cl_DONE     : std_logic := '1';

	constant cl_NOTREADY : std_logic := '0';
	constant cl_READY    : std_logic := '1';

	signal sl_reg_stb      : std_logic;
	signal str_pipe_status : tr_pipe_status;

	signal str_ifid_stage_reg : tr_ifid_stage_reg;

begin

	gen_if_id_stage : if gb_MULTI_CYCLE_FETCH = false generate
		proc_if_id_stage : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				str_ifid_stage_reg <= ctr_ifid_stage_reg_FLUSH;
			elsif rising_edge(pil_clk) then
				if pil_ifid_nop_inst = cl_ENABLE then
					str_ifid_stage_reg.t_inst                    <= ctr_IF_base_format_NOP;
					str_ifid_stage_reg.v_addr                    <= (others => '0');
					str_ifid_stage_reg.l_nop_inst                <= pitr_ifid_stage_reg.l_nop_inst;
					str_ifid_stage_reg.l_is_compressed           <= cl_DISABLE;
					str_ifid_stage_reg.l_illegal_compressed_inst <= cl_DISABLE;
				elsif str_pipe_status.l_stb = cl_DONE then -- Current stage is done
					str_ifid_stage_reg <= pitr_ifid_stage_reg;
				elsif pitr_pipe_status.l_ready = cl_READY then -- Next stage is ready for new data
					--- Since Current stage is not done yet but the next stage is ready, a pipeline stall/bubble will be entered.
				end if;
			end if;
		end process proc_if_id_stage;

		str_pipe_status.l_ready <= pitr_pipe_status.l_ready and pil_if_mem_valid;
		str_pipe_status.l_stb   <= not pil_if_halt and str_pipe_status.l_ready;

		potr_pipe_status.l_stb   <= str_pipe_status.l_stb;
		potr_pipe_status.l_ready <= str_pipe_status.l_ready;

		potr_ifid_stage_reg <= str_ifid_stage_reg;

	else gen_if_id_stage_mc : generate
		proc_if_id_stage : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				str_ifid_stage_reg <= ctr_ifid_stage_reg_FLUSH;
			elsif rising_edge(pil_clk) then
				if pil_ifid_nop_inst = cl_ENABLE then
					str_ifid_stage_reg.t_inst                    <= ctr_IF_base_format_NOP;
					str_ifid_stage_reg.v_addr                    <= (others => '0');
					str_ifid_stage_reg.l_nop_inst                <= pitr_ifid_stage_reg.l_nop_inst;
					str_ifid_stage_reg.l_is_compressed           <= cl_DISABLE;
					str_ifid_stage_reg.l_illegal_compressed_inst <= cl_DISABLE;
				elsif str_pipe_status.l_stb = cl_DONE then -- Current stage is done
					if pitr_pipe_status.l_stb = cl_DONE then 
						str_ifid_stage_reg                           <= pitr_ifid_stage_reg;
					else
						str_ifid_stage_reg.t_inst                    <= ctr_IF_base_format_NOP;
						str_ifid_stage_reg.v_addr                    <= (others => '0');
						str_ifid_stage_reg.l_nop_inst                <= pitr_ifid_stage_reg.l_nop_inst;
						str_ifid_stage_reg.l_is_compressed           <= cl_DISABLE;
						str_ifid_stage_reg.l_illegal_compressed_inst <= cl_DISABLE;
					end if;
				elsif pitr_pipe_status.l_ready = cl_READY then -- Next stage is ready for new data
					--- Since Current stage is not done yet but the next stage is ready, a pipeline stall/bubble will be entered.
					str_ifid_stage_reg.l_rvfi_intr               <= cl_DISABLE;
					str_ifid_stage_reg.l_irq_regfile_sel         <= cl_DISABLE;
					str_ifid_stage_reg.l_is_compressed           <= cl_DISABLE;
					str_ifid_stage_reg.l_illegal_compressed_inst <= cl_DISABLE;
				end if;
			end if;
		end process proc_if_id_stage;

		str_pipe_status.l_ready <= pitr_pipe_status.l_ready and pil_if_mem_valid;
		str_pipe_status.l_stb   <= not pil_if_halt and str_pipe_status.l_ready;

		proc_ifid_stb : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				sl_reg_stb <= cl_DISABLE;
			elsif rising_edge(pil_clk) then
				sl_reg_stb <= str_pipe_status.l_stb;
			end if;
		end process proc_ifid_stb;

		potr_pipe_status.l_stb   <= sl_reg_stb;
		potr_pipe_status.l_ready <= str_pipe_status.l_ready;

		potr_ifid_stage_reg <= str_ifid_stage_reg;
	end generate;

end architecture;