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

// testbench for clock_prescaler

module clock_prescaler_tb();
	parameter WIDTH=32;

	reg [WIDTH-1:0] system_clock = 0;

	wire [WIDTH-1:0] dut_out;
	reg reset = 1;
	clock_prescaler #(.WIDTH(WIDTH)) dut(system_clock[0], dut_out, reset);

	integer i;
	integer errors = 0;

	initial begin
		//$dumpfile("clock_prescaler_tb.vcd");
		//$dumpvars;

		for(i = 0; i < 8970; i=i+1) begin
			#1;
			reset = 0;
			if(system_clock != dut_out) begin
				$error("expected %d != seen %d", system_clock, dut_out);
				errors = errors+1;
			end
			system_clock = system_clock+1;
		end

		reset = 1;
		#1
		reset = 0;

		if(dut_out != 0) begin
			$error("reset did not set to zero");
			errors = errors+1;
		end


		if (errors != 0) begin
			$error("FAIL: collected %d errors", errors);
			$fatal();
		end else begin
			$finish;
		end
	end

endmodule

