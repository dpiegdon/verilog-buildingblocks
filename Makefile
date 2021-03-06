
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

simple_spi_slave_tb.test: simple_spi_slave_tb.v simple_spi_slave.v synchronizer.v

%_tb.test: %.v
	verilator +1364-2005ext+v --lint-only -Wall --bbox-unsup $<
	iverilog -Wall -Wno-timescale -o $@ $^

