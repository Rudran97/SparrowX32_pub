library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.core_pkg.all;
use work.options_pkg.all;
use work.csr_op_unit_pkg.all;
use work.tb_pkg.all;

entity tb_svx32_core_debug is
end entity;

architecture tb of tb_svx32_core_debug is

	signal pil_clk              : std_logic := '1';
	signal pil_rst              : std_logic := cl_RESET;
	signal pil_run_prg          : std_logic := cl_DISABLE;
	signal pol_next_inst        : std_logic;
	signal pol_ben              : std_logic;
	signal pil_fetch_mem_valid  : std_logic := cl_DISABLE;
	signal pil_fetch_mem_ack    : std_logic := cl_DISABLE;
	signal pol_fetch_mem_req    : std_logic;
	signal piv_fetch_mem_rdata  : std_logic_vector(31 downto 0) := (others => '0');
	signal pov_fetch_mem_addr   : std_logic_vector(31 downto 0);
	signal pil_mem_valid        : std_logic := cl_DISABLE;
	signal pil_mem_ack          : std_logic := cl_DISABLE;
	signal pol_mem_req          : std_logic;
	signal pol_mem_wen          : std_logic;
	signal piv_mem_rdata        : std_logic_vector(31 downto 0) := (others => '0');
	signal pov_mem_wdata        : std_logic_vector(31 downto 0);
	signal pov_mem_addr         : std_logic_vector(31 downto 0);
	signal pov_mem_byte_sel     : std_logic_vector(3 downto 0);
	signal pil_soft_irq         : std_logic := cl_DISABLE;
	signal pil_timer_irq        : std_logic := cl_DISABLE;
	signal pil_ext_irq          : std_logic := cl_DISABLE;
	signal pil_fast_irq         : std_logic := cl_DISABLE;
	signal piv_fast_irq_id      : std_logic_vector(3 downto 0)  := (others => '0');
	signal piv_fast_irq_vect    : std_logic_vector(31 downto 0) := (others => '0');
	signal pol_irq_pending      : std_logic;
	signal pil_debug_haltreq    : std_logic := cl_DISABLE;
	signal pil_debug_resumereq  : std_logic := cl_DISABLE;
	signal pol_debug_havereset  : std_logic;
	signal pol_debug_running    : std_logic;
	signal pol_debug_halted     : std_logic;
	signal pil_debug_regreq     : std_logic := cl_DISABLE;
	signal piv_debug_regno      : std_logic_vector(11 downto 0) := (others => '0');
	signal pil_debug_write      : std_logic := cl_DISABLE;
	signal piv_debug_wdata      : std_logic_vector(31 downto 0) := (others => '0');
	signal pov_debug_rdata      : std_logic_vector(31 downto 0);
	signal pol_debug_ack        : std_logic;
	signal pol_debug_err        : std_logic;
	signal pov_debug_pc_retired : std_logic_vector(31 downto 0);
	signal rvfi_valid           : std_logic;
	signal rvfi_order           : std_logic_vector(63 downto 0);
	signal rvfi_insn            : std_logic_vector(31 downto 0);
	signal rvfi_pc_rdata        : std_logic_vector(31 downto 0);

	--- signals and constants declared for mem_module ---
	constant cv_base_seg0 : std_logic_vector := "00";
	constant cv_base_seg1 : std_logic_vector := "01";
	constant cv_base_seg2 : std_logic_vector := "10";

	signal sl_mem_valid    : std_logic;
	signal sl_mem_ack      : std_logic;
	signal sl_mem_req      : std_logic;
	signal sl_mem_wen      : std_logic;
	signal sv_mem_addr     : std_logic_vector(31 downto 0);
	signal sv_mem_rdata    : std_logic_vector(31 downto 0);
	signal sv_mem_wdata    : std_logic_vector(31 downto 0);
	signal sv_mem_byte_sel : std_logic_vector(3 downto 0);

	signal si_mem_valid_delay_ct : integer := ci_mem_valid_delay_cycle;

	signal su_address_byte0 : unsigned(31 downto 2);
	signal su_address_byte1 : unsigned(31 downto 2);
	signal su_address_byte2 : unsigned(31 downto 2);
	signal su_address_byte3 : unsigned(31 downto 2);

	type t_mem_state is (idle_st, access_valid_st);
	signal st_mem_state : t_mem_state;

	alias av_mem_seg_sel : std_logic_vector(1 downto 0) is sv_mem_addr(1 downto 0);

	signal stav_mem0, stav_mem1, stav_mem2, stav_mem3 : tav_mem := (others => (others => '1'));

	signal sl_mem0_wen   : std_logic;
	signal sv_mem0_addr  : std_logic_vector(3 downto 0);
	signal sv_mem0_wdata : std_logic_vector(7 downto 0);
	signal sv_mem0_rdata : std_logic_vector(7 downto 0);

	signal sl_mem1_wen   : std_logic;
	signal sv_mem1_addr  : std_logic_vector(3 downto 0);
	signal sv_mem1_wdata : std_logic_vector(7 downto 0);
	signal sv_mem1_rdata : std_logic_vector(7 downto 0);

	signal sl_mem2_wen   : std_logic;
	signal sv_mem2_addr  : std_logic_vector(3 downto 0);
	signal sv_mem2_wdata : std_logic_vector(7 downto 0);
	signal sv_mem2_rdata : std_logic_vector(7 downto 0);
	signal sl_mem3_wen   : std_logic;
	signal sv_mem3_addr  : std_logic_vector(3 downto 0);
	signal sv_mem3_wdata : std_logic_vector(7 downto 0);
	signal sv_mem3_rdata : std_logic_vector(7 downto 0);

	--- signals declared for program memory ---
	signal stav_pmem : tav_pmem := ifc_init_ram_file(s_file_name => cs_dir_init_file & "rom.txt");

	signal sv_pmem_addr      : std_logic_vector(31 downto 0);
	signal sv_pmem_addr_next : std_logic_vector(31 downto 0);
	signal sv_pmem_rdata     : std_logic_vector(31 downto 0);
	signal sl_branch_taken   : boolean := false;

	signal sl_pmem_fetch_insn_req : std_logic;
	signal sv_fetch_mem_addr      : std_logic_vector(31 downto 0);
	signal sl_pmem_fetch_ack      : std_logic;
	signal sl_pmem_fetch_valid    : std_logic;

	type t_pmem_state is (idle_st, access_valid_st, wait_next_st);
	signal st_pmem_state : t_pmem_state;

	signal si_pmem_access_delay_ct : integer := ci_pmem_access_delay_cycle;

	constant ct_clk_period : time := 8.333333333333333 ns;

	type tas_GPR_string is array (0 to 31) of string(1 to 13);
	constant ctas_GPR_string : tas_GPR_string := (
		" x0      zero",
		" x1        ra",
		" x2        sp",
		" x3        gp",
		" x4        tp",
		" x5        t0",
		" x6        t1",
		" x7        t2",
		" x8     s0/fp",
		" x9        s1",
		"x10        a0",
		"x11        a1",
		"x12        a2",
		"x13        a3",
		"x14        a4",
		"x15        a5",
		"x16        a6",
		"x17        a7",
		"x18        s2",
		"x19        s3",
		"x20        s4",
		"x21        s5",
		"x22        s6",
		"x23        s7",
		"x24        s8",
		"x25        s9",
		"x26       s10",
		"x27       s11",
		"x28        t3",
		"x29        t4",
		"x30        t5",
		"x31        t6"
	);

	type tav_CSR is array (0 to 20) of std_logic_vector(11 downto 0);
	constant ctav_CSR : tav_CSR := (
		X"301",
		X"F11",
		X"F12",
		X"F13",
		X"F14",
		X"B02",
		X"300",
		X"304",
		X"305",
		X"344",
		X"342",
		X"341",
		X"340",
		X"343",
		X"7A0",
		X"7A1",
		X"7A2",
		X"7B0",
		X"7B1",
		X"7B2",
		X"7B3"
	);

	type tas_CSR_string is array (0 to 20) of string(1 to 9);
	constant ctas_CSR_string : tas_CSR_string := (
		"MISA     ",
		"MVENDORID",
		"MARCHID  ",
		"MIMPID   ",
		"MHARTID  ",
		"MINSTRET ",
		"MSTATUS  ",
		"MIE      ",
		"MTVEC    ",
		"MIP      ",
		"MCAUSE   ",
		"MEPC     ",
		"MSCRATCH ",
		"MTVAL    ",
		"TSELECT  ",
		"TDATA1   ",
		"TDATA2   ",
		"DCSR     ",
		"DPC      ",
		"DSCRATCH0",
		"DSCRATCH1"
	);

	constant cv_DBG_COMMAND_DCSR_step : std_logic_vector(31 downto 0) := X"0000_0004";
	constant cv_DBG_TDATA1_execute    : std_logic_vector(31 downto 0) := X"0000_0004";
	constant cv_DBG_TSELECT_TRIG0     : std_logic_vector(31 downto 0) := X"0000_0000";
	constant cv_DBG_TSELECT_TRIG1     : std_logic_vector(31 downto 0) := X"0000_0001";

	signal sl_debug_read_success : std_logic;

	signal ss_debug_file_name : string(1 to 16);

begin

	gen_debug_file_name : if cb_MULTI_CYCLE_FETCH = true generate
		ss_debug_file_name <= "debug_log_mc.txt";
	else generate
		ss_debug_file_name <= "debug_log_sc.txt";
	end generate;
		

	-----------------------------------------------------------------------------------------------------
	-------------------------------------- Memory Module Unit -------------------------------------------
	-----------------------------------------------------------------------------------------------------

	sl_mem_req  <= pol_mem_req;
	sv_mem_addr <= pov_mem_addr;

	proc_mem_module : process (pil_clk, pil_rst)
	begin
		if pil_rst = cl_RESET then
			sl_mem_valid    <= cl_DISABLE;
			sl_mem_ack      <= cl_DISABLE;
			sv_mem_byte_sel <= (others => '0');
			st_mem_state    <= idle_st;
		elsif rising_edge(pil_clk) then
			sl_mem_ack      <= cl_DISABLE;
			sl_mem_valid    <= cl_DISABLE;
			sl_mem_wen      <= cl_DISABLE;
			sv_mem_wdata    <= (others => '0');
			sv_mem_byte_sel <= (others => '0');
			case st_mem_state is
				when idle_st =>
					if sl_mem_req = cl_ENABLE then
						sl_mem_wen      <= pol_mem_wen;
						sv_mem_wdata    <= pov_mem_wdata;
						sv_mem_byte_sel <= pov_mem_byte_sel;
						case av_mem_seg_sel is
							when cv_base_seg0 =>
								su_address_byte0 <= unsigned(sv_mem_addr(31 downto 2));
								su_address_byte1 <= unsigned(sv_mem_addr(31 downto 2));
								su_address_byte2 <= unsigned(sv_mem_addr(31 downto 2));
								su_address_byte3 <= unsigned(sv_mem_addr(31 downto 2));
							when cv_base_seg1 =>
								su_address_byte0 <= unsigned(sv_mem_addr(31 downto 2)) + 1;
								su_address_byte1 <= unsigned(sv_mem_addr(31 downto 2));
								su_address_byte2 <= unsigned(sv_mem_addr(31 downto 2));
								su_address_byte3 <= unsigned(sv_mem_addr(31 downto 2));
							when cv_base_seg2 =>
								su_address_byte0 <= unsigned(sv_mem_addr(31 downto 2)) + 1;
								su_address_byte1 <= unsigned(sv_mem_addr(31 downto 2)) + 1;
								su_address_byte2 <= unsigned(sv_mem_addr(31 downto 2));
								su_address_byte3 <= unsigned(sv_mem_addr(31 downto 2));
							when others =>
								su_address_byte0 <= unsigned(sv_mem_addr(31 downto 2)) + 1;
								su_address_byte1 <= unsigned(sv_mem_addr(31 downto 2)) + 1;
								su_address_byte2 <= unsigned(sv_mem_addr(31 downto 2)) + 1;
								su_address_byte3 <= unsigned(sv_mem_addr(31 downto 2));
						end case;
						sl_mem_ack   <= cl_ENABLE;
						st_mem_state <= access_valid_st;
					end if;
				when access_valid_st =>
					if si_mem_valid_delay_ct = 0 then
						sl_mem_valid          <= cl_ENABLE;
						si_mem_valid_delay_ct <= ci_mem_valid_delay_cycle;
						st_mem_state          <= idle_st;
					else
						si_mem_valid_delay_ct <= si_mem_valid_delay_ct - 1;
					end if;
			end case;
		end if;
	end process proc_mem_module;

	sv_mem_rdata <= sv_mem3_rdata & sv_mem2_rdata & sv_mem1_rdata & sv_mem0_rdata;

	--- memory blocks ---

	sl_mem0_wen   <= sv_mem_byte_sel(0) and sl_mem_wen;
	sv_mem0_addr  <= std_logic_vector(su_address_byte0(5 downto 2));
	sv_mem0_wdata <= sv_mem_wdata(7 downto 0);

	proc_mem0 : process (pil_clk) is
	begin
		if rising_edge(pil_clk) then
			if sl_mem0_wen = '1' then
				stav_mem0(to_integer(unsigned(sv_mem0_addr))) <= sv_mem0_wdata;
			end if;
		end if;
	end process proc_mem0;

	sv_mem0_rdata <= stav_mem0(to_integer(unsigned(sv_mem0_addr)));

	sl_mem1_wen   <= sv_mem_byte_sel(1) and sl_mem_wen;
	sv_mem1_addr  <= std_logic_vector(su_address_byte1(5 downto 2));
	sv_mem1_wdata <= sv_mem_wdata(15 downto 8);

	proc_mem1 : process (pil_clk) is
	begin
		if rising_edge(pil_clk) then
			if sl_mem1_wen = '1' then
				stav_mem1(to_integer(unsigned(sv_mem1_addr))) <= sv_mem1_wdata;
			end if;
		end if;
	end process proc_mem1;

	sv_mem1_rdata <= stav_mem1(to_integer(unsigned(sv_mem1_addr)));

	sl_mem2_wen   <= sv_mem_byte_sel(2) and sl_mem_wen;
	sv_mem2_addr  <= std_logic_vector(su_address_byte2(5 downto 2));
	sv_mem2_wdata <= sv_mem_wdata(23 downto 16);

	proc_mem2 : process (pil_clk) is
	begin
		if rising_edge(pil_clk) then
			if sl_mem2_wen = '1' then
				stav_mem2(to_integer(unsigned(sv_mem2_addr))) <= sv_mem2_wdata;
			end if;
		end if;
	end process proc_mem2;

	sv_mem2_rdata <= stav_mem2(to_integer(unsigned(sv_mem2_addr)));

	sl_mem3_wen   <= sv_mem_byte_sel(3) and sl_mem_wen;
	sv_mem3_addr  <= std_logic_vector(su_address_byte3(5 downto 2));
	sv_mem3_wdata <= sv_mem_wdata(31 downto 24);

	proc_mem3 : process (pil_clk) is
	begin
		if rising_edge(pil_clk) then
			if sl_mem3_wen = '1' then
				stav_mem3(to_integer(unsigned(sv_mem3_addr))) <= sv_mem3_wdata;
			end if;
		end if;
	end process proc_mem3;

	sv_mem3_rdata <= stav_mem3(to_integer(unsigned(sv_mem3_addr)));

	-----------------------------------------------------------------------------------------------------
	------------------------------------ Program Memory Module ------------------------------------------
	-----------------------------------------------------------------------------------------------------

	gen_multi_cycle_fetch : if cb_MULTI_CYCLE_FETCH = true generate

		sl_pmem_fetch_insn_req <= pol_fetch_mem_req;

		proc_fetch_valid : process(pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				sl_pmem_fetch_ack   <= cl_DISABLE;
				sl_pmem_fetch_valid <= cl_DISABLE;
				sv_fetch_mem_addr   <= (others => '0');
				st_pmem_state       <= idle_st;
			elsif rising_edge(pil_clk) then
				sl_pmem_fetch_ack   <= cl_DISABLE;
				sl_pmem_fetch_valid <= cl_DISABLE;
				case st_pmem_state is
					when idle_st =>
						if sl_pmem_fetch_insn_req = cl_ENABLE then
							sv_fetch_mem_addr <= '0' & pov_fetch_mem_addr(30 downto 0);
							st_pmem_state     <= access_valid_st;
						end if;
					when access_valid_st =>
						sl_pmem_fetch_ack <= cl_ENABLE;
						sv_fetch_mem_addr <= '0' & pov_fetch_mem_addr(30 downto 0);

						if si_pmem_access_delay_ct = 0 then
							sl_pmem_fetch_valid     <= cl_ENABLE;
							si_pmem_access_delay_ct <= ci_pmem_access_delay_cycle;
							st_pmem_state           <= wait_next_st;
						else
							si_pmem_access_delay_ct <= si_pmem_access_delay_ct - 1;
						end if;
					when wait_next_st =>
						sl_pmem_fetch_ack   <= cl_ENABLE; -- hold ack
						sl_pmem_fetch_valid <= cl_ENABLE;

						if sl_pmem_fetch_insn_req = cl_DISABLE then
							st_pmem_state <= idle_st;
						end if;
				end case;
			end if;
		end process proc_fetch_valid;
	else gen_single_cycle_fetch : generate
		sl_pmem_fetch_ack   <= cl_ENABLE;
		sl_pmem_fetch_valid <= cl_ENABLE;
		sv_fetch_mem_addr   <= '0' & pov_fetch_mem_addr(30 downto 0);
	end generate;

	gen_rvfi_pmem_addr : if cb_RVFI_PMEM_ADDR = true generate
		proc_rvfi_pmem_addr : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				sl_branch_taken <= false;
				sv_pmem_addr    <= (others => '0');
			elsif rising_edge(pil_clk) then
				if pol_ben = cl_ENABLE and sl_branch_taken = false then
					sl_branch_taken <= true;
					sv_pmem_addr    <= std_logic_vector(unsigned(sv_pmem_addr) - 2);
				elsif pol_next_inst = cl_ENABLE then
					sl_branch_taken <= false;
					sv_pmem_addr    <= std_logic_vector(unsigned(sv_pmem_addr) + 1);
				end if;
			end if;
		end process proc_rvfi_pmem_addr;
		
		proc_pmem : process (sv_pmem_addr)
		begin
			sv_pmem_rdata <= stav_pmem(to_integer(unsigned(sv_pmem_addr)));
		end process;
	else generate
		proc_pmem_addr : process (sv_fetch_mem_addr)
		begin
			sv_pmem_addr      <= sv_fetch_mem_addr(31 downto 0);
			sv_pmem_addr_next <= std_logic_vector(unsigned(sv_fetch_mem_addr) + 2);
		end process proc_pmem_addr;

		proc_pmem : process (pil_clk)
		begin
			if rising_edge(pil_clk) then
				if sv_fetch_mem_addr(1 downto 0) = "10" then
					sv_pmem_rdata <= stav_pmem(to_integer(unsigned(sv_pmem_addr_next(31 downto 2))))(15 downto 0) & stav_pmem(to_integer(unsigned(sv_pmem_addr(31 downto 2))))(31 downto 16);
				else
					sv_pmem_rdata <= stav_pmem(to_integer(unsigned(sv_pmem_addr_next(31 downto 2))))(31 downto 16) & stav_pmem(to_integer(unsigned(sv_pmem_addr(31 downto 2))))(15 downto 0);
				end if;
			end if;
		end process;
	end generate;

	-----------------------------------------------------------------------------------------------------
	-------------------------------------- DUT : CORE Module --------------------------------------------
	-----------------------------------------------------------------------------------------------------

	pil_mem_valid <= sl_mem_valid;
	pil_mem_ack   <= sl_mem_ack;
	piv_mem_rdata <= sv_mem_rdata;

	pil_fetch_mem_ack   <= sl_pmem_fetch_ack;
	pil_fetch_mem_valid <= sl_pmem_fetch_valid;
	piv_fetch_mem_rdata <= sv_pmem_rdata;

	dut_svx32_core : entity work.svx32_core
		port map(
			pil_clk              => pil_clk,
			pil_rst              => pil_rst,
			pil_run_prg          => pil_run_prg,
			pol_next_inst        => pol_next_inst,
			pol_ben              => pol_ben,
			pil_fetch_mem_valid  => pil_fetch_mem_valid,
			pil_fetch_mem_ack    => pil_fetch_mem_ack,
			pol_fetch_mem_req    => pol_fetch_mem_req,
			piv_fetch_mem_rdata  => piv_fetch_mem_rdata,
			pov_fetch_mem_addr   => pov_fetch_mem_addr,
			pil_mem_valid        => pil_mem_valid,
			pil_mem_ack          => pil_mem_ack,
			pol_mem_req          => pol_mem_req,
			pol_mem_wen          => pol_mem_wen,
			piv_mem_rdata        => piv_mem_rdata,
			pov_mem_wdata        => pov_mem_wdata,
			pov_mem_addr         => pov_mem_addr,
			pov_mem_byte_sel     => pov_mem_byte_sel,
			pil_soft_irq         => pil_soft_irq,
			pil_timer_irq        => pil_timer_irq,
			pil_ext_irq          => pil_ext_irq,
			pil_fast_irq         => pil_fast_irq,
			piv_fast_irq_id      => piv_fast_irq_id,
			piv_fast_irq_vect    => piv_fast_irq_vect,
			pol_irq_pending      => pol_irq_pending,
			pil_debug_haltreq    => pil_debug_haltreq,
			pil_debug_resumereq  => pil_debug_resumereq,
			pol_debug_havereset  => pol_debug_havereset,
			pol_debug_running    => pol_debug_running,
			pol_debug_halted     => pol_debug_halted,
			pil_debug_regreq     => pil_debug_regreq,
			piv_debug_regno      => piv_debug_regno,
			pil_debug_write      => pil_debug_write,
			piv_debug_wdata      => piv_debug_wdata,
			pov_debug_rdata      => pov_debug_rdata,
			pol_debug_ack        => pol_debug_ack,
			pol_debug_err        => pol_debug_err,
			pov_debug_pc_retired => pov_debug_pc_retired,
			rvfi_valid           => rvfi_valid,
			rvfi_order           => rvfi_order,
			rvfi_insn            => rvfi_insn,
			rvfi_pc_rdata        => rvfi_pc_rdata
		);

	pil_clk     <= not pil_clk after ct_clk_period / 2;
	pil_rst     <= cl_NOTRESET after ct_clk_period;

	gen_stimuli : if cb_IRQ_test = true generate
		assert false report "IRQ Test Enabled" severity warning;
		proc_stimuli : process
		begin
			pil_run_prg <= cl_ENABLE;
			wait for 2.17 us;

			--- first irq ---
			pil_fast_irq      <= CL_ENABLE;
			piv_fast_irq_id   <= X"A";
			piv_fast_irq_vect <= X"0000_0100";
			wait for ct_clk_period;

			wait until rising_edge(pol_irq_pending);

			-- wait for 3 us;
			pil_fast_irq <= cl_DISABLE;

			-- --- 2nd IRQ ---
			-- wait for 1.1 us;
			-- pil_timer_irq <= cl_ENABLE;
			-- wait for ct_clk_period;

			-- -- wait until falling_edge(pol_irq_pending);

			-- -- wait for 3 us;
			-- pil_timer_irq <= cl_DISABLE;

			---
			wait for 20 us;

			pr_dump_ram(seg3 => stav_mem3, seg2 => stav_mem2, seg1 => stav_mem1, seg0 => stav_mem0);

			wait for ct_clk_period;
			assert false report "*** END OF SIMULATION!!! ***" severity failure;
		end process proc_stimuli;
	elsif cb_DEBUG = true generate
		proc_stimuli : process

			procedure pr_debug_clear_log is
				file f_debug_file           : text;
			begin
				file_open(f_debug_file, cs_dir_init_file & ss_debug_file_name, write_mode);
				file_close(f_debug_file);
			end procedure;

			procedure pr_debug_log(
				signal l_success : out std_logic
			) is
				file f_debug_file           : text;
				variable vln_mem_line       : line;
				variable vs_hex_string      : string(1 to 8);
				variable vv_debug_reg_rdata : std_logic_vector(31 downto 0);
			begin
				file_open(f_debug_file, cs_dir_init_file & ss_debug_file_name, append_mode);
				write(vln_mem_line, string'("-----------------------------------------------------------------"));
				writeline(f_debug_file, vln_mem_line);

				write(vln_mem_line, string'("Core GPR : "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);

				--- get GPR values ---
				for ii in 0 to 31 loop
					wait for ct_clk_period;
					pil_debug_regreq   <= cl_ENABLE;
					piv_debug_regno    <= std_logic_vector(X"000" + to_unsigned(ii, 12));
					pil_debug_write    <= cl_DISABLE;
					wait until rising_edge(pol_debug_ack);
					pil_debug_regreq   <= cl_DISABLE;
					vv_debug_reg_rdata := pov_debug_rdata;

					vs_hex_string := ifc_to_hstring(to_bitvector(vv_debug_reg_rdata));
					write(vln_mem_line, ctas_GPR_string(ii));
					write(vln_mem_line, string'(" "), right, 6);
					write(vln_mem_line, vs_hex_string, right);
					writeline(f_debug_file, vln_mem_line);
				end loop;

				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("---"));
				writeline(f_debug_file, vln_mem_line);

				write(vln_mem_line, string'("Control and Status Registers : "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);

				--- get CSR values ---
				for ii in tav_CSR'low to tav_CSR'high loop
					wait for ct_clk_period;
					pil_debug_regreq   <= cl_ENABLE;
					piv_debug_regno    <= ctav_CSR(ii);
					pil_debug_write    <= cl_DISABLE;
					wait until rising_edge(pol_debug_ack);
					pil_debug_regreq   <= cl_DISABLE;
					vv_debug_reg_rdata := pov_debug_rdata;

					vs_hex_string := ifc_to_hstring(to_bitvector(vv_debug_reg_rdata));
					write(vln_mem_line, ctas_CSR_string(ii));
					write(vln_mem_line, string'("          "));
					write(vln_mem_line, vs_hex_string);
					writeline(f_debug_file, vln_mem_line);
				end loop;

				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("-----------------------------------------------------------------"));
				writeline(f_debug_file, vln_mem_line);

				file_close(f_debug_file);

				l_success <= pol_debug_err;
			end procedure;

			procedure pr_debug_enter is
				file f_debug_file           : text;
				variable vln_mem_line       : line;
				variable vs_hex_string      : string(1 to 8);
			begin
				pil_debug_haltreq <= cl_ENABLE;
				wait until rising_edge(pol_debug_halted);
				pil_debug_haltreq <= cl_DISABLE;

				file_open(f_debug_file, cs_dir_init_file & ss_debug_file_name, append_mode);
				write(vln_mem_line, string'("ENTERING Debug mode : "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("Instruction 0x"));
				vs_hex_string := ifc_to_hstring(to_bitvector(rvfi_insn));
				write(vln_mem_line, vs_hex_string);
				write(vln_mem_line, string'("   Address 0x"));
				vs_hex_string := ifc_to_hstring(to_bitvector(rvfi_pc_rdata));
				write(vln_mem_line, vs_hex_string);
				writeline(f_debug_file, vln_mem_line);
				file_close(f_debug_file);

				--- log GPRs and CSRs ---
				pr_debug_log(l_success => sl_debug_read_success);
			end procedure;

			procedure pr_debug_exit is
				file f_debug_file           : text;
				variable vln_mem_line       : line;
			begin
				file_open(f_debug_file, cs_dir_init_file & ss_debug_file_name, append_mode);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("EXITING Debug mode"));
				writeline(f_debug_file, vln_mem_line);
				file_close(f_debug_file);

				--- disable debug step ---
				wait for ct_clk_period;
				pil_debug_regreq   <= cl_ENABLE;
				piv_debug_regno    <= std_logic_vector(cv_ADDR_DCSR);
				pil_debug_write    <= cl_ENABLE;
				piv_debug_wdata    <= (others => '0');
				wait until rising_edge(pol_debug_ack);
				pil_debug_regreq   <= cl_DISABLE;
				pil_debug_write    <= cl_DISABLE;
			end procedure;

			procedure pr_resume is
				file f_debug_file           : text;
				variable vln_mem_line       : line;
			begin
				file_open(f_debug_file, cs_dir_init_file & ss_debug_file_name, append_mode);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("Running ..."));
				writeline(f_debug_file, vln_mem_line);
				file_close(f_debug_file);

				--- resume/step through next instruction ---
				wait for ct_clk_period;
				pil_debug_resumereq <= cl_ENABLE;
				wait for ct_clk_period;
				pil_debug_resumereq <= cl_DISABLE;
			end procedure;

			procedure pr_debug_exit_and_resume is
			begin
				pr_debug_exit;
				pr_resume;
			end procedure;

			procedure pr_debug_step_log is
				file f_debug_file           : text;
				variable vln_mem_line       : line;
				variable vs_hex_string      : string(1 to 8);
			begin
				--- set debug mode to step ---
				wait for ct_clk_period;
				pil_debug_regreq   <= cl_ENABLE;
				piv_debug_regno    <= std_logic_vector(cv_ADDR_DCSR);
				pil_debug_write    <= cl_ENABLE;
				piv_debug_wdata    <= cv_DBG_COMMAND_DCSR_step;
				wait until rising_edge(pol_debug_ack);
				pil_debug_regreq   <= cl_DISABLE;
				pil_debug_write    <= cl_DISABLE;

				--- step through next instruction ---
				pr_resume;
				wait until rising_edge(pol_debug_halted);

				file_open(f_debug_file, cs_dir_init_file & ss_debug_file_name, append_mode);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("-----------------------------------------------------------------"));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("STEPPING : "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("Order 0x"));
				vs_hex_string := ifc_to_hstring(to_bitvector(rvfi_order(31 downto 0)));
				write(vln_mem_line, vs_hex_string);
				write(vln_mem_line, string'("   Instruction 0x"));
				vs_hex_string := ifc_to_hstring(to_bitvector(rvfi_insn));
				write(vln_mem_line, vs_hex_string);
				write(vln_mem_line, string'("   Address 0x"));
				vs_hex_string := ifc_to_hstring(to_bitvector(rvfi_pc_rdata));
				write(vln_mem_line, vs_hex_string);
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("-----------------------------------------------------------------"));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				file_close(f_debug_file);

				--- log GPRs and CSRs ---
				pr_debug_log(l_success => sl_debug_read_success);
			end procedure;

			procedure pr_set_trigger_match (
				v_match_addr      : in std_logic_vector(31 downto 0);
				v_trig_mod_select : in std_logic_vector(31 downto 0)
			) is
				file f_debug_file           : text;
				variable vln_mem_line       : line;
				variable vs_hex_string      : string(1 to 8);
			begin
				--- select trig module to modify ---
				wait for ct_clk_period;
				pil_debug_regreq   <= cl_ENABLE;
				piv_debug_regno    <= std_logic_vector(cv_ADDR_TSELECT);
				pil_debug_write    <= cl_ENABLE;
				piv_debug_wdata    <= v_trig_mod_select;
				wait until rising_edge(pol_debug_ack);
				pil_debug_regreq   <= cl_DISABLE;
				pil_debug_write    <= cl_DISABLE;

				--- Enable trigger module by setting execute bit ---
				wait for ct_clk_period;
				pil_debug_regreq   <= cl_ENABLE;
				piv_debug_regno    <= std_logic_vector(cv_ADDR_TDATA1);
				pil_debug_write    <= cl_ENABLE;
				piv_debug_wdata    <= cv_DBG_TDATA1_execute;
				wait until rising_edge(pol_debug_ack);
				pil_debug_regreq   <= cl_DISABLE;
				pil_debug_write    <= cl_DISABLE;

				--- set match address ---
				wait for ct_clk_period;
				pil_debug_regreq   <= cl_ENABLE;
				piv_debug_regno    <= std_logic_vector(cv_ADDR_TDATA2);
				pil_debug_write    <= cl_ENABLE;
				piv_debug_wdata    <= v_match_addr;
				wait until rising_edge(pol_debug_ack);
				pil_debug_regreq   <= cl_DISABLE;
				pil_debug_write    <= cl_DISABLE;

				file_open(f_debug_file, cs_dir_init_file & ss_debug_file_name, append_mode);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("-----------------------------------------------------------------"));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("Set TRIGGER MODULE "));
				vs_hex_string := ifc_to_hstring(to_bitvector(v_trig_mod_select));
				write(vln_mem_line, vs_hex_string);
				write(vln_mem_line, string'(" at : "));
				write(vln_mem_line, string'("0x"));
				vs_hex_string := ifc_to_hstring(to_bitvector(v_match_addr));
				write(vln_mem_line, vs_hex_string);
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("-----------------------------------------------------------------"));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				file_close(f_debug_file);
			end procedure;

			procedure pr_debug_log_on_trigger_match is
				file f_debug_file           : text;
				variable vln_mem_line       : line;
				variable vs_hex_string      : string(1 to 8);
			begin
				pr_resume;
				wait until rising_edge(pol_debug_halted);

				file_open(f_debug_file, cs_dir_init_file & ss_debug_file_name, append_mode);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("-----------------------------------------------------------------"));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("TRIGGER MATCH : Entering debug mode ..."));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("Order 0x"));
				vs_hex_string := ifc_to_hstring(to_bitvector(rvfi_order(31 downto 0)));
				write(vln_mem_line, vs_hex_string);
				write(vln_mem_line, string'("   Instruction 0x"));
				vs_hex_string := ifc_to_hstring(to_bitvector(rvfi_insn));
				write(vln_mem_line, vs_hex_string);
				write(vln_mem_line, string'("   Address 0x"));
				vs_hex_string := ifc_to_hstring(to_bitvector(rvfi_pc_rdata));
				write(vln_mem_line, vs_hex_string);
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'("-----------------------------------------------------------------"));
				writeline(f_debug_file, vln_mem_line);
				write(vln_mem_line, string'(" "));
				writeline(f_debug_file, vln_mem_line);
				file_close(f_debug_file);

				--- log GPRs and CSRs ---
				pr_debug_log(l_success => sl_debug_read_success);
			end procedure;

			variable vi_valid_ct : integer := 1;

		begin
			wait for ct_clk_period;
			pr_debug_clear_log;

			pil_run_prg <= cl_ENABLE;
			wait until falling_edge(pol_debug_havereset);
			assert false report "Core Out of Reset" severity warning;

			--------------------
			--- Trigger test ---
			--------------------
			pr_debug_enter;

			if cb_RISCV_FORMAL = true then
				assert pov_debug_pc_retired = rvfi_pc_rdata report "Incorrect PC" severity failure;
			end if;

			pr_set_trigger_match(v_match_addr => X"00000038", v_trig_mod_select => cv_DBG_TSELECT_TRIG0);
			pr_set_trigger_match(v_match_addr => X"00000080", v_trig_mod_select => cv_DBG_TSELECT_TRIG1);
			pr_debug_exit;

			pr_debug_log_on_trigger_match;

			if cb_RISCV_FORMAL = true then
				assert pov_debug_pc_retired = rvfi_pc_rdata report "Incorrect PC" severity failure;
			end if;

			-- pr_set_trigger_match(v_match_addr => X"00000038", v_trig_mod_select => cv_DBG_TSELECT_TRIG0);
			pr_set_trigger_match(v_match_addr => X"80000090", v_trig_mod_select => cv_DBG_TSELECT_TRIG1);
			assert false report "Trigger1 set" severity note;
			wait for 1 us;
			pr_debug_exit_and_resume;

			pr_debug_log_on_trigger_match;

			if cb_RISCV_FORMAL = true then
				assert pov_debug_pc_retired = rvfi_pc_rdata report "Incorrect PC" severity failure;
			end if;

			pr_debug_exit_and_resume;

			wait for 20 us;

			pr_dump_ram(seg3 => stav_mem3, seg2 => stav_mem2, seg1 => stav_mem1, seg0 => stav_mem0);

			wait for ct_clk_period;
			assert false report "*** END OF SIMULATION!!! ***" severity failure;
		end process proc_stimuli;
	else generate
		proc_stimuli : process
		begin
			wait for 10 us;
			pil_run_prg <= cl_ENABLE;
			wait for 20 us;
			-- assert stav_mem3(15) = X"01" and pol_core_hlt = cl_DISABLE report "*** ERR : EXIT CODE ***" severity warning;

			pr_dump_ram(seg3 => stav_mem3, seg2 => stav_mem2, seg1 => stav_mem1, seg0 => stav_mem0);

			wait for ct_clk_period;
			assert false report "*** END OF SIMULATION!!! ***" severity failure;
		end process proc_stimuli;
	end generate;

end architecture;