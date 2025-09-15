
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

simple_spi_slave_tb.test: simple_spi_slave.v simple_spi_slave_tb.v synchronizer.v

simple_spi_master_tb.test: simple_spi_master.v simple_spi_master_tb.v synchronizer.v

spongent_hash_tb.test: spongent_hash.v spongent_hash_tb.v lfsr.v

randomized_spongent_tb.test: randomized_spongent.v randomized_spongent_tb.v spongent_hash.v lfsr.v

%_tb.test: %.v %_tb.v
	verilator -DTESTBENCH --top-module $(patsubst %_tb.test,%,$@) +1800-2012ext+v --lint-only -Wall --bbox-unsup $(patsubst %_tb.test,%.v,$@)
	iverilog  -DTESTBENCH -g2012 -Wall -Wno-timescale -o $@ $^
