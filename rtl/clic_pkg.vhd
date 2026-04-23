library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

package clic_pkg is

    constant cl_PENDING    : std_logic := cl_ENABLE;
    constant cl_NOTPENDING : std_logic := cl_DISABLE;

    type tav_int_prio is array (integer range <>) of std_logic_vector(2 downto 0); -- 2..0 -> priority (priority 0 disables local interrupt)
    type tav_int_isr_vector is array (integer range <>) of std_logic_vector(31 downto 0); -- isr vector location address

end package;