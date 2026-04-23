library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mul_unsigned_block is
    port (
        pil_clk : in std_logic;
        pil_rst : in std_logic;
        piv_a   : in std_logic_vector(31 downto 0);
        piv_b   : in std_logic_vector(31 downto 0);
        pov_res : out std_logic_vector(63 downto 0)
    );
end entity;

architecture rtl of mul_unsigned_block is

    type tau_operand_pipe is array(0 to 3) of unsigned(15 downto 0);

    signal stau_a_hi  : tau_operand_pipe;
    signal stau_a_low : tau_operand_pipe;
    signal stau_b_hi  : tau_operand_pipe;
    signal stau_b_low : tau_operand_pipe;

    signal su_p1 : unsigned(33 downto 0); -- '0' & a[15:0]  * '0' & b[15:0]  -> 34 bit (2 sign bit + 32 res)
    signal su_p2 : unsigned(32 downto 0); -- '0' & a[15:0]  * b[31:16]       -> 33 bit (1 sign bit + 32 bit)
    signal su_p3 : unsigned(32 downto 0); -- a[31:16]       * '0' & b[15:0]  -> 33 bit (1 sign bit + 32 bit)
    signal su_p4 : unsigned(31 downto 0); -- a[31:16]       * b[31:16]       -> 32 bit

    signal su_m1 : unsigned(33 downto 0); -- su_p1 + '0' = su_p1
    signal su_m2 : unsigned(32 downto 0); -- su_p2 + su_m1[32:16]
    signal su_m3 : unsigned(32 downto 0); -- su_p3 + su_m2
    signal su_m4 : unsigned(31 downto 0); -- su_p4 + su_m3[32:16]

    signal stau_m1_delay : tau_operand_pipe;
    signal su_m3_delay   : unsigned(15 downto 0);

begin

    proc_unsigned_mul_block : process (pil_clk, pil_rst)
    begin
        if pil_rst = '1' then
            stau_a_hi     <= (others => (others => '0'));
            stau_a_low    <= (others => (others => '0'));
            stau_b_hi     <= (others => (others => '0'));
            stau_b_low    <= (others => (others => '0'));
            su_p1         <= (others => '0');
            su_p2         <= (others => '0');
            su_p3         <= (others => '0');
            su_p4         <= (others => '0');
            su_m1         <= (others => '0');
            su_m2         <= (others => '0');
            su_m3         <= (others => '0');
            su_m4         <= (others => '0');
            stau_m1_delay <= (others => (others => '0'));
            su_m3_delay   <= (others => '0');
        elsif rising_edge(pil_clk) then
            stau_a_hi  <= (0 => unsigned(piv_a(31 downto 16)), 1 => stau_a_hi(0), 2 => stau_a_hi(1), 3 => stau_a_hi(2));
            stau_a_low <= (0 => unsigned(piv_a(15 downto 0)), 1 => stau_a_low(0), 2 => stau_a_low(1), 3 => stau_a_low(2));
            stau_b_hi  <= (0 => unsigned(piv_b(31 downto 16)), 1 => stau_b_hi(0), 2 => stau_b_hi(1), 3 => stau_b_hi(2));
            stau_b_low <= (0 => unsigned(piv_b(15 downto 0)), 1 => stau_b_low(0), 2 => stau_b_low(1), 3 => stau_b_low(2));

            stau_m1_delay <= su_m1(15 downto 0) & stau_m1_delay(0 to stau_m1_delay'length - 2);
            su_m3_delay   <= su_m3(15 downto 0);

            su_p1 <= unsigned('0' & stau_a_low(0)) * unsigned('0' & stau_b_low(0));
            su_p2 <= unsigned('0' & stau_a_low(1)) * stau_b_hi(1);
            su_p3 <= stau_a_hi(2) * unsigned('0' & stau_b_low(2));
            su_p4 <= stau_a_hi(3) * stau_b_hi(3);

            su_m1 <= su_p1;
            su_m2 <= su_p2 + su_m1(32 downto 16);
            su_m3 <= su_p3 + su_m2;
            su_m4 <= su_p4 + su_m3(32 downto 16);
        end if;
    end process;

    pov_res(63 downto 32) <= std_logic_vector(su_m4);
    pov_res(31 downto 16) <= std_logic_vector(su_m3_delay);
    pov_res(15 downto 0)  <= std_logic_vector(stau_m1_delay(2));

end architecture;