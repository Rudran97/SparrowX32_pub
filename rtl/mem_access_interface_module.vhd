library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity mem_access_interface_module is
	port (
		pil_clk : in std_logic;
		pil_rst : in std_logic;

		--- interface to the memory module ---
		pil_mem_valid : in std_logic;
		pil_mem_ack   : in std_logic;
		pol_mem_req   : out std_logic;
		pol_mem_wen   : out std_logic;

		piv_mem_rdata    : in std_logic_vector(31 downto 0);
		pov_mem_wdata    : out std_logic_vector(31 downto 0);
		pov_mem_addr     : out std_logic_vector(31 downto 0);
		pov_mem_byte_sel : out std_logic_vector(3 downto 0);

		--- signals coming from exe_ma stage ---
		pil_mai_req        : in std_logic;
		pil_mai_wen        : in std_logic;
		pil_mai_sign       : in std_logic;
		piv_mai_data_width : in std_logic_vector(1 downto 0);

		piv_mai_addr  : in std_logic_vector(31 downto 0);
		piv_mai_wdata : in std_logic_vector(31 downto 0);
		pov_mai_rdata : out std_logic_vector(31 downto 0);

		pol_mai_valid_data : out std_logic
	);
end entity;

architecture rtl of mem_access_interface_module is

	constant cv_data_width_byte : std_logic_vector(1 downto 0) := "00";
	constant cv_data_width_half : std_logic_vector(1 downto 0) := "01";
	constant cv_data_width_word : std_logic_vector(1 downto 0) := "10";

	constant cv_base_seg0 : std_logic_vector(1 downto 0) := "00";
	constant cv_base_seg1 : std_logic_vector(1 downto 0) := "01";
	constant cv_base_seg2 : std_logic_vector(1 downto 0) := "10";

	--- signals declared for mem interface ---
	type t_mai_state is (idle_st, mem_ack_st, mem_valid_st, delay_st);
	signal st_mai_state : t_mai_state;

	signal sl_mem_req : std_logic;

	--- registers to store data / signals from exe_ma stage ---
	signal sv_mem_seg_en   : std_logic_vector(3 downto 0);
	signal sv_wdata_to_mem : std_logic_vector(31 downto 0);

	signal sl_mai_valid_data : std_logic;

	--- signals sync with mem_ack signal to read data - part of the valid read data procedure ---
	signal sv_rdata_from_mem : std_logic_vector(31 downto 0);

	alias av_mem_seg_sel : std_logic_vector(1 downto 0) is piv_mai_addr(1 downto 0);

begin

	proc_seg_en : process (piv_mai_addr, piv_mai_data_width)
	begin
		sv_mem_seg_en <= "0000";
		case piv_mai_data_width is
			when cv_data_width_byte =>
				case av_mem_seg_sel is
					when cv_base_seg0 =>
						sv_mem_seg_en <= "0001";
					when cv_base_seg1 =>
						sv_mem_seg_en <= "0010";
					when cv_base_seg2 =>
						sv_mem_seg_en <= "0100";
					when others =>
						sv_mem_seg_en <= "1000";
				end case;
			when cv_data_width_half =>
				case av_mem_seg_sel is
					when cv_base_seg0 =>
						sv_mem_seg_en <= "0011";
					when cv_base_seg1 =>
						sv_mem_seg_en <= "0110";
					when cv_base_seg2 =>
						sv_mem_seg_en <= "1100";
					when others =>
						sv_mem_seg_en <= "1001";
				end case;
			when cv_data_width_word =>
				sv_mem_seg_en <= "1111";
			when others =>
		end case;
	end process proc_seg_en;

	proc_wdata_to_mem_align : process (piv_mai_addr, piv_mai_wdata)
	begin
		--- alignment of the wdata is independent of the data width. It only depends on the mem_seg ---
		case av_mem_seg_sel is
			when cv_base_seg0 =>
				sv_wdata_to_mem <= piv_mai_wdata;
			when cv_base_seg1 =>
				sv_wdata_to_mem <= piv_mai_wdata(23 downto 0) & piv_mai_wdata(31 downto 24);
			when cv_base_seg2 =>
				sv_wdata_to_mem <= piv_mai_wdata(15 downto 0) & piv_mai_wdata(31 downto 16);
			when others =>
				sv_wdata_to_mem <= piv_mai_wdata(7 downto 0) & piv_mai_wdata(31 downto 8);
		end case;
	end process proc_wdata_to_mem_align;

	proc_rdata_from_mem_align_sign_ext : process (piv_mai_addr, piv_mem_rdata, piv_mai_data_width, pil_mai_sign)
	begin
		--- rdata must be aligned and sign extended as needed. Since the addr is not aligned, we have to
		--- align the rdata instead. 
		--- NOTE: The address alignment will be done in the memory unit.
		case av_mem_seg_sel is
			when cv_base_seg0                                    =>
				sv_rdata_from_mem <= fv_gen_mem_data_signedness(data => piv_mem_rdata,
					data_width                                           => piv_mai_data_width,
					signedness                                           => pil_mai_sign);
			when cv_base_seg1                                    =>
				sv_rdata_from_mem <= fv_gen_mem_data_signedness(data => piv_mem_rdata(7 downto 0) & piv_mem_rdata(31 downto 8),
					data_width                                           => piv_mai_data_width,
					signedness                                           => pil_mai_sign);
			when cv_base_seg2                                    =>
				sv_rdata_from_mem <= fv_gen_mem_data_signedness(data => piv_mem_rdata(15 downto 0) & piv_mem_rdata(31 downto 16),
					data_width                                           => piv_mai_data_width,
					signedness                                           => pil_mai_sign);
			when others                                          =>
				sv_rdata_from_mem <= fv_gen_mem_data_signedness(data => piv_mem_rdata(23 downto 0) & piv_mem_rdata(31 downto 24),
					data_width                                           => piv_mai_data_width,
					signedness                                           => pil_mai_sign);
		end case;
	end process proc_rdata_from_mem_align_sign_ext;

	proc_mai_fsm : process (pil_clk, pil_rst)
	begin
		if pil_rst = cl_RESET then
			st_mai_state      <= idle_st;
			sl_mem_req        <= cl_DISABLE;
			sl_mai_valid_data <= cl_DISABLE;
		elsif rising_edge(pil_clk) then
			case st_mai_state is
				when idle_st =>
					sl_mem_req        <= pil_mai_req;
					sl_mai_valid_data <= cl_DISABLE;
					if pil_mai_req = cl_ENABLE then
						st_mai_state <= mem_ack_st;
					end if;
				when mem_ack_st =>
						if pil_mem_ack = cl_ENABLE then
							sl_mem_req   <= cl_DISABLE;
							st_mai_state <= mem_valid_st;
						end if;
				when mem_valid_st =>
					if pil_mem_valid = cl_ENABLE then
						sl_mai_valid_data <= cl_ENABLE;
						st_mai_state      <= delay_st;
					end if;
				when delay_st =>
					sl_mai_valid_data <= cl_DISABLE;
					st_mai_state      <= idle_st;
			end case;
		end if;
	end process proc_mai_fsm;

	pol_mem_wen      <= pil_mai_wen;
	pol_mem_req      <= sl_mem_req;
	pov_mem_byte_sel <= sv_mem_seg_en;
	pov_mem_addr     <= piv_mai_addr;
	pov_mem_wdata    <= sv_wdata_to_mem;

	pov_mai_rdata <= sv_rdata_from_mem;

	pol_mai_valid_data <= sl_mai_valid_data;

end architecture;