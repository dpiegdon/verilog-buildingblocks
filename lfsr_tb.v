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
	localparam ITERATIONS=16'h5;

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
		clock_counter = 0;
		random = 0;
		rst = 0;
		errors = 0;
		whitelist[0] = 16'hACE1;
		for(i=1; i<ITERATIONS; i=i+1) begin
			old = whitelist[i-1];
			feedback = old[0] ^ old[2] ^ old[3] ^ old[5];
			whitelist[i] = { feedback, old[15:1] };
		end

		while(iteration < ITERATIONS) begin
			known_good = whitelist[iteration];
			if (known_good != shiftreg) begin
				$error("iteration %d: output 0x%04x != 0x%04x expected",
					iteration,
					whitelist[iteration],
					shiftreg);
				errors = errors+1;
			end else begin
				$display("iteration %d ok.", iteration);
			end
			@(negedge clk);
		end

		if(errors == 0)
			$finish;
		else
			$fatal();
	end

endmodule

