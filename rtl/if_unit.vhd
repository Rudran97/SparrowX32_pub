library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity if_unit is
	generic (
		gv_PC_ORIGIN             : std_logic_vector(31 downto 0) := X"0000_0000";
		gb_EXT_C                 : boolean                       := true;
        gb_MULTI_CYCLE_FETCH     : boolean                       := true;
		gb_RISCV_FORMAL          : boolean                       := false
	);
	port (
		pil_clk                  : in std_logic;
		pil_rst                  : in std_logic;
		pol_is_compressed        : out std_logic;
		pol_illegal_inst         : out std_logic;
		pov_rvfi_compressed_isnt : out std_logic_vector(31 downto 0);
		potr_inst                : out tr_IF_base_format;

		pil_pipe_start           : in std_logic;
		pil_pipe_ready           : in std_logic;
		pil_fetch_en             : in std_logic;
		pil_insn_first_fetch     : in std_logic;
		pol_insn_valid           : out std_logic;
		pol_prefetch_stall       : out std_logic;

		--- interface to the memory module ---
		pil_mem_valid            : in std_logic;
		pil_mem_ack              : in std_logic;
		pol_mem_req              : out std_logic;

		piv_mem_rdata            : in std_logic_vector(31 downto 0);
		pov_mem_addr             : out std_logic_vector(31 downto 0);

		--- program header ---
		pil_if_ben               : in std_logic;
		pil_if_cen               : in std_logic;
		piv_if_baddr             : in std_logic_vector(31 downto 0);
		pov_if_addr              : out std_logic_vector(31 downto 0)
	);
end entity;

architecture rtl of if_unit is

	signal sl_is_compressed        : std_logic;
	signal sl_illegal_inst         : std_logic;

	--- multi-cycle fetch ---
	signal str_inst                : tr_IF_base_format;
	signal str_inst32              : tr_IF_base_format;
	signal sv_rvfi_compressed_isnt : std_logic_vector(31 downto 0);

	signal su_prg_head             : unsigned(32 downto 0);
	signal su_prg_head_next        : unsigned(32 downto 0);

	signal sl_fetch_req            : std_logic;
	signal sl_bfetch_req           : std_logic;
	signal sv_fetch_addr           : std_logic_vector(31 downto 0);
	signal sv_bfetch_addr          : std_logic_vector(31 downto 0);
	signal sv_fetch_rdata          : std_logic_vector(31 downto 0);
	signal sl_fetch_valid          : std_logic;

	--- signal-cycle fetch ---
	signal sl_fetch_next           : std_logic;
	signal sl_if_ben               : std_logic;
	signal sv_if_baddr             : std_logic_vector(31 downto 0);
	signal sl_insn_is_compressed   : std_logic;
	signal sv_addr_to_core         : std_logic_vector(31 downto 0);

	signal sl_prefetch_stall       : std_logic;

begin

	gen_compressed_decoder : if gb_EXT_C = true generate
		inst_compressed_decoder : entity work.compressed_decoder
			generic map (
				gb_RISCV_FORMAL => gb_RISCV_FORMAL
			)
			port map(
				pitr_inst                => str_inst,
				pol_is_compressed        => sl_is_compressed,
				pol_illegal_inst         => sl_illegal_inst,
				pov_rvfi_compressed_isnt => sv_rvfi_compressed_isnt,
				potr_inst                => str_inst32
			);

		pov_rvfi_compressed_isnt <= sv_rvfi_compressed_isnt;
		potr_inst                <= str_inst32;
	else generate
		sl_is_compressed <= cl_DISABLE;
		sl_illegal_inst  <= cl_DISABLE;

		pov_rvfi_compressed_isnt <= (others => '0');
		potr_inst                <= str_inst;
	end generate;

	gen_mc_fetch : if gb_MULTI_CYCLE_FETCH = true generate
        assert false report "*** Multi-Cycle fetch selected ***" severity warning;

		proc_prg_head : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_ENABLE then
				su_prg_head <= '0' & unsigned(gv_PC_ORIGIN);
			elsif rising_edge(pil_clk) then
				if pil_if_ben = cl_ENABLE then
					su_prg_head <= unsigned('0' & piv_if_baddr);
				elsif pil_if_cen = cl_ENABLE then
					su_prg_head <= su_prg_head_next;
					if su_prg_head > X"FFFF_FFFF" then
						su_prg_head(32) <= '0';
					end if;
				end if;
			end if;
		end process proc_prg_head;

		sl_fetch_req   <= pil_insn_first_fetch or pil_if_cen or pil_if_ben;
		sl_bfetch_req  <= pil_if_ben;
		sv_fetch_addr  <= std_logic_vector(su_prg_head(31 downto 0));
		sv_bfetch_addr <= piv_if_baddr;

		inst_fetch_module : entity work.fetch_interface_module
			port map (
				pil_clk         => pil_clk,
				pil_rst         => pil_rst,
				pil_pipe_ready  => pil_pipe_ready,
				pil_mem_valid   => pil_mem_valid,
				pil_mem_ack     => pil_mem_ack,
				pol_mem_req     => pol_mem_req,
				piv_mem_rdata   => piv_mem_rdata,
				pov_mem_addr    => pov_mem_addr,
				pil_fetch_en    => pil_fetch_en,
				pil_fetch_req   => sl_fetch_req,
				pil_bfetch_req  => sl_bfetch_req,
				piv_fetch_addr  => sv_fetch_addr,
				piv_bfetch_addr => sv_bfetch_addr,
				pov_fetch_rdata => sv_fetch_rdata,
				pol_fetch_valid => sl_fetch_valid
		);

		str_inst           <= ftr_inst_slv2rec(instruction => sv_fetch_rdata);
		su_prg_head_next   <= su_prg_head + 2 when sl_is_compressed = cl_ENABLE else su_prg_head + 4;

		pol_insn_valid     <= sl_fetch_valid;
		
		pol_is_compressed  <= sl_is_compressed;
		pol_illegal_inst   <= sl_illegal_inst;

		pov_if_addr        <= std_logic_vector(su_prg_head(31 downto 0));
		pol_prefetch_stall <= cl_DISABLE;

	else gen_sc_fetch : generate
        assert false report "*** Single-cycle latency fetch selected ***" severity warning;

		sl_fetch_next         <= pil_insn_first_fetch or pil_if_cen;
		sl_if_ben             <= pil_if_ben;
		sv_if_baddr           <= piv_if_baddr;
		sl_insn_is_compressed <= sl_is_compressed;

		inst_prefetch_buff : entity work.prefetch_buffer
			generic map(
				gv_PC_ORIGIN         => gv_PC_ORIGIN
			)
			port map(
				pil_clk              => pil_clk,
				pil_rst              => pil_rst,

				pil_first_fetch      => pil_insn_first_fetch,
				pil_pipe_ready       => pil_pipe_ready,
				pil_fetch_next       => sl_fetch_next,
				pil_if_ben           => sl_if_ben,
				piv_if_baddr         => sv_if_baddr,
				pil_is_compressed    => sl_insn_is_compressed,

				pov_fetch_rdata      => sv_fetch_rdata,
				pol_fetch_valid      => sl_fetch_valid,

				piv_mem_rdata        => piv_mem_rdata,
				pov_mem_addr         => pov_mem_addr,

				pov_addr_to_core     => sv_addr_to_core
			);
		
		proc_prefetch_stall : process (pil_clk, pil_rst)
		begin
			if pil_rst = cl_RESET then
				sl_prefetch_stall <= cl_ENABLE;
			elsif rising_edge(pil_clk) then
				--- This will basically stall the pipeline for 1 clock cycle until the
				--- prefetch buffer is ready to fetch the 2nd instruction.
				sl_prefetch_stall <= not pil_pipe_start;
			end if;
		end process proc_prefetch_stall ;
		
		str_inst           <= ftr_inst_slv2rec(instruction => sv_fetch_rdata);

		pol_mem_req        <= cl_ENABLE;
		pol_insn_valid     <= cl_ENABLE;
		pol_is_compressed  <= sl_is_compressed;
		pol_illegal_inst   <= sl_illegal_inst;
		pov_if_addr        <= sv_addr_to_core;
		pol_prefetch_stall <= sl_prefetch_stall;
	end generate;

end architecture;