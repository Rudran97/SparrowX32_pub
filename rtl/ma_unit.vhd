library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity ma_unit is
	port (
		pil_clk          : in std_logic;
		pil_rst          : in std_logic;
		piv_ma_mai_addr  : in std_logic_vector(31 downto 0);
		piv_ma_mai_wdata : in std_logic_vector(31 downto 0);
		pitr_ma_ctrl     : in tr_CS_MA;

		--- interface to the memory module ---
		pil_ma_mem_valid : in std_logic;
		pil_ma_mem_ack   : in std_logic;
		pol_ma_mem_req   : out std_logic;
		pol_ma_mem_wen   : out std_logic;

		piv_ma_mem_rdata    : in std_logic_vector(31 downto 0);
		pov_ma_mem_wdata    : out std_logic_vector(31 downto 0);
		pov_ma_mem_addr     : out std_logic_vector(31 downto 0);
		pov_ma_mem_byte_sel : out std_logic_vector(3 downto 0);

		--- MA stage output ---
		pov_ma_mai_rdata : out std_logic_vector(31 downto 0);
		pol_ma_ready     : out std_logic
	);
end entity;

architecture rtl of ma_unit is

	signal sl_mem_req        : std_logic;
	signal sl_mem_wen        : std_logic;
	signal sv_mem_wdata      : std_logic_vector(31 downto 0);
	signal sv_mem_addr       : std_logic_vector(31 downto 0);
	signal sv_mem_byte_sel   : std_logic_vector(3 downto 0);
	signal sv_mai_rdata      : std_logic_vector(31 downto 0);
	signal sl_mai_valid_data : std_logic;

begin

	inst_mai_module : entity work.mem_access_interface_module
		port map(
			pil_clk            => pil_clk,
			pil_rst            => pil_rst,
			pil_mem_valid      => pil_ma_mem_valid,
			pil_mem_ack        => pil_ma_mem_ack,
			pol_mem_req        => sl_mem_req,
			pol_mem_wen        => sl_mem_wen,
			piv_mem_rdata      => piv_ma_mem_rdata,
			pov_mem_wdata      => sv_mem_wdata,
			pov_mem_addr       => sv_mem_addr,
			pov_mem_byte_sel   => sv_mem_byte_sel,
			pil_mai_req        => pitr_ma_ctrl.l_is_mem_inst,
			pil_mai_wen        => pitr_ma_ctrl.l_RAM_WEN,
			pil_mai_sign       => pitr_ma_ctrl.l_sign_ext,
			piv_mai_data_width => pitr_ma_ctrl.v_data_width_mux,
			piv_mai_addr       => piv_ma_mai_addr,
			piv_mai_wdata      => piv_ma_mai_wdata,
			pov_mai_rdata      => sv_mai_rdata,
			pol_mai_valid_data => sl_mai_valid_data
		);

	pol_ma_mem_req <= sl_mem_req;
	pol_ma_mem_wen <= sl_mem_wen;

	pov_ma_mem_wdata    <= sv_mem_wdata;
	pov_ma_mem_addr     <= sv_mem_addr;
	pov_ma_mem_byte_sel <= sv_mem_byte_sel;

	pov_ma_mai_rdata <= sv_mai_rdata;

	pol_ma_ready <= sl_mai_valid_data when pitr_ma_ctrl.l_is_mem_inst = cl_ENABLE else
		cl_ENABLE;

end architecture;