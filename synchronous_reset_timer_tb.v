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

// testbench for synchronous_reset_timer

module single_synchronous_reset_timer_tb();

	parameter LENGTH=7;

	reg [20:0] clk;
	reg reset_in;
	integer errors;
	integer i;

	wire reset_out;

	synchronous_reset_timer #(.LENGTH(LENGTH)) dut(clk[0], reset_out, reset_in);

	always #1 clk = clk+1;
	
	initial begin
		clk = 0;
		reset_in = 0;
		errors = 0;

		for(i=0; i<LENGTH; i=i+1) begin
			if(!reset_out) begin
				$error("with LENGTH %d:", LENGTH);
				$error("should reset but does not.");
				errors = errors + 1;
			end
			@(negedge clk);
		end
		if(reset_out) begin
			$error("with LENGTH %d:", LENGTH);
			$error("should no longer reset but does.");
			errors = errors + 1;
		end

		reset_in = 1;
		@(negedge clk);
		reset_in = 0;

		for(i=0; i<LENGTH; i=i+1) begin
			if(!reset_out) begin
				$error("with LENGTH %d:", LENGTH);
				$error("should reset but does not.");
				errors = errors + 1;
			end
			@(negedge clk);
		end
		if(reset_out) begin
			$error("with LENGTH %d:", LENGTH);
			$error("should no longer reset but does.");
			errors = errors + 1;
		end

		if(errors == 0)
			$finish;
		else
			$fatal();
	end

endmodule

module synchronous_reset_timer_tb();

	generate
		genvar i;
		for(i=3; i<33; i=i+1) begin: reset_tests
			single_synchronous_reset_timer_tb #(.LENGTH(i)) dut();
		end
	endgenerate

endmodule
