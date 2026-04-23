FLAGS=--std=08 --ieee=standard -fexplicit -frelaxed --workdir=build/ --warn-unused

architecture = rv32imac

AS = riscv32-unknown-elf-as
LD = riscv32-unknown-elf-ld
OC = riscv32-unknown-elf-objcopy
OD = riscv32-unknown-elf-objdump

PY = python3

create_build:
	mkdir -p build
	cp rtl/*.vhd build/

compile_pkg: create_build
	ghdl -a $(FLAGS) --work=work_rtl build/options_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/core_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/int_mul_div_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/int_alu_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/csr_op_unit_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/compressed_decoder_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/if_id_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/id_exe_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/exe_ma_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/ma_wb_pkg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/clic_pkg.vhd

compile_rtl: compile_pkg
	ghdl -a $(FLAGS) --work=work_rtl build/mul_unsigned_block.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/compressed_decoder.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/controller.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/fetch_interface_module.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/prefetch_buffer.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/if_unit.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/mem_access_interface_module.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/csr_op_unit.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/sys_regiser_file.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/int_mul_div.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/int_alu.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/decoder.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/data_forward_mux_reg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/ma_unit.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/ma_wb_reg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/if_id_reg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/id_unit.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/id_exe_reg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/exe_unit.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/exe_ma_reg.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/int_source_proc.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/int_target_proc.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/clic.vhd
	ghdl -a $(FLAGS) --work=work_rtl build/svx32_core.vhd
	ghdl synth $(FLAGS) --work=work_rtl --out=verilog svx32_core > build/svx32_core.v

compile: test/sw/sw.S
	$(AS) $< -o test/sw/sw.o
	$(LD) -T test/sw/linker.ld -o test/sw/sw.elf test/sw/sw.o
	$(OC) -O binary test/sw/sw.elf test/sw/sw.bin
	$(OC) -O ihex test/sw/sw.elf test/sw/sw.hex
	$(OD) -D test/sw/sw.elf > test/sw/sw.lst
	@$(PY) test/makehex.py test/sw/sw.hex 0x80000000 5000 0x10000000 500

clean:
	rm -rf build/
	rm -f test/sw/sw.bin 
	rm -f test/sw/sw.elf 
	rm -f test/sw/sw.lst 
	rm -f test/sw/sw.o 