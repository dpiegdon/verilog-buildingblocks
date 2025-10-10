/*
This file is part of verilog-buildingblocks,
by David R. Piegdon <dgit@piegdon.de>

verilog-buildingblocks is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

verilog-buildingblocks is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with verilog-buildingblocks.  If not, see <https://www.gnu.org/licenses/>.
*/

`default_nettype none
`timescale 1ns / 1ps

module io_mux_specific_tb(output reg finished, output reg [15:0] errors);
	parameter TXCOUNT = 1;
	parameter RXCOUNT = 1;

	localparam FCOUNT = RXCOUNT+TXCOUNT;
	localparam FWIDTH = $clog2(FCOUNT);

	reg [FWIDTH-1+1:0] func_select;
	reg [TXCOUNT-1+1:0] func_transmit;
	reg [1:0] pin_in = 0;
	wire [RXCOUNT-1:0] func_receive;
	wire pin_ena, pin_out;

	io_mux #(.RXCOUNT(RXCOUNT), .TXCOUNT(TXCOUNT))
		mux(pin_ena, pin_out, pin_in[0],
		    func_select[FWIDTH-1:0], func_transmit[TXCOUNT-1:0], func_receive[RXCOUNT-1:0]);

	integer value;
	integer func;

	initial begin
		errors = 0;
		finished = 0;

		// test all input functions
		for (func_select = 0; func_select < RXCOUNT; func_select=func_select+1) begin
			// check all combinations for output function values
			for (func_transmit = 0; func_transmit <= 2**TXCOUNT; func_transmit = func_transmit+1) begin
				// and all possible input values of pin
				for (pin_in = 0; pin_in <= 1; pin_in = pin_in+1) begin
					#1;
					// check that physical output does not get enables
					if (pin_ena !== 0) begin
						$error("TX%0d/RX%0d for func_select=%0d (in) func_transmit=%0d pin_in=%0d: func_receive=%0d pin_ena=%0d pin_out=%0d",
							TXCOUNT, RXCOUNT, func_select, func_transmit, pin_in, func_receive, pin_ena, pin_out);
						$error("  => pin_ena for input function %0d", func_select);
						errors = errors + 1;
					end
					// and that physical output value is never set to high
					if (pin_out !== 0) begin
						$error("TX%0d/RX%0d for func_select=%0d (in) func_transmit=%0d pin_in=%0d: func_receive=%0d pin_ena=%0d pin_out=%0d",
							TXCOUNT, RXCOUNT, func_select, func_transmit, pin_in, func_receive, pin_ena, pin_out);
						$error("  => pin_out for input function %0d", func_select);
						errors = errors + 1;
					end
					// and that physical input value correlates to selected input function, and no other function input function
					if ((int'(pin_in[0]) << func_select) !== func_receive) begin
						$error("TX%0d/RX%0d for func_select=%0d (in) func_transmit=%0d pin_in=%0d: func_receive=%0d pin_ena=%0d pin_out=%0d",
							TXCOUNT, RXCOUNT, func_select, func_transmit, pin_in, func_receive, pin_ena, pin_out);
						$error("  => bad func_receive 0x%x for input function %0d input %0d", func_receive, func_select, pin_in);
						errors = errors + 1;
					end
				end
			end
		end

		// test all output functions
		for(func_select = RXCOUNT; func_select < FCOUNT; func_select=func_select+1) begin
			// check all combinations for output function values
			for (func_transmit = 0; func_transmit <= 2**TXCOUNT; func_transmit = func_transmit+1) begin
				// and all possible input values of pin
				for(pin_in = 0; pin_in <= 1; pin_in = pin_in+1) begin
					#1;
					// check that physical output actually is enabled
					if (pin_ena !== 1) begin
						$error("TX%0d/RX%0d for func_select=%0d (out) func_transmit=%0d pin_in=%0d: func_receive=%0d pin_ena=%0d pin_out=%0d",
							TXCOUNT, RXCOUNT, func_select, func_transmit, pin_in, func_receive, pin_ena, pin_out);
						$error("  => pin_ena NOT for output function %0d", func_select);
						errors = errors + 1;
					end
					// and that physical output value correlates to selected output value
					if ((int'(pin_out) << func_select-RXCOUNT) !== ((int'(pin_out) << func_select-RXCOUNT) & func_transmit)) begin
						$error("TX%0d/RX%0d for func_select=%0d (out) func_transmit=%0d pin_in=%0d: func_receive=%0d pin_ena=%0d pin_out=%0d",
							TXCOUNT, RXCOUNT, func_select, func_transmit, pin_in, func_receive, pin_ena, pin_out);
						$error("  => bad pin_out %0d for output function %0d func_transmit 0x%x", pin_out, func_select, func_transmit);
						errors = errors + 1;
					end
					// and that nothing is received in output mode
					if (func_receive !== 0) begin
						$error("TX%0d/RX%0d for func_select=%0d (out) func_transmit=%0d pin_in=%0d: func_receive=%0d pin_ena=%0d pin_out=%0d",
							TXCOUNT, RXCOUNT, func_select, func_transmit, pin_in, func_receive, pin_ena, pin_out);
						$error("  => bad func_receive 0x%x for output function %0d input %0d", func_receive, func_select, pin_in);
						errors = errors + 1;
					end
				end
			end
		end

		finished = 1;
	end
endmodule

module io_mux_tb();
	integer errors = 0;

	localparam SUBTESTS = 25;
	wire [SUBTESTS-1:0] subtest_finished;
	wire [15:0] subtest_errors[SUBTESTS-1:0];

	io_mux_specific_tb #(.TXCOUNT(1), .RXCOUNT(1)) subtest11(subtest_finished[ 0], subtest_errors[ 0]);
	io_mux_specific_tb #(.TXCOUNT(1), .RXCOUNT(2)) subtest12(subtest_finished[ 1], subtest_errors[ 1]);
	io_mux_specific_tb #(.TXCOUNT(1), .RXCOUNT(3)) subtest13(subtest_finished[ 2], subtest_errors[ 2]);
	io_mux_specific_tb #(.TXCOUNT(1), .RXCOUNT(4)) subtest14(subtest_finished[ 3], subtest_errors[ 3]);
	io_mux_specific_tb #(.TXCOUNT(1), .RXCOUNT(5)) subtest15(subtest_finished[ 4], subtest_errors[ 4]);
	io_mux_specific_tb #(.TXCOUNT(2), .RXCOUNT(1)) subtest21(subtest_finished[ 5], subtest_errors[ 5]);
	io_mux_specific_tb #(.TXCOUNT(2), .RXCOUNT(2)) subtest22(subtest_finished[ 6], subtest_errors[ 6]);
	io_mux_specific_tb #(.TXCOUNT(2), .RXCOUNT(3)) subtest23(subtest_finished[ 7], subtest_errors[ 7]);
	io_mux_specific_tb #(.TXCOUNT(2), .RXCOUNT(4)) subtest24(subtest_finished[ 8], subtest_errors[ 8]);
	io_mux_specific_tb #(.TXCOUNT(2), .RXCOUNT(5)) subtest25(subtest_finished[ 9], subtest_errors[ 9]);
	io_mux_specific_tb #(.TXCOUNT(3), .RXCOUNT(1)) subtest31(subtest_finished[10], subtest_errors[10]);
	io_mux_specific_tb #(.TXCOUNT(3), .RXCOUNT(2)) subtest32(subtest_finished[11], subtest_errors[11]);
	io_mux_specific_tb #(.TXCOUNT(3), .RXCOUNT(3)) subtest33(subtest_finished[12], subtest_errors[12]);
	io_mux_specific_tb #(.TXCOUNT(3), .RXCOUNT(4)) subtest34(subtest_finished[13], subtest_errors[13]);
	io_mux_specific_tb #(.TXCOUNT(3), .RXCOUNT(5)) subtest35(subtest_finished[14], subtest_errors[14]);
	io_mux_specific_tb #(.TXCOUNT(4), .RXCOUNT(1)) subtest41(subtest_finished[15], subtest_errors[15]);
	io_mux_specific_tb #(.TXCOUNT(4), .RXCOUNT(2)) subtest42(subtest_finished[16], subtest_errors[16]);
	io_mux_specific_tb #(.TXCOUNT(4), .RXCOUNT(3)) subtest43(subtest_finished[17], subtest_errors[17]);
	io_mux_specific_tb #(.TXCOUNT(4), .RXCOUNT(4)) subtest44(subtest_finished[18], subtest_errors[18]);
	io_mux_specific_tb #(.TXCOUNT(4), .RXCOUNT(5)) subtest45(subtest_finished[19], subtest_errors[19]);
	io_mux_specific_tb #(.TXCOUNT(5), .RXCOUNT(1)) subtest51(subtest_finished[20], subtest_errors[20]);
	io_mux_specific_tb #(.TXCOUNT(5), .RXCOUNT(2)) subtest52(subtest_finished[21], subtest_errors[21]);
	io_mux_specific_tb #(.TXCOUNT(5), .RXCOUNT(3)) subtest53(subtest_finished[22], subtest_errors[22]);
	io_mux_specific_tb #(.TXCOUNT(5), .RXCOUNT(4)) subtest54(subtest_finished[23], subtest_errors[23]);
	io_mux_specific_tb #(.TXCOUNT(5), .RXCOUNT(5)) subtest55(subtest_finished[24], subtest_errors[24]);

	wire finished = &(subtest_finished);
	integer i;

	initial begin
		/*
		$dumpfile("io_mux_tb.vcd");
		$dumpvars;
		*/


		#1;

		wait(finished);

		#10;

		for (i = 0; i < SUBTESTS; ++i) begin
			errors = errors + int'(subtest_errors[i]);
		end

		if(errors != 0) begin
			$error("FAIL: collected %d errors", errors);
			$fatal();
		end else begin
			$finish();
		end
	end

endmodule
