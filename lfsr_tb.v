/*
This file is part of verilog-buildingblocks,
by David R. Piegdon <dgit@piegdon.de>

verilog-buildingblocks is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

verilog-buildingblocks is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with verilog-buildingblocks.  If not, see <https://www.gnu.org/licenses/>.
*/

`default_nettype none
`timescale 1ns / 1ps

// testbench for lfsr.
module lfsr_tb();
	localparam ITERATIONS=1001;

	reg [20:0] clock_counter;
	wire clk;
	wire [20:0] iteration;
	always #1 clock_counter = clock_counter+1;
	assign clk = clock_counter[0];
	assign iteration = {1'b0, clock_counter[20:1]};

	reg random;
	wire [15:0] shiftreg;
	reg rst;
	integer errors;
	integer i;
	reg [15:0] known_good;
	reg [15:0] old;
	reg feedback;
	lfsr dut(clk, random, shiftreg, rst);

	reg [15:0] whitelist [0:ITERATIONS-1];


	initial begin
		errors = 0;

		// generate whitelist against which we compare.
		whitelist[1] = 16'hACE1;
		for(i=2; i<ITERATIONS; i=i+1) begin
			old = whitelist[i-1];
			feedback = old[0] ^ old[2] ^ old[3] ^ old[5];
			whitelist[i] = { feedback, old[15:1] };
		end

		if(whitelist[1000] != 16'hf973) begin
			$error("TEST is broken:");
			$error(" known-good value for iteration 1000 is 0xf973,");
			$error(" but test-calc did yield: 0x%04x", whitelist[1000]);
			errors = errors+1;
		end


		// reset DUT
		clock_counter = 0;
		random = 0;
		rst = 1;
		@(negedge clk);
		rst = 0;
		@(negedge clk);

		// check first thousand or so values
		while(iteration < ITERATIONS) begin
			if (whitelist[iteration] == shiftreg) begin
				// nothing.
			end else begin
				$error("iteration %d: output 0x%04x != 0x%04x expected",
					iteration, shiftreg, whitelist[iteration]);
				errors = errors+1;
			end
			@(negedge clk);
		end

		// make sure there were iterations
		if(iteration < ITERATIONS) begin
			$error("TEST is broken: next iteration would only be %d.", iteration);
		end

		while(shiftreg == 16'b1010_1100_1110_0001) begin
			$error("stall rquired: 0x%04x", shiftreg);
			errors = errors+1;
			@(negedge clk);
		end;

		// test reset behaviour
		rst = 1;
		@(negedge clk);
		rst = 0;

		if(shiftreg != 16'b1010_1100_1110_0001) begin
			$error("reset does not work: should be 0x%04x but is 0x%04x",
				16'b1010_1100_1110_0001,
				shiftreg);
			errors = errors+1;
		end

		// fini.
		if(errors == 0)
			$finish;
		else
			$fatal();
	end

endmodule

