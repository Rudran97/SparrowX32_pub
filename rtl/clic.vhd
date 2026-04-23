library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.clic_pkg.all;

entity clic is
    port (
        pil_clk              : in std_logic;
        pil_rst              : in std_logic;
        pitav_int_prio       : in tav_int_prio(0 to 7);
        pitav_int_isr_vector : in tav_int_isr_vector(0 to 7);

        --- external src and clic interface ---
        piv_irq_src          : in std_logic_vector(7 downto 0);
        pov_irq_clr          : out std_logic_vector(7 downto 0); -- clic requests the source to clear the interrupt

        --- Core to CLIC ---
        pil_clic_irq_en      : in std_logic;
        pil_irq_done         : in std_logic;

        --- CLIC to Core ---
        pol_irq              : out std_logic;
        pov_irq_id           : out std_logic_vector(3 downto 0);
        pov_irq_vect         : out std_logic_vector(31 downto 0)
    );
end entity clic;

architecture rtl of clic is

    type t_clic_fsm is (
        idle_st,
        detect_int_st,
        wait_done_st
    );

    signal st_clic_fsm        : t_clic_fsm;

    signal sl_irq             : std_logic;
    signal sv_irq_id          : std_logic_vector(2 downto 0);
    signal sv_irq_vect        : std_logic_vector(31 downto 0);

    signal sv_irq_pen_clr     : std_logic_vector(7 downto 0);

    --- clic internal signals ---
    type tal_int is array (0 to 7) of std_logic;
    signal stal_isp_int_ie    : tal_int;
    signal stal_isp_int_src   : tal_int;
    signal stal_isp_int_done  : tal_int;
    signal stal_isp_int_pen   : tal_int;

    signal sl_itp_prio_sel_en : std_logic;
    signal sv_itp_int_pen     : std_logic_vector(7 downto 0);
    signal sl_itp_irq_pen     : std_logic;
    signal sv_itp_irq_pen_id  : std_logic_vector(2 downto 0);
    signal sv_itp_pen_clr     : std_logic_vector(7 downto 0);
    signal sv_itp_irq_vect    : std_logic_vector(31 downto 0);

begin

    gen_isp_signals : for ii in 0 to 7 generate
		stal_isp_int_ie(ii)   <= pitav_int_prio(ii)(2) or pitav_int_prio(ii)(1) or pitav_int_prio(ii)(0) when sl_itp_prio_sel_en = cl_ENABLE else
            cl_DISABLE;
		stal_isp_int_src(ii)  <= piv_irq_src(ii);
        stal_isp_int_done(ii) <= sv_irq_pen_clr(ii);
	end generate;

    gen_isp_modules : for ii in 0 to 7 generate
        inst_isp_modules : entity work.int_source_proc
            port map (
                pil_clk      => pil_clk,
                pil_rst      => pil_rst,
                pil_int_ie   => stal_isp_int_ie(ii),
                pil_int_src  => stal_isp_int_src(ii),
                pil_int_done => stal_isp_int_done(ii),
                pol_int_pen  => stal_isp_int_pen(ii) 
            );
    end generate;

    gen_itp_pen_signals : for ii in 0 to 7 generate
        sv_itp_int_pen(ii) <= stal_isp_int_pen(ii);
    end generate;
    
    inst_int_target_process : entity work.int_target_proc
        port map (
            pil_clk              => pil_clk,
            pil_rst              => pil_rst,
            pil_prio_sel_en      => sl_itp_prio_sel_en,
            piv_int_pen          => sv_itp_int_pen,
            pitav_int_prio       => pitav_int_prio,
            pitav_int_isr_vector => pitav_int_isr_vector,
            pol_irq              => sl_itp_irq_pen,
            pov_irq_id           => sv_itp_irq_pen_id,
            pov_int_pen_clr      => sv_itp_pen_clr,
            pov_isr_vector       => sv_itp_irq_vect
        );

    proc_clic_fsm : process(pil_clk, pil_rst)
    begin
        if pil_rst = cl_RESET then
            sl_itp_prio_sel_en <= cl_DISABLE;
            sl_irq             <= cl_NOTPENDING;
            sv_irq_id          <= (others => '0');
            sv_irq_vect        <= (others => '0');
            sv_irq_pen_clr     <= (others => '0');
            st_clic_fsm        <= idle_st;
        elsif rising_edge(pil_clk) then
            case st_clic_fsm is
                when idle_st       =>
                    sl_itp_prio_sel_en     <= cl_DISABLE;
                    sl_irq                 <= cl_NOTPENDING;
                    sv_irq_id              <= (others => '0');
                    sv_irq_vect            <= (others => '0');
                    sv_irq_pen_clr         <= (others => '0');

                    if pil_clic_irq_en = cl_ENABLE then
                        sl_itp_prio_sel_en <= cl_ENABLE;
                        st_clic_fsm        <= detect_int_st;
                    end if;
                when detect_int_st =>
                    if pil_clic_irq_en = cl_ENABLE then
                        if sl_itp_irq_pen = cl_PENDING then
                            sl_irq         <= sl_itp_irq_pen;
                            sv_irq_id      <= sv_itp_irq_pen_id;
                            sv_irq_vect    <= sv_itp_irq_vect;
                            sv_irq_pen_clr <= sv_itp_pen_clr;
                            st_clic_fsm    <= wait_done_st;
                        end if;
                    else
                        sl_itp_prio_sel_en <= cl_DISABLE;
                        st_clic_fsm        <= idle_st;
                    end if;
                when wait_done_st  =>
                    if pil_irq_done = cl_ENABLE then
                        sl_irq             <= cl_NOTPENDING;
                        sv_irq_pen_clr     <= (others => '0');
                        st_clic_fsm        <= detect_int_st;
                    end if;
            end case;
        end if;
    end process proc_clic_fsm;

    pol_irq      <= sl_irq;
    pov_irq_id   <= '0' & sv_irq_id;
    pov_irq_vect <= sv_irq_vect;
    pov_irq_clr  <= sv_irq_pen_clr;

end architecture;