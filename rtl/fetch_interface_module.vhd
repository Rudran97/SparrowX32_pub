library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.options_pkg.all;

entity fetch_interface_module is
	port (
		pil_clk            : in std_logic;
		pil_rst            : in std_logic;

        pil_pipe_ready     : in std_logic;

		--- interface to the memory module ---
		pil_mem_valid      : in std_logic;
		pil_mem_ack        : in std_logic;
		pol_mem_req        : out std_logic;

		piv_mem_rdata      : in std_logic_vector(31 downto 0);
		pov_mem_addr       : out std_logic_vector(31 downto 0);

		--- signals coming from core ---
        pil_fetch_en       : in std_logic; -- fetch will be only carried out when the signal is '1'
		pil_fetch_req      : in std_logic; -- regular fetch req could be both next addr fetch or branch
        pil_bfetch_req     : in std_logic; -- fetch req issued by controller due to branch

		piv_fetch_addr     : in std_logic_vector(31 downto 0);
        piv_bfetch_addr    : in std_logic_vector(31 downto 0);
		pov_fetch_rdata    : out std_logic_vector(31 downto 0);

		pol_fetch_valid    : out std_logic
	);
end entity;

architecture rtl of fetch_interface_module is

	--- signals declared for mem interface ---
	type t_fim_fsm is (idle_st, mem_req_deassert_st, mem_ack_st, mem_valid_st);
	signal st_fim_fsm : t_fim_fsm;

	signal sl_mem_req             : std_logic;
	signal sl_fetch_valid         : std_logic;
    signal sv_fetch_addr          : std_logic_vector(31 downto 0);
    signal sl_refetch             : std_logic;

begin

    proc_fim_fsm : process (pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            st_fim_fsm             <= idle_st;
            sl_mem_req             <= cl_DISABLE;
            sl_fetch_valid         <= cl_DISABLE;
            sl_refetch             <= cl_DISABLE;
            sv_fetch_addr          <= (others => '0');
        elsif rising_edge(pil_clk) then
            case st_fim_fsm is
                when idle_st =>
                    if pil_pipe_ready = cl_ENABLE then
                        --- only disable the valid signal once the id_exe/exe_ma stage is ready ---
                        sl_fetch_valid <= cl_DISABLE;
                    end if;

                    sl_mem_req     <= cl_DISABLE;

                    if pil_fetch_en = cl_ENABLE then
                        if pil_fetch_req = cl_ENABLE or sl_refetch = cl_ENABLE then
                            sl_refetch     <= cl_DISABLE;
                            sl_fetch_valid <= cl_DISABLE;
                            st_fim_fsm     <= mem_req_deassert_st;
                        end if;
                    end if;
                when mem_req_deassert_st =>
                    --- wait till the req signal is deasserted ---
                    sl_mem_req         <= cl_ENABLE;

                    if pil_bfetch_req = cl_ENABLE then
                        --- if the core request a fetch due to branch then fetch the branch addr ---
                        sv_fetch_addr  <= piv_bfetch_addr;
                    else
                        sv_fetch_addr  <= piv_fetch_addr;
                    end if;

                    if pil_fetch_req = cl_DISABLE then
                        st_fim_fsm <= mem_ack_st;
                    end if;
                when mem_ack_st =>
                    if pil_bfetch_req = cl_ENABLE then
                        --- fetch req issued by core due to branch ---
                        sl_refetch <= cl_ENABLE;
                    end if;

                    if pil_mem_ack = cl_ENABLE then
                        -- sl_mem_req <= cl_DISABLE;
                        st_fim_fsm <= mem_valid_st;
                    end if;
                when mem_valid_st =>
                    if pil_mem_valid = cl_ENABLE then
                        sl_mem_req <= cl_DISABLE;
                        if sl_refetch = cl_DISABLE and pil_bfetch_req = cl_DISABLE then
                            --- only enable valid signal if the core has not issued a refetch.
                            --  incase of a refetch the current data is invalid ---
                            sl_fetch_valid <= cl_ENABLE;
                        else
                            sl_refetch     <= cl_ENABLE;
                        end if;

                        st_fim_fsm     <= idle_st;
                    end if;
            end case;
        end if;
    end process proc_fim_fsm;

    pol_mem_req     <= sl_mem_req;
    pov_mem_addr    <= sv_fetch_addr;
    pov_fetch_rdata <= piv_mem_rdata;
    pol_fetch_valid <= sl_fetch_valid;

end architecture;