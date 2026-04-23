library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity prefetch_buffer is
    generic (
        gv_PC_ORIGIN         : std_logic_vector(31 downto 0) := X"0000_0000"
    );
    port (
        pil_clk              : in std_logic;
        pil_rst              : in std_logic;

        pil_first_fetch      : in std_logic;
        pil_pipe_ready       : in std_logic;
        pil_fetch_next       : in std_logic;
        pil_if_ben           : in std_logic;
        piv_if_baddr         : in std_logic_vector(31 downto 0);
        pil_is_compressed    : in std_logic;

        pov_fetch_rdata      : out std_logic_vector(31 downto 0);
        pol_fetch_valid      : out std_logic;

        piv_mem_rdata        : in std_logic_vector(31 downto 0);
        pov_mem_addr         : out std_logic_vector(31 downto 0);

        pov_addr_to_core     : out std_logic_vector(31 downto 0)
    );
end entity prefetch_buffer;

architecture rtl of prefetch_buffer is

	signal su_prg_head        : unsigned(32 downto 0); --- points to the next address to prefetch
	signal su_prg_head_next   : unsigned(32 downto 0); --- points to the prefetch + 1 addr. Sometimes points to the
                                                       --- next intruction to prefetch if the current instruction is
                                                       --- a compressed instruction.

    signal sl_valid           : std_logic;
    signal sv_addr_to_core    : std_logic_vector(31 downto 0);

    signal sl_valid_sample    : std_logic;

begin

    proc_next_pc : process (pil_if_ben, pil_fetch_next, pil_is_compressed, piv_if_baddr, su_prg_head, sv_addr_to_core)
    begin
        if pil_if_ben = cl_ENABLE then
            su_prg_head_next     <= unsigned('0' & piv_if_baddr);
        else
            --- Due to the 1 cycle delay, if the last instruction sent to the core i.e.
            --- instruction at sv_addr_to_core was a compressed instruction, then recalculate
            --- the next address to fetch
            if pil_is_compressed = cl_ENABLE and pil_fetch_next = cl_ENABLE then
                -- su_prg_head_next <= su_prg_head + 2;
                su_prg_head_next <= unsigned('0' & sv_addr_to_core) + 2;
            else
                su_prg_head_next <= su_prg_head + 4;
            end if;
        end if;
    end process proc_next_pc;

    --- If the first instrution is a compressed instruction, then delay the sampling for a clock cycle or else the
    --- IF stage would not register the instruction on time.
    sl_valid_sample <= cl_DISABLE when pil_first_fetch = cl_ENABLE and pil_is_compressed = cl_ENABLE else
        cl_ENABLE;

	proc_prg_head : process (pil_clk, pil_rst)
	begin
		if pil_rst = cl_ENABLE then
			su_prg_head             <= '0' & unsigned(gv_PC_ORIGIN);
            sl_valid                <= cl_DISABLE;
            sv_addr_to_core         <= gv_PC_ORIGIN;
		elsif rising_edge(pil_clk) then
            sl_valid                <= cl_DISABLE;

			if (pil_if_ben = cl_ENABLE or pil_fetch_next = cl_ENABLE) and sl_valid_sample = cl_ENABLE then
                sl_valid            <= cl_ENABLE;

                --- During a branch, the program header must point to the address after the branch address
                --- so that the next instruction in line can be prefetched. However, the addr_to_core must
                --- still point to the address of the branch instruction.
                if pil_if_ben = cl_ENABLE then
                    su_prg_head     <= su_prg_head_next + 4;
                    sv_addr_to_core <= piv_if_baddr;
                else
                    --- If the current instruction (last instruction that was prefetched) is a compressed
                    --- instruction, then the su_prg_head must point to the address after the prg_head_next
                    --- since su_prg_head_next (i.e. current addr + 2) has already been prefetched.
                    if pil_is_compressed = cl_ENABLE then
                        su_prg_head     <= su_prg_head_next + 4;
                        sv_addr_to_core <= std_logic_vector(su_prg_head_next(31 downto 0));
                    else
                        su_prg_head     <= su_prg_head_next;
                        sv_addr_to_core <= std_logic_vector(su_prg_head(31 downto 0));
                    end if;
                end if;

				if su_prg_head > X"FFFF_FFFF" then
					su_prg_head(32) <= '0';
				end if;
			end if;
		end if;
	end process proc_prg_head;

    pov_fetch_rdata    <= piv_mem_rdata;
    pol_fetch_valid    <= sl_valid;

    --- During a branch, fetch the instruction at the branched address ---
    pov_mem_addr       <= piv_if_baddr when pil_if_ben = cl_ENABLE else
        sv_addr_to_core when pil_pipe_ready = cl_DISABLE else
        std_logic_vector(su_prg_head_next(31 downto 0)) when pil_is_compressed = cl_ENABLE and pil_fetch_next = cl_ENABLE else
        std_logic_vector(su_prg_head(31 downto 0));

    pov_addr_to_core   <= sv_addr_to_core;

end architecture;