
.PHONY: test_ram_group, test_ram, test_delay, test_c_mult, test_bfu

# this one is just a smoke test
test_ram_group:
	./do\
		src/memory/ram.vhdl\
		src/memory/ram_group.vhdl\
		test/memory/ram_group_tb.vhdl

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
