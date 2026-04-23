library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.int_mul_div_pkg.all;

entity int_mul_div is
	generic (
		gb_RISCV_FORMAL_ALTOPS : boolean := false
	);
	port (
		pil_clk          : in std_logic;
		pil_rst          : in std_logic;
		pil_int_md_halt  : in std_logic; -- When enabled the current calculation will be stopped until disabled
		piv_int_md_oper  : in std_logic_vector(3 downto 0); --- 3 -> EN, 2..0 -> funct3
		piv_int_md_temp1 : in std_logic_vector(31 downto 0);
		piv_int_md_temp2 : in std_logic_vector(31 downto 0);
		pov_int_md_out   : out std_logic_vector(31 downto 0);
		pol_int_md_busy  : out std_logic
	);
end entity int_mul_div;

architecture rtl of int_mul_div is

	signal sv_mul_temp1           : std_logic_vector(piv_int_md_temp1'length - 1 downto 0);
	signal sv_mul_temp2           : std_logic_vector(piv_int_md_temp2'length - 1 downto 0);
	signal sv_mul_out             : std_logic_vector(pov_int_md_out'length - 1 downto 0);
	signal sv_mul_result          : std_logic_vector(piv_int_md_temp1'length + piv_int_md_temp2'length - 1 downto 0);
	signal sl_mul_mul_sign        : std_logic;
	signal sl_mul_busy            : std_logic;
	signal si_mul_result_delay_ct : integer range 0 to 6;

	signal sv_div_temp1       : std_logic_vector(piv_int_md_temp1'length - 1 downto 0);
	signal sv_div_temp2       : std_logic_vector(piv_int_md_temp2'length - 1 downto 0);
	signal sv_div_out         : std_logic_vector(pov_int_md_out'length - 1 downto 0);
	signal sv_div_result      : std_logic_vector(piv_int_md_temp1'length + piv_int_md_temp2'length - 1 downto 0);
	signal sl_div_div_sign    : std_logic;
	signal sl_div_rem_sign    : std_logic;
	signal sl_div_shift_carry : std_logic;
	signal sl_div_busy        : std_logic;

	type t_multipler_stage is (st_idle, st_multiply, st_mul_valid, st_result_valid, st_wait0);
	signal st_multiplier_state : t_multipler_stage;

	type t_divide_stage is (st_idle, st_ready_buffer, st_result_valid, st_subtract, st_shift, st_wait0);
	signal st_divider_state : t_divide_stage;

	alias al_module_en     : std_logic is piv_int_md_oper(3);
	alias al_operation_sel : std_logic is piv_int_md_oper(2);
	alias av_operation     : std_logic_vector is piv_int_md_oper(2 downto 0);

begin

	gen_rvfi_altops : if gb_RISCV_FORMAL_ALTOPS = true generate
		assert false report "*** Using RISCV_FORMAL_ALTOPS ***" severity warning;
		-- Instruction time for MUL is 10 cc.

		proc_rvfi_mul : process (pil_clk, pil_rst)
			variable vi_delay_ct : integer range 0 to 7;
			variable vu_add      : unsigned(31 downto 0);
			variable vv_xor      : std_logic_vector(31 downto 0);
		begin
			if pil_rst = cl_RESET then
				vi_delay_ct            := 0;
				vu_add                 := (others => '0');
				vv_xor                 := (others => '0');
				sv_mul_out             <= (others => '0');
				sl_mul_busy            <= '1';
				st_multiplier_state    <= st_idle;
			elsif rising_edge(pil_clk) then
				if pil_int_md_halt = cl_ENABLE then
					st_multiplier_state <= st_idle;
				else
					case st_multiplier_state is
						when st_idle =>
							sl_mul_busy <= '1';
							if al_module_en = cl_ENABLE then
								if al_operation_sel = cl_mul_operation then
									st_multiplier_state <= st_multiply;
								end if;
							else
								st_multiplier_state <= st_idle;
							end if;
						when st_multiply =>
							sl_mul_busy <= '1';
							case av_operation is
								when cv_MD_MULH =>
									vu_add := unsigned(piv_int_md_temp1) + unsigned(piv_int_md_temp2);
									vv_xor := std_logic_vector(vu_add) xor X"f6583fb7";
								when cv_MD_MULHSU =>
									vu_add := unsigned(piv_int_md_temp1) - unsigned(piv_int_md_temp2);
									vv_xor := std_logic_vector(vu_add) xor X"ecfbe137";
								when cv_MD_MULHU =>
									vu_add := unsigned(piv_int_md_temp1) + unsigned(piv_int_md_temp2);
									vv_xor := std_logic_vector(vu_add) xor X"949ce5e8";
								when others =>
									vu_add := unsigned(piv_int_md_temp1) + unsigned(piv_int_md_temp2);
									vv_xor := std_logic_vector(vu_add) xor X"5876063e";
							end case;
							if vi_delay_ct < 7 then
								vi_delay_ct := vi_delay_ct + 1;
								st_multiplier_state <= st_multiply;
							else
								vi_delay_ct := 0;
								st_multiplier_state <= st_mul_valid;
							end if;
						when st_mul_valid =>
							sl_mul_busy         <= '1';
							st_multiplier_state <= st_result_valid;
						when st_result_valid =>
							sl_mul_busy         <= '0';
							sv_mul_out          <= vv_xor;
							st_multiplier_state <= st_wait0;
						when st_wait0 =>
							sl_mul_busy         <= '1';
							st_multiplier_state <= st_idle;
					end case;
				end if;
			end if;
		end process proc_rvfi_mul;

		proc_rvfi_div : process(pil_clk, pil_rst)
			variable vi_delay_ct : integer range 0 to 32;
			variable vu_add      : unsigned(31 downto 0);
			variable vv_xor      : std_logic_vector(31 downto 0);
		begin
			if pil_rst = cl_RESET then
				vi_delay_ct      := 0;
				vu_add           := (others => '0');
				vv_xor           := (others => '0');
				sv_div_out       <= (others => '0');
				sl_div_busy      <= '1';
				st_divider_state <= st_idle;
			elsif rising_edge(pil_clk) then
				if pil_int_md_halt = cl_ENABLE then
					st_divider_state <= st_idle;
				else
					case st_divider_state is
						when st_idle =>
							sl_div_busy <= '1';
							if al_module_en = cl_ENABLE then
								if al_operation_sel = cl_div_operation then
									st_divider_state <= st_ready_buffer;
								end if;
							else
								st_divider_state <= st_idle;
							end if;
						when st_ready_buffer =>
							sl_div_busy      <= '1';
							st_divider_state <= st_subtract;
						when st_subtract =>
							sl_div_busy      <= '1';
							st_divider_state <= st_shift;
							case av_operation is
								when cv_MD_DIV  =>
									vu_add   := unsigned(piv_int_md_temp1) - unsigned(piv_int_md_temp2);
									vv_xor   := std_logic_vector(vu_add) xor X"7f8529ec";
								when cv_MD_DIVU =>
									vu_add   := unsigned(piv_int_md_temp1) - unsigned(piv_int_md_temp2);
									vv_xor   := std_logic_vector(vu_add) xor X"10e8fd70";
								when cv_MD_REM  =>
									vu_add   := unsigned(piv_int_md_temp1) - unsigned(piv_int_md_temp2);
									vv_xor   := std_logic_vector(vu_add) xor X"8da68fa5";
								when others =>
									vu_add   := unsigned(piv_int_md_temp1) - unsigned(piv_int_md_temp2);
									vv_xor   := std_logic_vector(vu_add) xor X"3138d0e1";
							end case;
						when st_shift =>
							sl_div_busy      <= '1';
							--- The delay has been reduced for Formal-Verification. RVFI DIV[U]/REM[U] produces ERROR for longer delays ---
							if vi_delay_ct < 3 then
								vi_delay_ct      := vi_delay_ct + 1;
								st_divider_state <= st_subtract;
							else
								vi_delay_ct      := 0;
								st_divider_state <= st_result_valid;
							end if;
						when st_result_valid =>
							sl_div_busy      <= '0';
							sv_div_out       <= vv_xor;
							st_divider_state <= st_wait0;
						when st_wait0 =>
							sl_div_busy      <= '1';
							st_divider_state <= st_idle;
					end case;
				end if;
			end if;
		end process proc_rvfi_div;

	else gen_regular_muldiv : generate
		assert false report "*** Using regular mul div implementation ***" severity warning;
		inst_mul_unsigned_block : entity work.mul_unsigned_block
			port map(
				pil_clk => pil_clk,
				pil_rst => pil_rst,
				piv_a   => sv_mul_temp1,
				piv_b   => sv_mul_temp2,
				pov_res => sv_mul_result
			);

		proc_mul_module : process (pil_clk, pil_rst) is
		begin
			if pil_rst = '1' then
				sv_mul_temp1           <= (others => '0');
				sv_mul_temp2           <= (others => '0');
				sv_mul_out             <= (others => '0');
				sl_mul_mul_sign        <= '0';
				sl_mul_busy            <= '1';
				si_mul_result_delay_ct <= 0;
				st_multiplier_state    <= st_idle;
			elsif rising_edge(pil_clk) then
				if pil_int_md_halt = cl_ENABLE then
					st_multiplier_state <= st_idle;
				else
					case st_multiplier_state is
						when st_idle =>
							sl_mul_busy            <= '1';
							si_mul_result_delay_ct <= 0;
							if al_module_en = cl_ENABLE then
								if al_operation_sel = cl_mul_operation then
									case av_operation is
										when cv_MD_MULH =>
											sl_mul_mul_sign <= piv_int_md_temp1(31) xor piv_int_md_temp2(31);
											if piv_int_md_temp1(31) = cl_neg then
												sv_mul_temp1 <= fv_2s_complement(v_number => piv_int_md_temp1);
											else
												sv_mul_temp1 <= piv_int_md_temp1;
											end if;
											if piv_int_md_temp2(31) = cl_neg then
												sv_mul_temp2 <= fv_2s_complement(v_number => piv_int_md_temp2);
											else
												sv_mul_temp2 <= piv_int_md_temp2;
											end if;
										when cv_MD_MULHSU =>
											sl_mul_mul_sign <= piv_int_md_temp1(31);
											if piv_int_md_temp1(31) = cl_neg then
												sv_mul_temp1 <= fv_2s_complement(v_number => piv_int_md_temp1);
											else
												sv_mul_temp1 <= piv_int_md_temp1;
											end if;
											sv_mul_temp2 <= piv_int_md_temp2;
										when others =>
											sl_mul_mul_sign <= '0';
											sv_mul_temp1    <= piv_int_md_temp1;
											sv_mul_temp2    <= piv_int_md_temp2;
									end case;
									st_multiplier_state <= st_multiply;
								end if;
							else
								st_multiplier_state <= st_idle;
							end if;
						when st_multiply =>
							sl_mul_busy <= '1';
							if si_mul_result_delay_ct < 5 then
								si_mul_result_delay_ct <= si_mul_result_delay_ct + 1;
								st_multiplier_state    <= st_multiply;
							else
								si_mul_result_delay_ct <= 0;
								st_multiplier_state    <= st_mul_valid;
							end if;
						when st_mul_valid =>
							sl_mul_busy         <= '1';
							st_multiplier_state <= st_result_valid;
						when st_result_valid =>
							sl_mul_busy <= '0';
							case av_operation is
								when cv_MD_MULH | cv_MD_MULHSU =>
									if sl_mul_mul_sign = cl_neg then
										sv_mul_out <= fv_2s_complement(v_number => sv_mul_result)(63 downto 32);
									else
										sv_mul_out <= sv_mul_result(63 downto 32);
									end if;
								when cv_MD_MULHU =>
									sv_mul_out <= sv_mul_result(63 downto 32);
								when others =>
									sv_mul_out <= sv_mul_result(31 downto 0);
							end case;
							st_multiplier_state <= st_wait0;
						when st_wait0 =>
							sl_mul_busy         <= '1';
							st_multiplier_state <= st_idle;
					end case;
				end if;
			end if;
		end process proc_mul_module;

		proc_div_module : process (pil_clk, pil_rst) is
			variable vi_shift_counter   : integer range 0 to 32;
			variable vu_subtract_result : unsigned(32 downto 0); --- 33 bits... top bit for carry
		begin
			if pil_rst = '1' then
				sv_div_temp1  <= (others => '0');
				sv_div_temp2  <= (others => '0');
				sv_div_result <= (others => '0');
				sv_div_out    <= (others => '0');
				vi_shift_counter := 0;
				sl_div_div_sign    <= '0';
				sl_div_rem_sign    <= '0';
				sl_div_shift_carry <= '0';
				sl_div_busy        <= '1';
				st_divider_state   <= st_idle;
			elsif rising_edge(pil_clk) then
				if pil_int_md_halt = cl_ENABLE then
					st_divider_state <= st_idle;
				else
					case st_divider_state is
						when st_idle =>
							sl_div_busy <= '1';
							if al_module_en = cl_ENABLE then
								if al_operation_sel = cl_div_operation then
									case av_operation is
										when cv_MD_DIV | cv_MD_REM =>
											sl_div_div_sign <= piv_int_md_temp1(31) xor piv_int_md_temp2(31);
											sl_div_rem_sign <= piv_int_md_temp1(31);
											if piv_int_md_temp1(31) = cl_neg then
												sv_div_temp1 <= fv_2s_complement(v_number => piv_int_md_temp1);
											else
												sv_div_temp1 <= piv_int_md_temp1;
											end if;
											if piv_int_md_temp2(31) = cl_neg then
												sv_div_temp2 <= fv_2s_complement(v_number => piv_int_md_temp2);
											else
												sv_div_temp2 <= piv_int_md_temp2;
											end if;
										when others =>
											sl_div_div_sign <= '0';
											sl_div_rem_sign <= '0';
											sv_div_temp1    <= piv_int_md_temp1;
											sv_div_temp2    <= piv_int_md_temp2;
									end case;
									st_divider_state <= st_ready_buffer;
								end if;
							else
								st_divider_state <= st_idle;
							end if;
						when st_ready_buffer =>
							sl_div_busy                <= '1';
							sv_div_result              <= (others => '0');
							sv_div_result(31 downto 0) <= sv_div_temp1;
							st_divider_state           <= st_subtract;
						when st_subtract =>
							vu_subtract_result := unsigned('0' & sv_div_result(63 downto 32)) - unsigned('0' & sv_div_temp2);
							if vu_subtract_result(32) = '0' then
								sv_div_result(63 downto 32) <= std_logic_vector(vu_subtract_result(31 downto 0));
								sl_div_shift_carry          <= '1';
							else
								sl_div_shift_carry <= '0';
							end if;
							st_divider_state <= st_shift;
						when st_shift =>
							sl_div_busy <= '1';
							if vi_shift_counter < 32 then
								vi_shift_counter := vi_shift_counter + 1;
								sv_div_result(63 downto 1) <= sv_div_result(62 downto 0);
								sv_div_result(0)           <= sl_div_shift_carry;
								st_divider_state           <= st_subtract;
							else
								sv_div_result(31 downto 1) <= sv_div_result(30 downto 0);
								sv_div_result(0)           <= sl_div_shift_carry;
								vi_shift_counter := 0;
								st_divider_state <= st_result_valid;
							end if;
						when st_result_valid =>
							sl_div_busy <= '0';
							case av_operation is
								when cv_MD_DIV =>
									if sl_div_div_sign = cl_neg then
										sv_div_out <= fv_2s_complement(v_number => sv_div_result(31 downto 0));
									else
										sv_div_out <= sv_div_result(31 downto 0);
									end if;
								when cv_MD_DIVU =>
									sv_div_out <= sv_div_result(31 downto 0);
								when cv_MD_REM =>
									if sl_div_rem_sign = cl_neg then
										sv_div_out <= fv_2s_complement(v_number => sv_div_result(63 downto 32));
									else
										sv_div_out <= sv_div_result(63 downto 32);
									end if;
								when others =>
									sv_div_out <= sv_div_result(63 downto 32);
							end case;
							st_divider_state <= st_wait0;
						when st_wait0 =>
							sl_div_busy      <= '1';
							st_divider_state <= st_idle;
					end case;
				end if;
			end if;
		end process proc_div_module;
	end generate;

	pov_int_md_out <= sv_mul_out when al_operation_sel = cl_mul_operation else sv_div_out;

	pol_int_md_busy <= sl_mul_busy when al_operation_sel = cl_mul_operation and pil_int_md_halt = cl_DISABLE else
		sl_div_busy when al_operation_sel = cl_div_operation and pil_int_md_halt = cl_DISABLE else
		cl_DISABLE;

end architecture rtl;