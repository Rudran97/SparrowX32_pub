library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.clic_pkg.all;

entity int_source_proc is
	port(
		pil_clk      : in  std_logic;
		pil_rst      : in  std_logic;
		pil_int_ie   : in  std_logic; -- local interrupt enable
		pil_int_src  : in  std_logic;
		pil_int_done : in  std_logic;
		pol_int_pen  : out std_logic
	);
end entity int_source_proc;

architecture rtl of int_source_proc is
	
	signal sl_int_pen : std_logic;

begin
	
	proc_int_handler : process (pil_clk, pil_rst) is
	begin
		if pil_rst = cl_RESET then
			sl_int_pen <= cl_NOTPENDING;
		elsif rising_edge(pil_clk) then
			if pil_int_ie = cl_ENABLE then
				if pil_int_src = cl_ENABLE then
					sl_int_pen <= cl_PENDING;
				end if;
				
				if pil_int_done = cl_ENABLE then
					sl_int_pen <= cl_NOTPENDING;
				end if;
			else
				sl_int_pen <= cl_NOTPENDING;
			end if;
		end if;
	end process proc_int_handler;
	
	pol_int_pen <= sl_int_pen;
	
end architecture rtl;
