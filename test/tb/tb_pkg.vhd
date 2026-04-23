library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

package tb_pkg is
    
    constant cb_RVFI_PMEM_ADDR          : boolean := false; -- When set, addresses would be calculated sequenctialy
	constant cb_IRQ_test                : boolean := false;
	constant cb_DEBUG                   : boolean := false;

	constant ci_mem_valid_delay_cycle   : integer := 0;
	constant ci_pmem_access_delay_cycle : integer := 0;

	constant cs_dir_init_file    : string := "../../test/tb/"; -- This path is relative to where the simulator runs.
	                                                           -- change this accordingly or use absolute path.
	constant cs_init_file_format : string := "hex";

	--- tb related declarations ---
	type tav_mem is array (0 to 63) of std_logic_vector(7 downto 0);
	type tav_pmem is array (0 to 511) of std_logic_vector(31 downto 0);

	impure function ifc_init_ram_file(
		s_file_name : in string
	) return tav_pmem;

	function ifc_to_hstring(
		v_hex : in bit_vector
	) return string;

	procedure pr_dump_ram (
		seg3, seg2, seg1, seg0 : in tav_mem
	);

end package;

package body tb_pkg is
	
	impure function ifc_init_ram_file (s_file_name : in string) return tav_pmem is
		file f_mem_file                                : text;
		variable vln_mem_line                          : line;
		variable vtv_mem_content                       : tav_pmem;
		variable vbv_bit_line                          : bit_vector(vtv_mem_content(0)'range);
	begin
		if cs_dir_init_file /= "" then
			file_open(f_mem_file, s_file_name, read_mode);
			for ii in tav_pmem'low to tav_pmem'high loop
				if not endfile(f_mem_file) then
					readline(f_mem_file, vln_mem_line);
					if cs_init_file_format = "bin" then
						read(vln_mem_line, vbv_bit_line);
						vtv_mem_content(ii) := to_stdlogicvector(vbv_bit_line);
					elsif cs_init_file_format = "hex" then
						hread(vln_mem_line, vbv_bit_line);
						vtv_mem_content(ii) := to_stdlogicvector(vbv_bit_line);
					else
						report "***WRONG MEM VALUE***" severity failure;
					end if;
				else
					vtv_mem_content(ii) := X"00000000";
				end if;
			end loop;
		end if;
		return vtv_mem_content;
	end function;

	function ifc_to_hstring (v_hex : in bit_vector) return string is
		variable vln_line              : LINE;
	begin
		hwrite(vln_line, v_hex);
		return vln_line.all;
	end function ifc_to_hstring;

	procedure pr_dump_ram (
		seg3, seg2, seg1, seg0 : in tav_mem
	) is
		file f_mem_file        : text;
		variable vln_mem_line  : line;
		variable vs_hex_string : string(1 to 26);
	begin
		file_open(f_mem_file, cs_dir_init_file & "ram_dump.txt", write_mode);
		write(vln_mem_line, string'("            03  02  01  00"));
		writeline(f_mem_file, vln_mem_line);
		write(vln_mem_line, string'("--------------------------"));
		writeline(f_mem_file, vln_mem_line);
		for ii in tav_mem'low to tav_mem'high loop
			vs_hex_string := ifc_to_hstring(v_hex => to_bitvector(std_logic_vector(to_unsigned(4 * ii, 32)))) & "    " & ifc_to_hstring(to_bitvector(seg3(ii))) & "  " & ifc_to_hstring(to_bitvector(seg2(ii))) & "  " & ifc_to_hstring(to_bitvector(seg1(ii))) & "  " & ifc_to_hstring(to_bitvector(seg0(ii)));
			write(vln_mem_line, vs_hex_string);
			writeline(f_mem_file, vln_mem_line);
		end loop;
		write(vln_mem_line, string'("--------------------------"));
		writeline(f_mem_file, vln_mem_line);
	end procedure;

end package body;