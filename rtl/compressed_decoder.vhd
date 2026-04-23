library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.compressed_decoder_pkg.all;

entity compressed_decoder is
    generic (
        gb_RISCV_FORMAL : boolean := false
    );
    port (
        pitr_inst                : in tr_IF_base_format;
        pol_is_compressed        : out std_logic;
        pol_illegal_inst         : out std_logic;
        pov_rvfi_compressed_isnt : out std_logic_vector(31 downto 0);
        potr_inst                : out tr_IF_base_format
    );
end entity;

architecture rtl of compressed_decoder is

    signal sv_inst16 : std_logic_vector(15 downto 0);

    alias av_opcode : std_logic_vector is sv_inst16(ci_CIF_opcode_u downto ci_CIF_opcode_l);
    alias av_funct3 : std_logic_vector is sv_inst16(ci_CIF_funct3_u downto ci_CIF_funct3_l);

    signal sl_is_compressed : std_logic;
    signal sl_decode_err    : std_logic;
    signal sl_illegal_inst  : std_logic;

    signal sv_inst32 : std_logic_vector(31 downto 0);

begin

    sv_inst16 <= fv_inst_32to16(instruction => pitr_inst);

    proc_c_dec : process (sv_inst16, pitr_inst)
    begin
        sv_inst32     <= fv_inst_rec2slv(instruction => pitr_inst);
        sl_decode_err <= cl_DISABLE;

        case av_opcode is
            when cv_COC_C0 =>
                case av_funct3 is
                    when ctr_C0_funct3.v_ADDI4SPN =>
                        --- c.addi4spn : addi rd', x2, nzuimm ---
                        sv_inst32 <= "00" & sv_inst16(10 downto 7) & sv_inst16(12 downto 11) & sv_inst16(5) & sv_inst16(6) & "00" &
                            "00010" & "000" & "01" & sv_inst16(4 downto 2) & cv_IC_I;

                        if sv_inst16(12 downto 5) = "00000000" then
                            sl_decode_err <= cl_ENABLE;
                        end if;
                    when ctr_C0_funct3.v_LW =>
                        --- c.lw : lw rd', imm(rs1') ---
                        sv_inst32 <= "00000" & sv_inst16(5) & sv_inst16(12 downto 10) & sv_inst16(6) & "00" & "01" & sv_inst16(9 downto 7) &
                            "010" & "01" & sv_inst16(4 downto 2) & cv_IC_I_LD;
                    when ctr_C0_funct3.v_SW =>
                        --- c.sw : sw rs2', imm(rs1') ---
                        sv_inst32 <= "00000" & sv_inst16(5) & sv_inst16(12) & "01" & sv_inst16(4 downto 2) & "01" & sv_inst16(9 downto 7) &
                            "010" & sv_inst16(11 downto 10) & sv_inst16(6) & "00" & cv_IC_S;
                    when others =>
                        sl_decode_err <= cl_ENABLE;
                end case;
            when cv_COC_C1 =>
                case av_funct3 is
                    when ctr_C1_funct3.v_ADDI_NOP =>
                        --- c.addi/c.nop : addi rd, rd, imm ---
                        sv_inst32 <= (31 downto 26 => sv_inst16(12)) & sv_inst16(12) & sv_inst16(6 downto 2) & sv_inst16(11 downto 7) & "000" & sv_inst16(11 downto 7) & cv_IC_I;
                    when ctr_C1_funct3.v_JAL | ctr_C1_funct3.v_J =>
                        --- c.jal/c.j : jal x1, imm / jal x0, imm ---
                        sv_inst32 <= sv_inst16(12) & sv_inst16(8) & sv_inst16(10 downto 9) & sv_inst16(6) & sv_inst16(7) & sv_inst16(2) & sv_inst16(11) & sv_inst16(5 downto 3) & (20 downto 12 => sv_inst16(12)) &
                            "0000" & not sv_inst16(15) & cv_IC_J;
                    when ctr_C1_funct3.v_LI =>
                        --- c.li : addi rd, x0, imm ---
                        sv_inst32 <= (31 downto 26 => sv_inst16(12)) & sv_inst16(12) & sv_inst16(6 downto 2) & "00000" & "000" & sv_inst16(11 downto 7) & cv_IC_I;
                    when ctr_C1_funct3.v_LUI_ADDI16SP =>
                        --- c.lui : lui rd, imm ---
                        sv_inst32 <= (31 downto 17 => sv_inst16(12)) & sv_inst16(6 downto 2) & sv_inst16(11 downto 7) & cv_IC_UI;
                        if sv_inst16(11 downto 7) = "00010" then
                            --- c.addi16sp : addi x2, x2, nzimm --- 
                            sv_inst32 <= (31 downto 29 => sv_inst16(12)) & sv_inst16(4 downto 3) & sv_inst16(5) & sv_inst16(2) & sv_inst16(6) & "0000" & "00010" & "000" & "00010" & cv_IC_I;
                        end if;

                        if (sv_inst16(12) & sv_inst16(6 downto 2)) = "000000" then
                            sl_decode_err <= cl_ENABLE;
                        end if;
                    when ctr_C1_funct3.v_CA_type =>
                        case sv_inst16(11 downto 10) is
                            when "00" | "01" =>
                                --- c.srli/c.srai : srli rd, rd, shamt / srai rd, rd, shamt ---
                                sv_inst32 <= '0' & sv_inst16(10) & "00000" & sv_inst16(6 downto 2) & "01" & sv_inst16(9 downto 7) & "101" & "01" & sv_inst16(9 downto 7) & cv_IC_I;

                                if sv_inst16(12) = '1' then
                                    sl_decode_err <= cl_ENABLE;
                                end if;
                            when "10" =>
                                --- c.andi : andi rd, rd, imm ---
                                sv_inst32 <= (31 downto 26 => sv_inst16(12)) & sv_inst16(12) & sv_inst16(6 downto 2) & "01" & sv_inst16(9 downto 7) & "111" & "01" & sv_inst16(9 downto 7) & cv_IC_I;
                            when others                =>
                                case sv_inst16(12) & sv_inst16(6 downto 5) is
                                    when "000" =>
                                        --- c.sub : sub rd', rd', rs2' ---
                                        sv_inst32 <= "01" & "00000" & "01" & sv_inst16(4 downto 2) & "01" & sv_inst16(9 downto 7) & "000" & "01" & sv_inst16(9 downto 7) & cv_IC_R;
                                    when "001" =>
                                        --- c.xor : xor rd', rd', rs2' ---
                                        sv_inst32 <= "0000000" & "01" & sv_inst16(4 downto 2) & "01" & sv_inst16(9 downto 7) & "100" & "01" & sv_inst16(9 downto 7) & cv_IC_R;
                                    when "010" =>
                                        --- c.or : or rd', rd', rs2' ---
                                        sv_inst32 <= "0000000" & "01" & sv_inst16(4 downto 2) & "01" & sv_inst16(9 downto 7) & "110" & "01" & sv_inst16(9 downto 7) & cv_IC_R;
                                    when "011" =>
                                        --- c.and : and rd', rd', rs2' ---
                                        sv_inst32 <= "0000000" & "01" & sv_inst16(4 downto 2) & "01" & sv_inst16(9 downto 7) & "111" & "01" & sv_inst16(9 downto 7) & cv_IC_R;
                                    when others =>
                                        sl_decode_err <= cl_ENABLE;
                                end case;
                        end case;
                    when ctr_C1_funct3.v_BEQZ | ctr_C1_funct3.v_BNEZ =>
                        --- c.beqz/c.bnez : beq rs1', x0, imm / bne rs1', x0, imm ---
                        sv_inst32 <= (31 downto 28 => sv_inst16(12)) & sv_inst16(6 downto 5) & sv_inst16(2) & "00000" & "01" & sv_inst16(9 downto 7) & "00" & sv_inst16(13) &
                            sv_inst16(11 downto 10) & sv_inst16(4 downto 3) & sv_inst16(12) & cv_IC_SB;
                    when others =>
                        sl_decode_err <= cl_ENABLE;
                end case;
            when cv_COC_C2 =>
                case av_funct3 is
                    when ctr_C2_funct3.v_SLLI =>
                        --- c.slli : slli rd, rd, shamt ---
                        sv_inst32 <= (31 downto 25 => '0') & sv_inst16(6 downto 2) & sv_inst16(11 downto 7) & "001" & sv_inst16(11 downto 7) & cv_IC_I;

                        if sv_inst16(12) = '1' then
                            sl_decode_err <= cl_ENABLE;
                        end if;
                    when ctr_C2_funct3.v_LWSP =>
                        --- c.lwsp : lw rd, imm(x2) ---
                        sv_inst32 <= (31 downto 28 => '0') & sv_inst16(3 downto 2) & sv_inst16(12) & sv_inst16(6 downto 4) & "00" & "00010" & "010" & sv_inst16(11 downto 7) & cv_IC_I_LD;

                        if sv_inst16(11 downto 7) = "00000" then
                            sl_decode_err <= cl_ENABLE;
                        end if;
                    when ctr_C2_funct3.v_RR_OP =>
                        if sv_inst16(12) = '0' then
                            if sv_inst16(6 downto 2) /= "00000" then
                                --- c.mv : add rd, x0, rs2 ---
                                sv_inst32 <= (31 downto 25 => '0') & sv_inst16(6 downto 2) & "00000" & "000" & sv_inst16(11 downto 7) & cv_IC_R;
                            else
                                --- c.jr : jalr x0, rs1, 0 ---
                                sv_inst32 <= (31 downto 20 => '0') & sv_inst16(11 downto 7) & "000" & "00000" & cv_IC_I_JALR;
                                if sv_inst16(11 downto 7) = "00000" then
                                    sl_decode_err <= cl_ENABLE;
                                end if;
                            end if;
                        else
                            if sv_inst16(6 downto 2) /= "00000" then
                                --- c.add : add rd, rd, rs2 ---
                                sv_inst32 <= (31 downto 25 => '0') & sv_inst16(6 downto 2) & sv_inst16(11 downto 7) & "000" & sv_inst16(11 downto 7) & cv_IC_R;
                            else
                                if sv_inst16(11 downto 7) = "00000" then
                                    if sv_inst16(6 downto 2) /= "00000" then
                                        sl_decode_err <= cl_ENABLE;
                                    else
                                        --- c.ebreak : ebreak ---
                                        sv_inst32     <= X"00100073";
                                    end if;
                                else
                                    --- c.jalr : jalr x1, rs1, 0 ---
                                    sv_inst32 <= (31 downto 20 => '0') & sv_inst16(11 downto 7) & "000" & "00001" & cv_IC_I_JALR;
                                end if;
                            end if;
                        end if;
                    when ctr_C2_funct3.v_SWSP =>
                        --- c.swsp : sw rs2, imm(x2) ---
                        sv_inst32 <= (31 downto 28 => '0') & sv_inst16(8 downto 7) & sv_inst16(12) & sv_inst16(6 downto 2) & "00010" & "010" & sv_inst16(11 downto 9) & "00" & cv_IC_S;
                    when others                =>
                        --- Invalid ---
                        sl_decode_err <= cl_ENABLE;
                end case;
            when others =>
                sl_decode_err <= cl_ENABLE;
        end case;
    end process proc_c_dec;

    sl_illegal_inst  <= sl_decode_err and sl_is_compressed;
    sl_is_compressed <= cl_DISABLE when sv_inst16(1 downto 0) = "11" else
        cl_ENABLE;

    pol_is_compressed <= sl_is_compressed;
    pol_illegal_inst  <= sl_illegal_inst;

    pov_rvfi_compressed_isnt <= X"0000" & sv_inst16;

    gen_rvfi_inst32 : if gb_RISCV_FORMAL = true generate
        potr_inst <= ctr_IF_base_format_NOP when sl_illegal_inst = cl_ENABLE else ftr_inst_slv2rec(instruction => sv_inst32);
    else gen_regular_inst32 : generate
        potr_inst <= ftr_inst_slv2rec(instruction => sv_inst32);
    end generate;

end architecture;