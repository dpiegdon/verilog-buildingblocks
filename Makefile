
.PHONY: clean run_tests

TESTBENCHES=$(wildcard *_tb.v)
TESTS=$(TESTBENCHES:%.v=%.test)


run_tests: $(TESTS)
	@for test in $^; do \
		echo $$test; \
		./$$test; \
	done

clean:
	@-rm -f *_tb.test
	@-rm -f *_tb.vcd

%_tb.test: %_tb.v
	verilator -DTESTBENCH --top-module $(patsubst %_tb.test,%,$@) +1800-2012ext+v --lint-only -Wall -Wno-PROCASSINIT --bbox-unsup $(patsubst %_tb.test,%.v,$@)
	iverilog  -DTESTBENCH -g2012 -Wall -Wno-timescale -o $@ $^
