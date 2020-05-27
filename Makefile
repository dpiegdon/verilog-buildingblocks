
.PHONY: clean run_tests

TESTBENCHES=$(wildcard *_tb.v)
TESTS=$(TESTBENCHES:%.v=%.test)


%_tb.test: %_tb.v %.v
	@verilator +1364-2005ext+v --lint-only -Wall --bbox-unsup $(patsubst %_tb.test,%.v,$@)
	@iverilog -Wall -Wno-timescale -o $@ $^

run_tests: $(TESTS)
	@for test in $^; do \
		echo $$test; \
		./$$test; \
	done

clean:
	@-rm -f *_tb.test
	@-rm -f *_tb.vcd

