
.PHONY: clean run_tests

TESTBENCHES=$(wildcard *_tb.v)
TESTS=$(TESTBENCHES:%.v=%.test)


%_tb.test: %_tb.v %.v
	@iverilog -o $@ $^

run_tests: $(TESTS)
	@for test in $^; do \
		echo $$test; \
		./$$test; \
	done

clean:
	@-rm -f *_tb.test
	@-rm -f *_tb.vcd

