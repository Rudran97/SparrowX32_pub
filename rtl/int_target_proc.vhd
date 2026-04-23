library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.clic_pkg.all;

entity int_target_proc is
	port (
		pil_clk              : in std_logic;
		pil_rst              : in std_logic;
		pil_prio_sel_en      : in std_logic;
		piv_int_pen          : in std_logic_vector(7 downto 0);
		pitav_int_prio       : in tav_int_prio(0 to 7);
		pitav_int_isr_vector : in tav_int_isr_vector(0 to 7);
		pol_irq              : out std_logic;
		pov_irq_id           : out std_logic_vector(2 downto 0);
		pov_int_pen_clr      : out std_logic_vector(7 downto 0);
		pov_isr_vector       : out std_logic_vector(31 downto 0)
	);
end entity int_target_proc;

architecture rtl of int_target_proc is

	type tav_priority_matrix is array (0 to 7) of std_logic_vector(7 downto 0);
	signal stav_priority_matrix       : tav_priority_matrix;

	type tai_pen_prio_lvl_addr_loc is array (1 to 7) of integer range 0 to 7;
	signal stai_pen_prio_lvl_addr_loc : tai_pen_prio_lvl_addr_loc;

	type tal_isr_pen_lvl_flag is array (1 to 7) of std_logic;
	signal stal_isr_pen_lvl_flag      : tal_isr_pen_lvl_flag;

	signal sv_irq_id                  : std_logic_vector(2 downto 0);
	signal sv_int_pen_clr             : std_logic_vector(7 downto 0);
	signal sv_isr_vector_address      : std_logic_vector(31 downto 0);

begin

	-- Interrupt priority matrix: Sets the pending bit in the matrix corresponding to each interrupt in their respective priority level
	-- matrix(priority_level_of_interrupt_x)(interrupt_x_bit_position) <= ('1', '0');  where '1' -> pending, '0' -> not pending.
	-- e.g., int15 -> priority 6 and interrupt is pending
	-- e.g., int2  -> priority 5 interrupt is pending
	-- e.g., int1  -> priority 5 interrupt is pending
	-----------------------------------------------------------------------------------------------------------------------------------
	--                                    interrupts
	-- ---------------------------------------------------------------------------------
	-- priority | ... int15  int14  ... ... ... ... ... int2  int1  int0
	-- -------- | ---------------------------------------------------------
	-- level 0  |      
	-- level 1  |
	-- level 2  |
	-- level 3  |
	-- level 4  |
	-- level 5  |                                         1     1
	-- level 6  |       1
	-- level 7  |
	--
	--
	--
	--
	--
	--
	-----------------------------------------------------------------------------------------------------------------------------------

	proc_priority_matrix_table : process (pitav_int_prio, piv_int_pen) is
	begin
		for ii in 0 to 7 loop
			stav_priority_matrix(ii) <= (others => cl_NOTPENDING);
		end loop;

		for ii in 0 to 7 loop
			stav_priority_matrix(to_integer(unsigned(pitav_int_prio(ii))))(ii) <= piv_int_pen(ii);
		end loop;
	end process proc_priority_matrix_table;

	gen_priority_level_vetoring : for level in 1 to 7 generate
		proc_priority_level_vectoring : process (pil_clk, pil_rst) is
		begin
			if pil_rst = '1' then
				stai_pen_prio_lvl_addr_loc(level) <= 0;
				stal_isr_pen_lvl_flag(level)      <= cl_NOTPENDING;
			elsif rising_edge(pil_clk) then
				if pil_prio_sel_en = '1' then
					stal_isr_pen_lvl_flag(level)  <= cl_NOTPENDING;

					for ii in 7 downto 0 loop
						if stav_priority_matrix(level)(ii) = cl_PENDING then
							stai_pen_prio_lvl_addr_loc(level) <= ii;
							stal_isr_pen_lvl_flag(level)      <= cl_PENDING;
						end if;
					end loop;
				end if;
			end if;
		end process;
	end generate;

	proc_priority_isr_selection : process (pil_prio_sel_en, pitav_int_isr_vector, stal_isr_pen_lvl_flag, stai_pen_prio_lvl_addr_loc) is
	begin
		sv_irq_id             <= (others => '0');
		sv_isr_vector_address <= (others => '0');
		sv_int_pen_clr        <= (others => '0');

		if pil_prio_sel_en = cl_ENABLE then
			if stal_isr_pen_lvl_flag(7) = cl_PENDING then
				sv_irq_id                                     <= std_logic_vector(to_unsigned(stai_pen_prio_lvl_addr_loc(7), sv_irq_id'length));
				sv_isr_vector_address                         <= pitav_int_isr_vector(stai_pen_prio_lvl_addr_loc(7));
				sv_int_pen_clr(stai_pen_prio_lvl_addr_loc(7)) <= cl_ENABLE;
			elsif stal_isr_pen_lvl_flag(6) = cl_PENDING then
				sv_irq_id                                     <= std_logic_vector(to_unsigned(stai_pen_prio_lvl_addr_loc(6), sv_irq_id'length));
				sv_isr_vector_address                         <= pitav_int_isr_vector(stai_pen_prio_lvl_addr_loc(6));
				sv_int_pen_clr(stai_pen_prio_lvl_addr_loc(6)) <= cl_ENABLE;
			elsif stal_isr_pen_lvl_flag(5) = cl_PENDING then
				sv_irq_id                                     <= std_logic_vector(to_unsigned(stai_pen_prio_lvl_addr_loc(5), sv_irq_id'length));
				sv_isr_vector_address                         <= pitav_int_isr_vector(stai_pen_prio_lvl_addr_loc(5));
				sv_int_pen_clr(stai_pen_prio_lvl_addr_loc(5)) <= cl_ENABLE;
			elsif stal_isr_pen_lvl_flag(4) = cl_PENDING then
				sv_irq_id                                     <= std_logic_vector(to_unsigned(stai_pen_prio_lvl_addr_loc(4), sv_irq_id'length));
				sv_isr_vector_address                         <= pitav_int_isr_vector(stai_pen_prio_lvl_addr_loc(4));
				sv_int_pen_clr(stai_pen_prio_lvl_addr_loc(4)) <= cl_ENABLE;
			elsif stal_isr_pen_lvl_flag(3) = cl_PENDING then
				sv_irq_id                                     <= std_logic_vector(to_unsigned(stai_pen_prio_lvl_addr_loc(3), sv_irq_id'length));
				sv_isr_vector_address                         <= pitav_int_isr_vector(stai_pen_prio_lvl_addr_loc(3));
				sv_int_pen_clr(stai_pen_prio_lvl_addr_loc(3)) <= cl_ENABLE;
			elsif stal_isr_pen_lvl_flag(2) = cl_PENDING then
				sv_irq_id                                     <= std_logic_vector(to_unsigned(stai_pen_prio_lvl_addr_loc(2), sv_irq_id'length));
				sv_isr_vector_address                         <= pitav_int_isr_vector(stai_pen_prio_lvl_addr_loc(2));
				sv_int_pen_clr(stai_pen_prio_lvl_addr_loc(2)) <= cl_ENABLE;
			elsif stal_isr_pen_lvl_flag(1) = cl_PENDING then
				sv_irq_id                                     <= std_logic_vector(to_unsigned(stai_pen_prio_lvl_addr_loc(1), sv_irq_id'length));
				sv_isr_vector_address                         <= pitav_int_isr_vector(stai_pen_prio_lvl_addr_loc(1));
				sv_int_pen_clr(stai_pen_prio_lvl_addr_loc(1)) <= cl_ENABLE;
			end if;
		end if;
	end process proc_priority_isr_selection;

	pol_irq         <= stal_isr_pen_lvl_flag(1) or
		stal_isr_pen_lvl_flag(2) or
		stal_isr_pen_lvl_flag(3) or
		stal_isr_pen_lvl_flag(4) or
		stal_isr_pen_lvl_flag(5) or
		stal_isr_pen_lvl_flag(6) or
		stal_isr_pen_lvl_flag(7);

	pov_irq_id      <= sv_irq_id;
	pov_int_pen_clr <= sv_int_pen_clr;
	pov_isr_vector  <= sv_isr_vector_address;

end architecture rtl;