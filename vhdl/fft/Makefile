
.PHONY: test_ram, test_delay, test_c_mult, test_bfu

test_ram:
	./do\
		src/memory/ram.vhdl\
		test/memory/ram_tb.vhdl

test_delay:
	./do\
		src/common/delay.vhdl\
		test/common/delay_tb.vhdl

test_c_mult:
	./do\
		src/butterfly_unit/c_mult.vhdl\
		test/butterfly_unit/c_mult_tb.vhdl

test_bfu:
	./do\
		src/common/delay.vhdl\
		src/butterfly_unit/c_mult.vhdl\
		src/butterfly_unit/bfu.vhdl\
		test/butterfly_unit/bfu_tb.vhdl
