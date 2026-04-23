library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.core_pkg.all;

entity mem_bank is
	generic (
		gi_mem_depth        : integer := 8;
		gi_mem_width        : integer := 8;
		gs_mem_init_file    : string  := "";
		gi_seg_number       : integer := 0
	);
	port (
		pil_clk             : in std_logic;
		pil_mem_wen         : in std_logic;
		piv_mem_addr        : in std_logic_vector(31 downto 0);
		piv_mem_wdata       : in std_logic_vector(gi_mem_width - 1 downto 0);
		pov_mem_rdata       : out std_logic_vector(gi_mem_width - 1 downto 0)
	);
end entity mem_bank;

architecture rtl of mem_bank is

	type tav_mem is array (0 to gi_mem_depth - 1) of std_logic_vector(gi_mem_width - 1 downto 0);

	impure function ifc_init_ram_file return tav_mem is
		file f_mem_file          : text;
		variable vln_mem_line    : line;
		variable vtv_mem_content : tav_mem;
		variable vbv_bit_line    : bit_vector(31 downto 0);
	begin
		if gs_mem_init_file /= "" then
			file_open(f_mem_file, gs_mem_init_file, read_mode);
			for ii in tav_mem'low to tav_mem'high loop
				if not endfile(f_mem_file) then
					readline(f_mem_file, vln_mem_line);
					hread(vln_mem_line, vbv_bit_line);
					if gi_mem_width = 8 then
						vtv_mem_content(ii) := to_stdlogicvector(vbv_bit_line(7 + 8 * gi_seg_number downto 8 * gi_seg_number));
					elsif gi_mem_width = 16 then
						vtv_mem_content(ii) := to_stdlogicvector(vbv_bit_line(15 + 16 * gi_seg_number downto 16 * gi_seg_number));
					else
						vtv_mem_content(ii) := to_stdlogicvector(vbv_bit_line);
					end if;
				end if;
			end loop;
		end if;
		return vtv_mem_content;
	end function;

	signal stav_mem : tav_mem := ifc_init_ram_file;

	signal sv_address_reg : std_logic_vector(piv_mem_addr'length - 1 downto 0);

begin

	proc_ram : process (pil_clk) is
	begin
		if rising_edge(pil_clk) then
			if pil_mem_wen = cl_ENABLE then
				stav_mem(to_integer(unsigned(piv_mem_addr))) <= piv_mem_wdata;
			end if;
			sv_address_reg <= piv_mem_addr;
		end if;
	end process proc_ram;

	pov_mem_rdata <= stav_mem(to_integer(unsigned(sv_address_reg)));

end architecture rtl;